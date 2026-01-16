import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import '../main.dart'; // To access the 'cameras' list

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});

  @override
  State<DetectorPage> createState() => _DetectorPageState();
}

class _DetectorPageState extends State<DetectorPage>
    with WidgetsBindingObserver {
  CameraController? controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  bool isProcessing = false;
  String? errorMessage;
  int _lastRunTime = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  init() async {
    if (cameras.isEmpty) {
      if (mounted) {
        setState(() {
          errorMessage = "No compatible camera found.";
          isLoaded = true;
        });
      }
      return;
    }

    try {
      vision = FlutterVision();
      var camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Use Medium resolution for better performance/stability on Xiaomi/Android
      controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup
            .yuv420, // Explicitly request YUV420 for better compatibility
      );

      await controller?.initialize();
      await loadYoloModel();

      if (!mounted) return;
      setState(() {
        isLoaded = true;
        isDetecting = false;
        yoloResults = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Failed to initialize: $e";
        isLoaded = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up resources when the app is not active.
      // Important: Stop detection loop first to avoid "BufferQueue abandoned"
      setState(() {
        isDetecting = false;
      });
      if (cameraController.value.isStreamingImages) {
        await cameraController.stopImageStream();
      }
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize the camera when the app is resumed.
      if (cameraController.value.isInitialized) {
        return;
      }
      onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = controller;
    if (oldController != null) {
      controller = null;
      await oldController.dispose();
    }

    final CameraController newController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    controller = newController;

    try {
      await newController.initialize();
      if (mounted) {
        setState(() {});
      }
    } on CameraException catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Use a local function to handle async disposal safely
    _disposeResources();
    super.dispose();
  }

  Future<void> _disposeResources() async {
    await stopDetection();
    await vision.closeYoloModel();
    controller?.dispose();
  }

  Future<void> loadYoloModel() async {
    try {
      await vision.loadYoloModel(
          labels: 'assets/labels.txt',
          modelPath: 'assets/yolov8n_float16.tflite',
          modelVersion: "yolov8",
          numThreads: 2,
          useGpu: false); // Disable GPU for stability on Xiaomi
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Failed to load model: $e";
        });
      }
    }
  }

  Future<void> startDetection() async {
    if (controller == null || !controller!.value.isInitialized) return;
    if (controller!.value.isStreamingImages) return;

    setState(() {
      isDetecting = true;
    });

    try {
      await controller!.startImageStream((image) async {
        if (!isDetecting) return;

        int currentTime = DateTime.now().millisecondsSinceEpoch;
        // Strict Throttle: Process only every 500ms (2 FPS)
        if (currentTime - _lastRunTime < 500) {
          return;
        }

        if (isProcessing) return;

        isProcessing = true;
        _lastRunTime = currentTime;

        try {
          cameraImage = image;
          await yoloOnFrame(image);
        } catch (e) {
          debugPrint("Error processing frame: $e");
        } finally {
          if (mounted) {
            isProcessing = false;
          }
        }
      });
    } catch (e) {
      debugPrint("Error starting image stream: $e");
    }
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
    // Safely stop stream
    if (controller != null && controller!.value.isStreamingImages) {
      try {
        await controller!.stopImageStream();
      } catch (e) {
        debugPrint("Error stopping stream: $e");
      }
    }
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    try {
      final result = await vision.yoloOnFrame(
          bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          iouThreshold: 0.4,
          confThreshold: 0.4,
          classThreshold: 0.5);

      if (mounted && result.isNotEmpty) {
        setState(() {
          yoloResults = result;
        });
      }
    } catch (e) {
      debugPrint("Error on frame: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFE94560)),
              SizedBox(height: 20),
              Text("Loading Model...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }

    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
            child: Text("Camera not initialized",
                style: TextStyle(color: Colors.white))),
      );
    }

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: CameraPreview(controller!),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDetecting ? "Active Detection" : "Ready",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: isDetecting ? stopDetection : startDetection,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDetecting ? Colors.white : const Color(0xFFE94560),
                    border: Border.all(
                        width: 4,
                        color: Colors.white,
                        style: BorderStyle.solid),
                    boxShadow: [
                      BoxShadow(
                        color: (isDetecting
                                ? Colors.white
                                : const Color(0xFFE94560))
                            .withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isDetecting ? Icons.stop : Icons.play_arrow,
                    color: isDetecting ? const Color(0xFFE94560) : Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null || controller == null)
      return [];

    double factorX = screen.width / (cameraImage!.height);
    double factorY = screen.height / (cameraImage!.width);

    Color colorPick = const Color(0xFFE94560);

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX;
      double top = result["box"][1] * factorY;
      double right = result["box"][2] * factorX;
      double bottom = result["box"][3] * factorY;

      double width = right - left;
      double height = bottom - top;

      if (width <= 0 || height <= 0) return const SizedBox.shrink();

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(color: colorPick, width: 2.0),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              decoration: BoxDecoration(
                  color: colorPick,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  )),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
