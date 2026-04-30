import torch, torchaudio, transformers, gradio, soundfile, numpy
print('torch:       ', torch.__version__)
print('transformers:', transformers.__version__)
print('gradio:      ', gradio.__version__)
print('CUDA:', torch.cuda.is_available())
