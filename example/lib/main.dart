import 'package:flutter/material.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Not initialized';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLandmarker();
  }

  Future<void> _initializeLandmarker() async {
    try {
      await KwonMediapipeLandmarker.initialize(
        face: true,
        pose: false,
        faceOptions: const FaceOptions(
          numFaces: 1,
          outputBlendshapes: true,
        ),
      );
      setState(() {
        _status = 'Initialized successfully!';
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _disposeLandmarker() async {
    try {
      await KwonMediapipeLandmarker.dispose();
      setState(() {
        _status = 'Disposed';
        _isInitialized = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to dispose: $e';
      });
    }
  }

  @override
  void dispose() {
    KwonMediapipeLandmarker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MediaPipe Landmarker Example'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isInitialized ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Initialize button
                ElevatedButton(
                  onPressed: _isInitialized ? null : _initializeLandmarker,
                  child: const Text('Initialize'),
                ),
                const SizedBox(height: 12),

                // Dispose button
                ElevatedButton(
                  onPressed: _isInitialized ? _disposeLandmarker : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Dispose'),
                ),
                const SizedBox(height: 24),

                // Info
                const Text(
                  'Face Landmarker: 478 landmarks + 52 blendshapes\n'
                  'Pose Landmarker: 33 body landmarks',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
