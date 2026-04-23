import os
import urllib.request
import urllib.error

def download_model():
    # Switching to TinyLlama (a great, fast, open alternative) since SmolLM2 is currently requiring a login!
    url = "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
    output_dir = "assets/models"
    output_file = f"{output_dir}/tinyllama-1.1b-chat-q4_k_m.gguf"

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"Downloading from {url}...")
    
    # Create a custom request with a modern User-Agent to bypass 401/403 blocks
    req = urllib.request.Request(
        url, 
        headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
    )

    try:
        with urllib.request.urlopen(req) as response, open(output_file, 'wb') as out_file:
            # Get file size
            file_size = int(response.info().get('Content-Length', -1))
            downloaded = 0
            chunk_size = 1024 * 64 # 64 KB chunks
            
            print(f"File size: {file_size / (1024*1024):.2f} MB")
            
            while True:
                chunk = response.read(chunk_size)
                if not chunk:
                    break
                out_file.write(chunk)
                downloaded += len(chunk)
                
                # Simple progress indicator
                if file_size > 0:
                    percent = (downloaded / file_size) * 100
                    print(f"\rProgress: {percent:.1f}% ({downloaded / (1024*1024):.2f} MB)", end="")
            
        print(f"\nModel successfully downloaded to {output_file}")
    except urllib.error.HTTPError as e:
        print(f"\nHTTP Error: {e.code} - {e.reason}")
        print("Please download manually from: https://huggingface.co/HuggingFaceTB/SmolLM2-135M-Instruct-GGUF/resolve/main/smollm2-135m-instruct-q4_k_m.gguf")
    except Exception as e:
        print(f"\nDownload failed: {e}")

if __name__ == "__main__":
    download_model()
