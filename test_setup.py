import cv2
import numpy as np
import sys
from ultralytics import YOLO

def test_setup():
    print("Testing imports...")
    try:
        import streamlit
        print("Streamlit imported.")
    except ImportError as e:
        print(f"Failed to import streamlit: {e}")
        return

    print("Loading YOLOv8n model (this will download it if missing)...")
    try:
        model = YOLO("yolov8n.pt")
        print("Model loaded successfully.")
    except Exception as e:
        print(f"Failed to load user model: {e}")
        return

    print("Running dummy inference...")
    try:
        # Create a black image
        img = np.zeros((640, 640, 3), dtype=np.uint8)
        results = model.predict(img)
        print("Inference successful.")
    except Exception as e:
        print(f"Inference failed: {e}")
        return

    print("\n✅ Setup verified successfully!")

if __name__ == "__main__":
    test_setup()
