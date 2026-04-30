#!/bin/bash
set -e

echo "========================================"
echo "  VibeVoice ASR — Linux Container"
echo "========================================"

# Проверка GPU
if python3 -c "import torch; assert torch.cuda.is_available(), 'CUDA not found'" 2>/dev/null; then
    GPU=$(python3 -c "import torch; print(torch.cuda.get_device_name(0))")
    echo "✅ GPU: $GPU"
else
    echo "⚠ CUDA недоступен, запуск на CPU"
fi

# Проверка Flash Attention
python3 -c "import flash_attn; print('✅ Flash Attention:', flash_attn.__version__)" \
    2>/dev/null || echo "ℹ Flash Attention не установлен"

# Проверка модели
if [ -d "$VIBEVOICE_MODEL_PATH" ]; then
    echo "✅ Модель: $VIBEVOICE_MODEL_PATH"
else
    echo "❌ Модель не найдена: $VIBEVOICE_MODEL_PATH"
    exit 1
fi

# ============================================================
# Патч app.py: фиксируем server_name и share
# app.py может хардкодить server_name="127.0.0.1", что ломает доступ
# извне контейнера. Патчим перед каждым запуском.
# ============================================================

APP_FILE="/app/app.py"

# 1. Заменяем server_name="127.0.0.1" на 0.0.0.0
sed -i 's/server_name=["'\'']*127\.0\.0\.1["'\'']*/server_name="0.0.0.0"/g' "$APP_FILE"

# 2. Если .launch( есть без server_name — добавляем
sed -i 's/\.launch(/\.launch(server_name="0.0.0.0", /g' "$APP_FILE"
# Убираем дубликацию если уже был server_name
sed -i 's/server_name="0\.0\.0\.0", server_name=/server_name=/g' "$APP_FILE"

# 3. Опционально: публичная ссылка Gradio (GRADIO_SHARE=true)
if [ "${GRADIO_SHARE:-false}" = "true" ]; then
    sed -i 's/\.launch(/.launch(share=True, /g' "$APP_FILE"
    # Убираем дубликацию
    sed -i 's/share=True, share=True/share=True/g' "$APP_FILE"
    echo "🌐 Gradio share=True: будет создана публичная ссылка"
fi

echo ""
echo "Запуск: http://0.0.0.0:${GRADIO_SERVER_PORT:-7860}"
echo "========================================"

exec python3 "$APP_FILE"
