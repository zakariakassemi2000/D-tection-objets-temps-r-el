import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ui/home_page.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error: $e.code\nError Message: $e.message');
    cameras = [];
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLOv8 Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1A2E),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
