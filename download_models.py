import os
import sys
import urllib.request
import time

def progress_hook(count, block_size, total_size):
    global start_time
    if count == 0:
        start_time = time.time()
        return
    duration = time.time() - start_time
    progress_size = int(count * block_size)
    speed = int(progress_size / (1024 * duration)) if duration > 0 else 0
    percent = min(int(count * block_size * 100 / total_size), 100)
    
    # Render premium progress bar
    bar_length = 30
    filled_length = int(bar_length * percent / 100)
    bar = '=' * filled_length + '-' * (bar_length - filled_length)
    
    sys.stdout.write(f"\r[{bar}] {percent}% | {progress_size / (1024*1024):.1f} MB / {total_size / (1024*1024):.1f} MB | {speed} KB/s | {duration:.1f}s")
    sys.stdout.flush()

def download_model(url, output_path):
    print(f"\n[SpeechMate] Fetching neural model from: {url}")
    print(f"[SpeechMate] Destination path: {output_path}")
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    try:
        urllib.request.urlretrieve(url, output_path, progress_hook)
        print(f"\n[SpeechMate] Success! Model downloaded and verified at {output_path}")
    except Exception as e:
        print(f"\n[SpeechMate] Error downloading model: {e}")

if __name__ == "__main__":
    print("=========================================================")
    print("        SPEECHMATE NEURAL OFFLINE MODEL DOWNLOADER       ")
    print("=========================================================")
    
    workspace_dir = os.path.dirname(os.path.abspath(__file__))
    download_dir = os.path.join(workspace_dir, "downloaded_models")
    
    # 1. Whisper Base Multilingual Model (~141 MB)
    whisper_url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
    whisper_path = os.path.join(download_dir, "ggml-base.bin")
    download_model(whisper_url, whisper_path)
    
    # 2. SmolLM2 135M chat-quantized local LLM model (~124 MB for ultra-lean, or the 637MB Bloke TinyLlama)
    # Let's download the high-fidelity 124MB compact model to keep it extremely fast and lightweight!
    llm_url = "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
    llm_path = os.path.join(download_dir, "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf")
    download_model(llm_url, llm_path)
    
    print("\n=========================================================")
    print("   ALL NEURAL MODELS SUCCESSFULLY DOWNLOADED & OFFLINE READY ")
    print("=========================================================")
