import tensorflow as tf
import os

saved_model_dir = 'saved_model_tf'
tflite_file = 'mobile_app/assets/yolov8n_float16.tflite'

print(f"Converting {saved_model_dir} to {tflite_file}...")

try:
    converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_dir)
    # Optimization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()

    with open(tflite_file, 'wb') as f:
        f.write(tflite_model)
    print("Success!")
except Exception as e:
    print(f"Error: {e}")
