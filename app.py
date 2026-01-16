import cv2
import streamlit as st
from ultralytics import YOLO
import time
import sys

# Page Config
st.set_page_config(
    page_title="Real-Time Object Detection",
    page_icon="👁️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom Styling
st.markdown("""
<style>
    .reportview-container {
        background: #0e1117;
    }
    .sidebar .sidebar-content {
        background: #262730;
    }
    h1 {
        color: #00FF7F;
    }
</style>
""", unsafe_allow_html=True)

# Title and Sidebar
st.title("👁️ Intelligent Real-Time Object Detection")
st.sidebar.header("Settings")

import os
import glob

def get_latest_model():
    """Finds the latest trained model in runs/detect directory."""
    try:
        # Search for best.pt in all train runs
        models = glob.glob(os.path.join("runs", "detect", "*", "weights", "best.pt"))
        if models:
            # Return the most recently modified model
            latest = max(models, key=os.path.getctime)
            return latest
    except Exception as e:
        print(f"Error finding models: {e}")
    return "yolov8n.pt"

# Model Selection
default_model = get_latest_model()
model_path = st.sidebar.text_input("Model Path", default_model) # Auto-detect latest model
conf_threshold = st.sidebar.slider("Confidence Threshold", 0.0, 1.0, 0.4, 0.05)

# Metrics
st.sidebar.markdown("---")
fps_display = st.sidebar.empty()
status_indicator = st.sidebar.empty()

@st.cache_resource
def load_model(path):
    return YOLO(path)

try:
    with st.spinner(f"Loading Model {model_path}..."):
        model = load_model(model_path)
    status_indicator.success("Model Loaded Successfully!")
except Exception as e:
    status_indicator.error(f"Error loading model: {e}")
    st.error(f"Could not load model. Check path. Error: {e}")
    st.stop()

# Input Source
st.sidebar.markdown("---")
input_source = st.sidebar.radio("Select Input Source", ("Webcam", "Video File"))

if input_source == "Webcam":
    run = st.checkbox('Start Webcam', value=True)
    FRAME_WINDOW = st.image([])
    
    if run:
        cap = cv2.VideoCapture(0)
        
        if not cap.isOpened():
            st.error("Could not open webcam.")
        else:
            prev_time = 0
            while run:
                ret, frame = cap.read()
                if not ret:
                    st.write("Failed to grab frame")
                    break
                
                # Inference
                results = model.predict(frame, conf=conf_threshold, verbose=False)
                
                # Visualization
                annotated_frame = results[0].plot()
                
                # Convert BGR to RGB for Streamlit
                annotated_frame = cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB)
                
                # FPS Calculation
                curr_time = time.time()
                fps = 1 / (curr_time - prev_time)
                prev_time = curr_time
                fps_display.metric("FPS", f"{fps:.2f}")
                
                FRAME_WINDOW.image(annotated_frame)
            
            cap.release()
    else:
        st.write("Webcam stopped.")

elif input_source == "Video File":
    uploaded_file = st.sidebar.file_uploader("Upload Video", type=['mp4', 'avi', 'mov', 'mkv'])
    
    if uploaded_file is not None:
        # Save uploaded file to a temporary file
        import tempfile
        tfile = tempfile.NamedTemporaryFile(delete=False)
        tfile.write(uploaded_file.read())
        
        cap = cv2.VideoCapture(tfile.name)
        
        if not cap.isOpened():
            st.error("Error opening video file.")
        else:
            stop_button = st.sidebar.button("Stop Processing")
            FRAME_WINDOW = st.image([])
            prev_time = 0
            
            while cap.isOpened() and not stop_button: 
                ret, frame = cap.read()
                if not ret:
                    break
                
                # Inference
                results = model.predict(frame, conf=conf_threshold, verbose=False)
                
                # Visualization
                annotated_frame = results[0].plot()
                
                # Convert BGR to RGB for Streamlit
                annotated_frame = cv2.cvtColor(annotated_frame, cv2.COLOR_BGR2RGB)
                
                # FPS Calculation
                curr_time = time.time()
                # Avoid division by zero
                if curr_time - prev_time > 0:
                    fps = 1 / (curr_time - prev_time)
                else:
                    fps = 0
                prev_time = curr_time
                fps_display.metric("FPS", f"{fps:.2f}")
                
                FRAME_WINDOW.image(annotated_frame)
            
            cap.release()
            st.sidebar.success("Video processing completed.")

