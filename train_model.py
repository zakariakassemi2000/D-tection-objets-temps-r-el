from ultralytics import YOLO

def train_model(model_name='yolov8n.pt', data_config='coco128.yaml', epochs=5):
    """
    Executes the training pipeline.
    
    Args:
        model_name (str): Path to the starting model/weights.
        data_config (str): Path to the data YAML file.
        epochs (int): Number of training epochs.
    """
    print(f"--- Phase 3: Training Model [{model_name}] on [{data_config}] for {epochs} epochs ---")
    
    try:
        # Load a model
        model = YOLO(model_name)  # load a pretrained model (recommended for training)

        # Train the model
        print("🚀 Starting training...")
        import os
        results = model.train(data=data_config, epochs=epochs, imgsz=640, project=os.path.abspath("runs"), name="detect", exist_ok=True)
        
        # Validate the model
        print("🛡️ Validating model...")
        metrics = model.val()
        print(f"✅ Validation mAP50-95: {metrics.box.map}")
        
        # Export the model
        success = model.export(format='onnx')
        print(f"💾 Model exported to ONNX: {success}")
        
    except Exception as e:
        print(f"❌ Error during training pipeline: {e}")

if __name__ == "__main__":
    train_model(epochs=1)
