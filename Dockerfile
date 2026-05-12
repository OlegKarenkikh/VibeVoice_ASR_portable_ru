# CUDA 12.6 + RTX 4060 Ti friendly
FROM nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04

# ── Окружение ───────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    HF_HOME=/app/models \
    HUGGINGFACE_HUB_CACHE=/app/models \
    TORCH_HOME=/app/models/torch \
    XDG_CACHE_HOME=/app/cache \
    GRADIO_TEMP_DIR=/app/temp \
    GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_SERVER_PORT=7860 \
    VIBEVOICE_MODEL_REPO=scerz/VibeVoice-ASR-4bit \
    VIBEVOICE_MODEL_PATH=/app/models/VibeVoice-ASR-4bit \
    QWEN_TOKENIZER_REPO=Qwen/Qwen2.5-1.5B \
    QWEN_TOKENIZER_PATH=/app/models/Qwen2.5-1.5B-tokenizer \
    HF_HUB_DISABLE_XET=1

# ── Системные пакеты ─────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 python3.12-venv python3-pip python3.12-dev \
    ffmpeg \
    libsndfile1 libgomp1 \
    build-essential ninja-build \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

WORKDIR /app
RUN mkdir -p models cache temp output

# ── PyTorch c CUDA 12.6 ────────────────────────────────────────────
RUN pip3 install --no-cache-dir \
    torch==2.7.1 torchaudio==2.7.1 \
    --index-url https://download.pytorch.org/whl/cu126

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

RUN pip3 install --no-cache-dir flash-attn --no-build-isolation \
    || echo "⚠ Flash Attention не установлен, работаем в обычном режиме"

# ── Приложение ───────────────────────────────────────────────────
COPY app.py .
COPY run_app.py .
COPY vibevoice/ ./vibevoice/
COPY assets/ ./assets/

# ── Предзагрузка модели и Qwen tokenizer ─────────────────────────────
RUN --mount=type=secret,id=hf_token,required=false \
    python3 - <<'EOF'
import os
import json
from pathlib import Path
from huggingface_hub import snapshot_download

model_repo = os.environ.get("VIBEVOICE_MODEL_REPO", "scerz/VibeVoice-ASR-4bit")
model_dir = Path(os.environ.get("VIBEVOICE_MODEL_PATH", "/app/models/VibeVoice-ASR-4bit"))

qwen_repo = os.environ.get("QWEN_TOKENIZER_REPO", "Qwen/Qwen2.5-1.5B")
qwen_dir = Path(os.environ.get("QWEN_TOKENIZER_PATH", "/app/models/Qwen2.5-1.5B-tokenizer"))

try:
    token = Path("/run/secrets/hf_token").read_text(encoding="utf-8").strip() or None
except FileNotFoundError:
    token = None

model_dir.mkdir(parents=True, exist_ok=True)
qwen_dir.mkdir(parents=True, exist_ok=True)

snapshot_download(
    repo_id=model_repo,
    local_dir=str(model_dir),
    token=token,
    ignore_patterns=["*.msgpack", "flax_model*", "tf_model*", "rust_model*"],
)

print(f"✅ Модель {model_repo} загружена в {model_dir}")

snapshot_download(
    repo_id=qwen_repo,
    local_dir=str(qwen_dir),
    token=token,
    allow_patterns=[
        "tokenizer.json",
        "tokenizer_config.json",
        "vocab.json",
        "merges.txt",
        "special_tokens_map.json",
        "added_tokens.json",
        "config.json",
    ],
)

has_tokenizer_json = (qwen_dir / "tokenizer.json").exists()
has_vocab_merges = (qwen_dir / "vocab.json").exists() and (qwen_dir / "merges.txt").exists()

if not (has_tokenizer_json or has_vocab_merges):
    raise RuntimeError(
        f"Qwen tokenizer files are incomplete in {qwen_dir}. "
        "Need tokenizer.json or vocab.json + merges.txt."
    )

cfg_path = model_dir / "preprocessor_config.json"

if cfg_path.exists():
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
else:
    cfg = {}

cfg["language_model_pretrained_name"] = str(qwen_dir)

cfg_path.write_text(
    json.dumps(cfg, ensure_ascii=False, indent=2),
    encoding="utf-8",
)

print(f"✅ Qwen tokenizer {qwen_repo} загружен в {qwen_dir}")
print(f"✅ preprocessor_config.json обновлён: language_model_pretrained_name={qwen_dir}")
EOF

EXPOSE 7860
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
