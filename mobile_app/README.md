# Object Detection Mobile App

This is a Flutter application for real-time object detection using YOLOv8 and TFLite.

## 🚀 How to Run (Step-by-Step)

### 1. Prerequisites
You must have the following installed on your computer:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) (for Android SDK and Emulator)
- [Python](https://www.python.org/downloads/) (to export the model)

### 2. Prepare the AI Model
Before running the app, you need the TFLite model file.
1.  Open a terminal in the root project folder (`d:\Bureau\Détection objets temps réel`).
2.  Run the export script:
    ```bash
    python export_model.py
    ```
    *This will generate `yolov8n_float16.tflite` or similar.*
3.  **Move the generated file** to the assets folder:
    *   From: `d:\Bureau\Détection objets temps réel\yolov8n_float16.tflite`
    *   To: `d:\Bureau\Détection objets temps réel\mobile_app\assets\`

### 3. Build and Run the App
1.  Connect your Android phone (USB Debugging ON) or start an Emulator.
2.  Open a terminal in the `mobile_app` folder:
    ```bash
    cd mobile_app
    ```
3.  Install dependencies:
    ```bash
    flutter pub get
    ```
4.  Run the app:
    ```bash
    flutter run
    ```

### Troubleshooting
-   **Model Not Found**: Ensure the filename in `pubspec.yaml` matches your actual tflite file.
-   **Gradle Errors**: If you see errors about "minSdkVersion", open `android/app/build.gradle` and change `minSdkVersion flutter.minSdkVersion` to `minSdkVersion 21`.
