# CUDA 12.6 + cuDNN runtime (совместимо с RTX 30xx/40xx/50xx)
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

# ── Переменные окружения ──────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    HF_HOME=/app/models \
    HUGGINGFACE_HUB_CACHE=/app/models \
    TRANSFORMERS_CACHE=/app/models \
    TORCH_HOME=/app/models/torch \
    XDG_CACHE_HOME=/app/cache \
    GRADIO_TEMP_DIR=/app/temp \
    GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_SERVER_PORT=7860 \
    VIBEVOICE_MODEL_PATH=/app/models/VibeVoice-ASR-HF

# ── Системные зависимости ─────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3-pip python3.12-dev \
    ffmpeg \
    libsndfile1 libgomp1 \
    build-essential ninja-build \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# python3 → python3.12
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

WORKDIR /app
RUN mkdir -p models cache temp output

# ── PyTorch с CUDA 12.6 ───────────────────────────────────────
RUN pip3 install --no-cache-dir \
    torch==2.7.1 torchaudio==2.7.1 \
    --index-url https://download.pytorch.org/whl/cu126

# ── Зависимости приложения ────────────────────────────────────
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# ── Flash Attention 2 (на Linux компилируется из исходников) ──
# Нужен build-essential и ninja-build (установлены выше).
# --no-build-isolation использует уже установленный torch.
RUN pip3 install --no-cache-dir flash-attn --no-build-isolation \
    || echo "⚠ Flash Attention не собрался, продолжаем без него"

# ── Копируем код приложения ───────────────────────────────────
COPY app.py .
COPY vibevoice/ ./vibevoice/
COPY assets/ ./assets/

# ── Предзагрузка модели в образ при сборке ────────────────────
# Модель 9B BF16 ≈ 18 GB на диске.
# Если нужен токен (приватный доступ): docker build --build-arg HF_TOKEN=hf_xxx ...
ARG HF_TOKEN=""
RUN python3 - <<'EOF'
import os
from huggingface_hub import snapshot_download

token = os.environ.get("HF_TOKEN") or None
snapshot_download(
    repo_id="microsoft/VibeVoice-ASR-HF",
    local_dir="/app/models/VibeVoice-ASR-HF",
    token=token,
    ignore_patterns=["*.msgpack", "flax_model*", "tf_model*", "rust_model*"],
)
print("✅ Модель загружена в /app/models/VibeVoice-ASR-HF")
EOF

EXPOSE 7860
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
