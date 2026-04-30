#!/bin/bash
set -e

echo "========================================"
echo "  VibeVoice ASR — Linux Container"
echo "========================================"

# GPU check
if python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
    GPU=$(python3 -c "import torch; print(torch.cuda.get_device_name(0))")
    echo "✅ GPU: $GPU"
else
    echo "⚠ CUDA недоступен, запуск на CPU"
fi

# Flash Attention check
python3 -c "import flash_attn; print('✅ Flash Attention:', flash_attn.__version__)" \
    2>/dev/null || echo "ℹ Flash Attention не установлен"

# Model check
if [ -d "$VIBEVOICE_MODEL_PATH" ]; then
    echo "✅ Модель: $VIBEVOICE_MODEL_PATH"
else
    echo "❌ Модель не найдена: $VIBEVOICE_MODEL_PATH"
    exit 1
fi

echo ""
echo "Запуск: http://0.0.0.0:${GRADIO_SERVER_PORT:-7860}"
if [ "${GRADIO_SHARE:-false}" = "true" ]; then
    echo "🌐 GRADIO_SHARE=true: будет создана публичная ссылка Gradio"
fi
echo "========================================"

# Launch via wrapper that monkey-patches gr.Blocks.launch
exec python3 /app/run_app.py
