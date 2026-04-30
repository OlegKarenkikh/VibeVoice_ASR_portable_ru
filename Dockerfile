# CUDA 12.6 + RTX 4060 Ti friendly
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

# ── Окружение ───────────────────────────────────────────────
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
    # Модель по умолчанию — 4-bit для 16 GB VRAM
    VIBEVOICE_MODEL_REPO=scerz/VibeVoice-ASR-4bit \
    VIBEVOICE_MODEL_PATH=/app/models/VibeVoice-ASR-4bit

# ── Системные пакеты (FFmpeg, ninja, dev-tools) ───────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3-pip python3.12-dev \
    ffmpeg \
    libsndfile1 libgomp1 \
    build-essential ninja-build \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# alias python3 → python3.12
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

WORKDIR /app
RUN mkdir -p models cache temp output

# ── PyTorch + Flash Attention ─────────────────────────────────────────
RUN pip3 install --no-cache-dir \
    torch==2.7.1 torchaudio==2.7.1 \
    --index-url https://download.pytorch.org/whl/cu126

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

RUN pip3 install --no-cache-dir flash-attn --no-build-isolation \
    || echo "⚠ Flash Attention не установлен, работаем в обычном режиме"

# ── Приложение ────────────────────────────────────────────────────
COPY app.py .
COPY vibevoice/ ./vibevoice/
COPY assets/ ./assets/

# ── Скачиваем 4-bit модель при сборке ───────────────────────────
# scerz/VibeVoice-ASR-4bit ≈ 5-6 GB VRAM (подходит для RTX 4060 Ti 16 GB)
# Для переключения на полную модель — см. docker-compose.yml
ARG HF_TOKEN=""
RUN python3 - <<'EOF'
import os
from huggingface_hub import snapshot_download

model_repo = os.environ.get("VIBEVOICE_MODEL_REPO", "scerz/VibeVoice-ASR-4bit")
model_dir  = os.environ.get("VIBEVOICE_MODEL_PATH", "/app/models/VibeVoice-ASR-4bit")
token      = os.environ.get("HF_TOKEN") or None

os.makedirs(model_dir, exist_ok=True)
snapshot_download(
    repo_id=model_repo,
    local_dir=model_dir,
    token=token,
    ignore_patterns=["*.msgpack", "flax_model*", "tf_model*", "rust_model*"],
)
print(f"✅ Модель {model_repo} загружена в {model_dir}")
EOF

EXPOSE 7860
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
