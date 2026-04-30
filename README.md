<div align="center">

# VibeVoice ASR Portable

**Портативное распознавание речи — Microsoft VibeVoice, установка в один клик, 100% офлайн.**
**Поддерживается Windows (portable) и Linux/Docker (GPU-контейнер).**

[![Stars](https://img.shields.io/github/stars/timoncool/VibeVoice_ASR_portable_ru?style=flat-square)](https://github.com/timoncool/VibeVoice_ASR_portable_ru/stargazers)
[![License](https://img.shields.io/github/license/timoncool/VibeVoice_ASR_portable_ru?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/timoncool/VibeVoice_ASR_portable_ru?style=flat-square)](https://github.com/timoncool/VibeVoice_ASR_portable_ru/commits)
[![Downloads](https://img.shields.io/github/downloads/timoncool/VibeVoice_ASR_portable_ru/total?style=flat-square)](https://github.com/timoncool/VibeVoice_ASR_portable_ru/releases)
[![Docker Image](https://img.shields.io/docker/pulls/OlegKarenkikh/vibevoice-asr-ru?style=flat-square&logo=docker)](https://hub.docker.com/r/OlegKarenkikh/vibevoice-asr-ru)

![Интерфейс VibeVoice ASR](assets/screenshot.png)

</div>

VibeVoice ASR — современная модель распознавания речи от Microsoft, которая преобразует аудио в текст с высокой точностью и поддержкой диаризации спикеров. Полная русификация интерфейса.

## Возможности

- Распознавание речи в текст с высокой точностью
- Диаризация спикеров (определение кто говорит)
- Временные метки для каждого сегмента речи
- 4-bit квантизация для экономии видеопамяти
- Полностью русскоязычный интерфейс
- Тёмная тема интерфейса
- Поддержка множества аудио и видео форматов через FFmpeg
- Ускоренная загрузка моделей через HuggingFace Xet
- **Запуск в Docker-контейнере (Linux, NVIDIA GPU)**

---

## 🐧 Linux / Docker (GPU-контейнер)

### Требования

- Linux (Ubuntu 20.04+, Debian, etc.)
- Docker + [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- NVIDIA GPU с поддержкой CUDA 12.6+ (RTX 30xx / 40xx / 50xx)
- 16 GB+ RAM, 20 GB+ свободного места

### Быстрый старт (готовый образ с Docker Hub)

Образ уже содержит предзагруженную 4-bit модель (`scerz/VibeVoice-ASR-4bit`, ~5–6 GB VRAM).

```bash
# 1. Скачать образ
docker pull olegkarenkikh/vibevoice-asr-ru:latest

# 2. Запустить
docker run --gpus all -p 7860:7860 \
  -v $(pwd)/output:/app/output \
  olegkarenkikh/vibevoice-asr-ru:latest

# 3. Открыть в браузере
# http://localhost:7860
```

### Запуск через docker compose

```bash
git clone https://github.com/OlegKarenkikh/VibeVoice_ASR_portable_ru.git
cd VibeVoice_ASR_portable_ru
docker compose up -d

# Логи
docker compose logs -f

# Остановка
docker compose down
```

### Сборка образа из исходников

```bash
# Стандартная сборка (4-bit модель, RTX 40xx/30xx)
docker compose build

# С токеном HuggingFace (для приватных моделей)
HF_TOKEN=hf_xxxxxxxx docker compose build

# Альтернативная модель (полная, требует 18+ GB VRAM)
VIBEVOICE_MODEL_REPO=microsoft/VibeVoice-ASR-HF docker compose build
```

### Выбор модели по GPU

| GPU | VRAM | Рекомендуемая модель | VIBEVOICE_MODEL_REPO |
|-----|------|----------------------|----------------------|
| RTX 4060 Ti 16 GB | 16 GB | 4-bit ✅ | `scerz/VibeVoice-ASR-4bit` |
| RTX 3080 / 3090 | 10–24 GB | 4-bit или full | `scerz/VibeVoice-ASR-4bit` |
| RTX 4090 / A100 | 24+ GB | Full ✅ | `microsoft/VibeVoice-ASR-HF` |

### Переменные окружения контейнера

| Переменная | По умолчанию | Описание |
|---|---|---|
| `VIBEVOICE_MODEL_REPO` | `scerz/VibeVoice-ASR-4bit` | HuggingFace repo модели |
| `VIBEVOICE_MODEL_PATH` | `/app/models/VibeVoice-ASR-4bit` | Путь к модели внутри контейнера |
| `GRADIO_SERVER_PORT` | `7860` | Порт веб-интерфейса |
| `HF_HOME` | `/app/models` | Кэш HuggingFace |

### Монтирование томов

```yaml
volumes:
  # Транскрипции на хост
  - ./output:/app/output
  # Переиспользовать уже скачанную модель (не скачивать повторно)
  - /path/to/hf_cache/VibeVoice-ASR-4bit:/app/models/VibeVoice-ASR-4bit:ro
```

---

## 🪟 Windows (portable)

### Системные требования

- Windows 10/11 (64-bit)
- NVIDIA GPU с поддержкой CUDA (рекомендуется 8GB+ VRAM)
- Или CPU (медленнее, но работает)
- 16GB+ RAM, 10GB свободного места на диске

### Рекомендуемые видеокарты

| Серия | CUDA версия | Flash Attention 2 |
|-------|-------------|-------------------|
| GTX 10xx (Pascal) | CUDA 11.8 | Нет |
| RTX 20xx (Turing) | CUDA 11.8 | Нет |
| RTX 30xx (Ampere) | CUDA 12.6 | Да |
| RTX 40xx (Ada Lovelace) | CUDA 12.8 | Да |
| RTX 50xx (Blackwell) | CUDA 12.8 | Да |

### Установка

1. Скачайте архив `VibeVoice_ASR_portable_ru_installer.zip` из [релизов](https://github.com/timoncool/VibeVoice_ASR_portable_ru/releases)
2. Распакуйте в любую папку (например `D:\VibeVoice`)
3. Запустите `install.bat`
4. Выберите вашу видеокарту из списка
5. Дождитесь завершения установки

### Запуск

1. Запустите `run.bat`
2. Приложение автоматически откроется в браузере
3. Выберите модель и нажмите «Загрузить модель»
4. Загрузите аудио файл или запишите с микрофона
5. Нажмите «Распознать речь»

---

## Модели

### 4-bit модель `scerz/VibeVoice-ASR-4bit` (рекомендуется для 16 GB VRAM)
- ~5–6 GB VRAM
- Подходит для RTX 4060 Ti 16 GB и выше
- Отличное качество при сниженном потреблении памяти

### Полная модель `microsoft/VibeVoice-ASR-HF`
- ~18 GB VRAM (BF16)
- Максимальное качество распознавания
- Требует RTX 4090, A100 или выше

## Поддерживаемые форматы

**Аудио:** MP3, WAV, FLAC, OGG, M4A, AAC, WMA, AIFF и другие

**Видео:** MP4, MKV, AVI, MOV, WebM и другие (извлекается аудио дорожка)

## Решение проблем

### `CUDA out of memory`
- Используйте 4-bit модель
- Закройте другие приложения, использующие GPU
- Уменьшите параметр «Максимум токенов»

### Контейнер не видит GPU
- Убедитесь, что установлен [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Проверьте: `docker run --rm --gpus all nvidia/cuda:12.6.3-base-ubuntu24.04 nvidia-smi`

### Модель загружается медленно
- При первом запуске модель скачивается (~5–6 GB)
- Используйте volume-монтирование чтобы не скачивать повторно при пересборке

---

## Структура репозитория

```
VibeVoice_ASR_portable_ru/
├── app.py                    # Основное приложение (Gradio)
├── requirements.txt          # Python-зависимости
├── Dockerfile                # Linux/Docker GPU-контейнер
├── docker-compose.yml        # Оркестровка (GPU, RTX 40xx/30xx)
├── docker-compose.cpu.yml    # Тестовый запуск без GPU (CPU only)
├── entrypoint.sh             # Стартовый скрипт контейнера
├── install.bat               # Windows-установщик
├── run.bat                   # Windows-запуск
├── vibevoice/                # Модули VibeVoice ASR
├── assets/                   # Скриншоты и ресурсы
├── models/                   # Кэш моделей HuggingFace
├── output/                   # Выходные файлы транскрипции
├── temp/                     # Временные файлы
└── cache/                    # Кэш приложения
```

---

**Оригинальная модель:** [Microsoft VibeVoice ASR](https://huggingface.co/microsoft/VibeVoice-ASR)
**4-bit квантизация:** [scerz/VibeVoice-ASR-4bit](https://huggingface.co/scerz/VibeVoice-ASR-4bit)

## Лицензия

Данный проект распространяется под лицензией MIT.
Модель VibeVoice ASR распространяется под лицензией Microsoft.

## Ссылки

- [VibeVoice ASR на HuggingFace](https://huggingface.co/microsoft/VibeVoice-ASR)
- [Репозиторий Microsoft VibeVoice](https://github.com/microsoft/VibeVoice)
- [Телеграм канал Нейро-Софт](https://t.me/neuroport)

## Другие проекты [@timoncool](https://github.com/timoncool)

| Проект | Описание |
|--------|----------|
| [ACE-Step Studio](https://github.com/timoncool/ACE-Step-Studio) | AI-студия музыки — песни, вокал, каверы, клипы |
| [Foundation Music Lab](https://github.com/timoncool/Foundation-Music-Lab) | Генерация музыки + редактор таймлайна |
| [LavaSR](https://github.com/timoncool/LavaSR_portable_ru) | Портативное улучшение аудио |
| [Qwen3-TTS](https://github.com/timoncool/Qwen3-TTS_portable_rus) | Портативный TTS с клонированием голоса |
| [SuperCaption Qwen3-VL](https://github.com/timoncool/SuperCaption_Qwen3-VL) | Портативное описание изображений |
| [VideoSOS](https://github.com/timoncool/videosos) | AI-видеопродакшн в браузере |

## Star History

<a href="https://www.star-history.com/?repos=timoncool%2FVibeVoice_ASR_portable_ru&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=timoncool/VibeVoice_ASR_portable_ru&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=timoncool/VibeVoice_ASR_portable_ru&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=timoncool/VibeVoice_ASR_portable_ru&type=date&legend=top-left" />
 </picture>
</a>
