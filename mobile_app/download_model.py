import requests
import os

url = "https://huggingface.co/squantumengine/yolov8_saved_model/resolve/main/yolov8n_float16.tflite"
output_path = "assets/yolov8n_float16.tflite"

# Ensure assets directory exists
os.makedirs("assets", exist_ok=True)

print(f"Downloading from {url}...")
try:
    response = requests.get(url, allow_redirects=True)
    if response.status_code == 200:
        with open(output_path, "wb") as f:
            f.write(response.content)
        print(f"Download successful to {output_path}")
    else:
        print(f"Failed to download. Status code: {response.status_code}")
except Exception as e:
    print(f"Error downloading: {e}")
