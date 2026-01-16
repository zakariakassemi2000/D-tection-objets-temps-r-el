from ultralytics import YOLO

# Load the YOLOv8 model
model = YOLO('yolov8n.pt')

# Export the model to TFLite format
# 'float16' quantization is widely supported and smaller than float32
model.export(format='tflite', half=True)
