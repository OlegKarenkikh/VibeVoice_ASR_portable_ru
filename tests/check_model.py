import os
p = os.environ.get('VIBEVOICE_MODEL_PATH', '/app/models/VibeVoice-ASR-4bit')
assert os.path.isdir(p), 'Model dir not found: ' + p
files = os.listdir(p)
print('Files:', len(files), files[:5])
assert any(f.endswith('.json') for f in files), 'No .json config found'
print('Model check PASSED')
