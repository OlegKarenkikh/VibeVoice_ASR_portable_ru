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
    echo "⚠ CUDA недоступен, запуск на CPU (медленно)"
fi

# Проверка Flash Attention
python3 -c "import flash_attn; print('✅ Flash Attention:', flash_attn.__version__)" \
    2>/dev/null || echo "ℹ Flash Attention не установлен, используется стандартный attention"

# Проверка модели
if [ -d "$VIBEVOICE_MODEL_PATH" ]; then
    echo "✅ Модель найдена: $VIBEVOICE_MODEL_PATH"
else
    echo "❌ Модель не найдена по пути $VIBEVOICE_MODEL_PATH"
    exit 1
fi

echo ""
echo "Запуск на http://0.0.0.0:7860 ..."
echo "========================================"

exec python3 app.py
