import onnx
from onnx_tf.backend import prepare
import tensorflow as tf
import os

try:
    print("Loading ONNX model...")
    onnx_model = onnx.load("yolov8n.onnx")

    print("Preparing TF representation...")
    tf_rep = prepare(onnx_model)

    print("Exporting to SavedModel...")
    tf_rep.export_graph("yolov8n_saved_model")

    print("Converting to TFLite...")
    converter = tf.lite.TFLiteConverter.from_saved_model("yolov8n_saved_model")
    # optimization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]

    tflite_model = converter.convert()

    output_path = "assets/yolov8n_float16.tflite"
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"Successfully saved to {output_path}")

except Exception as e:
    print(f"Error: {e}")
