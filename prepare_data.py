from ultralytics.utils.downloads import download
from ultralytics.data.utils import check_det_dataset
import os
import yaml

def prepare_dataset(dataset_name='coco128.yaml'):
    """
    Downloads and validates a standard YOLO dataset.
    
    Args:
        dataset_name (str): The name of the dataset YAML file (e.g., 'coco128.yaml', 'coco8.yaml').
    """
    print(f"--- Phase 2: preparing Data [{dataset_name}] ---")
    
    # Configure Ultralytics to use local directory to avoid Permission Error
    from ultralytics import settings
    local_dataset_dir = os.path.abspath("datasets")
    print(f"⚙️ Updating datasets_dir to: {local_dataset_dir}")
    settings.update({'datasets_dir': local_dataset_dir})
    
    # Check/Download dataset
    try:
        # This will download the dataset if not present and return parameters
        data = check_det_dataset(dataset_name)
        print(f"✅ Dataset found/downloaded at: {data['path']}")
        
        # Verify structure
        print("📊 Validating dataset structure...")
        print(f"   - Train images: {data['train']}")
        print(f"   - Val images: {data['val']}")
        print(f"   - Number of classes: {data['nc']}")
        print(f"   - Classes: {data['names']}")
        
        return data
    except Exception as e:
        print(f"❌ Error preparing dataset: {e}")
        return None

if __name__ == "__main__":
    prepare_dataset()
