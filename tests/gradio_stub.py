import gradio as gr
import time
import inspect
import threading

demo = gr.Interface(
    fn=lambda x: x,
    inputs=gr.Textbox(),
    outputs=gr.Textbox(),
    title="Smoke Test",
)

launch_kwargs = dict(server_name="0.0.0.0", server_port=7860)
sig = inspect.signature(demo.launch)

if "prevent_thread_lock" in sig.parameters:
    # Gradio 4.x
    launch_kwargs["prevent_thread_lock"] = True
    demo.launch(**launch_kwargs)
    time.sleep(60)
else:
    # Gradio 5/6 — launch() blocks, run in thread
    t = threading.Thread(target=demo.launch, kwargs=launch_kwargs, daemon=True)
    t.start()
    print("Gradio thread started", flush=True)
    time.sleep(60)
