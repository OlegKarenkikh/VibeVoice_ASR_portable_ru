"""
Self-contained Gradio smoke test.
Starts a minimal Gradio interface in a background thread,
then polls it with urllib from the same process.
Exits 0 on success, 1 on failure.
No curl, no docker exec, no daemon containers.
"""
import gradio as gr
import threading
import time
import sys
import urllib.request
import urllib.error

PORT = 7860
MAX_WAIT = 90   # seconds
POLL_INTERVAL = 3

demo = gr.Interface(
    fn=lambda x: x,
    inputs=gr.Textbox(),
    outputs=gr.Textbox(),
    title="Smoke Test",
)

t = threading.Thread(
    target=demo.launch,
    kwargs={"server_name": "0.0.0.0", "server_port": PORT},
    daemon=True,
)
t.start()
print(f"Gradio thread started, polling http://127.0.0.1:{PORT}/", flush=True)

deadline = time.time() + MAX_WAIT
while time.time() < deadline:
    time.sleep(POLL_INTERVAL)
    try:
        code = urllib.request.urlopen(
            f"http://127.0.0.1:{PORT}/", timeout=2
        ).getcode()
        if code == 200:
            elapsed = MAX_WAIT - (deadline - time.time())
            print(f"HTTP 200 after ~{elapsed:.0f}s — PASSED", flush=True)
            sys.exit(0)
    except Exception as e:
        print(f"  waiting... ({e})", flush=True)

print("FAILED: Gradio did not respond in time", flush=True)
sys.exit(1)
