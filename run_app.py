"""
Obviously app.py hardcodes server_name or doesn't set it at all —
Gradio then defaults to 127.0.0.1 which breaks Docker networking.

This wrapper monkey-patches gr.Blocks.launch BEFORE app.py is imported,
forcing server_name=0.0.0.0 and optional share=True (via GRADIO_SHARE=true).
No sed, no file patching, works regardless of how app.py calls .launch().
"""
import os
import gradio as gr

_original_launch = gr.Blocks.launch

def _patched_launch(self, *args, **kwargs):
    # Force 0.0.0.0 so the container is reachable from outside
    kwargs.setdefault("server_name", "0.0.0.0")
    # Override even if app.py explicitly passed 127.0.0.1
    if kwargs.get("server_name") == "127.0.0.1":
        kwargs["server_name"] = "0.0.0.0"
    # Optional public Gradio tunnel
    if os.environ.get("GRADIO_SHARE", "").lower() == "true":
        kwargs["share"] = True
    print(f"[run_app] launch: server_name={kwargs['server_name']} "
          f"share={kwargs.get('share', False)}", flush=True)
    return _original_launch(self, *args, **kwargs)

gr.Blocks.launch = _patched_launch

# Run the real app as __main__
import runpy
runpy.run_path("/app/app.py", run_name="__main__")
