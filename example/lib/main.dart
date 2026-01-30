import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaPipe Landmarker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraReady = false;      // 카메라 준비 상태
  bool _isMediaPipeReady = false;   // MediaPipe 준비 상태
  bool _isDetecting = false;
  bool _isDisposed = false;         // Widget dispose 상태
  
  // 비동기 처리 핵심: 현재 처리 중인지 플래그
  bool _isProcessingFrame = false;
  
  // Results
  LandmarkerResult? _lastResult;
  int _frameCount = 0;
  int _processedFrames = 0;
  int _detectedFrames = 0;
  
  // FPS 계산
  DateTime? _lastFpsUpdate;
  double _fps = 0;
  int _fpsFrameCount = 0;
  
  // Debug
  final List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _addLog('AppLifecycleState: $state');
    
    // 앱이 백그라운드로 갈 때 카메라 정리
    if (state == AppLifecycleState.inactive || 
        state == AppLifecycleState.paused) {
      _pauseCamera();
    }
    // 앱이 포그라운드로 돌아올 때 카메라 재초기화
    else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
    // 앱 완전 종료 시
    else if (state == AppLifecycleState.detached) {
      _cleanupAll();
    }
  }

  void _pauseCamera() {
    if (_isDisposed) return;
    
    _addLog('Pausing camera...');
    
    // 1. 상태 업데이트 먼저
    _isDetecting = false;
    _isProcessingFrame = true;
    _isCameraReady = false;  // 중요: 카메라 준비 상태 false로!
    
    // 2. 컨트롤러 정리
    final controller = _cameraController;
    _cameraController = null;
    
    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          controller.stopImageStream().catchError((_) {});
        }
      } catch (_) {}
      
      // dispose는 비동기로 처리
      Future.microtask(() {
        try {
          controller.dispose();
          _addLog('Camera controller disposed');
        } catch (e) {
          _addLog('Camera dispose error: $e');
        }
      });
    }
    
    // UI 업데이트
    if (mounted) setState(() {});
  }

  void _resumeCamera() {
    if (_isDisposed) return;
    if (_isCameraReady) return;  // 이미 준비되어 있으면 스킵
    
    _addLog('Resuming camera...');
    
    // 카메라 재초기화 (약간의 딜레이 후)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed && mounted) {
        _isProcessingFrame = false;
        _initializeCamera();
      }
    });
  }

  void _cleanupAll() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isDetecting = false;
    _isProcessingFrame = true;
    _isCameraReady = false;
    
    final controller = _cameraController;
    _cameraController = null;
    
    if (controller != null) {
      try {
        controller.stopImageStream().catchError((_) {});
      } catch (_) {}
      try {
        controller.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupAll();
    KwonMediapipeLandmarker.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    debugPrint('[DEBUG] $message');
    if (mounted && !_isDisposed) {
      setState(() {
        _debugLogs.insert(0, '[$timestamp] $message');
        if (_debugLogs.length > 50) {
          _debugLogs.removeLast();
        }
      });
    }
  }

  Future<void> _initializeAll() async {
    _addLog('Starting initialization...');
    
    // 1. Camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _addLog('ERROR: Camera permission denied');
      return;
    }
    _addLog('Camera permission granted');
    
    // 2. Initialize camera
    await _initializeCamera();
    if (!_isCameraReady) return;
    
    // 3. Initialize MediaPipe (한 번만)
    if (!_isMediaPipeReady) {
      _addLog('Initializing MediaPipe...');
      try {
        await KwonMediapipeLandmarker.initialize(
          face: true,
          pose: false,
          faceOptions: const FaceOptions(
            numFaces: 1,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.5,
            outputBlendshapes: true,
            outputTransformationMatrix: false,
          ),
        );
        _isMediaPipeReady = true;
        _addLog('MediaPipe initialized: true');
      } catch (e) {
        _addLog('ERROR: MediaPipe init failed: $e');
        return;
      }
    }
    
    _addLog('All initialization complete!');
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    
    _addLog('Initializing camera...');
    
    // 기존 컨트롤러가 있으면 정리
    if (_cameraController != null) {
      try {
        await _cameraController!.dispose();
      } catch (_) {}
      _cameraController = null;
    }
    
    // 1. Get cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _addLog('ERROR: No cameras available');
      return;
    }
    _addLog('Found ${cameras.length} cameras');
    
    // 2. Select front camera
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _addLog('Using camera: ${frontCamera.name}, direction: ${frontCamera.lensDirection}');
    
    // 3. Create new camera controller
    final controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    try {
      await controller.initialize();
      
      // dispose 체크
      if (_isDisposed) {
        controller.dispose();
        return;
      }
      
      _cameraController = controller;
      _isCameraReady = true;
      
      _addLog('Camera initialized successfully');
      _addLog('Preview size: ${controller.value.previewSize}');
      
      if (mounted) setState(() {});
    } catch (e) {
      _addLog('ERROR: Camera init failed: $e');
      try {
        controller.dispose();
      } catch (_) {}
      _cameraController = null;
      _isCameraReady = false;
    }
  }

  void _startDetection() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _addLog('ERROR: Camera not ready');
      return;
    }
    
    _addLog('Starting detection...');
    _frameCount = 0;
    _processedFrames = 0;
    _detectedFrames = 0;
    _isProcessingFrame = false;
    _lastFpsUpdate = DateTime.now();
    _fpsFrameCount = 0;
    
    controller.startImageStream(_onCameraFrame);
    
    setState(() {
      _isDetecting = true;
    });
  }

  void _stopDetection() {
    _addLog('Stopping detection...');
    _cameraController?.stopImageStream();
    setState(() {
      _isDetecting = false;
      _isProcessingFrame = false;
    });
  }

  /// 카메라 프레임 콜백 - 비동기 처리의 핵심!
  void _onCameraFrame(CameraImage image) {
    // dispose 후에는 처리 안함
    if (_isDisposed || !mounted) return;
    
    _frameCount++;
    
    // 핵심: 이전 프레임 처리 중이면 스킵!
    if (_isProcessingFrame) {
      return;
    }
    
    // 처리 시작
    _isProcessingFrame = true;
    
    // 비동기로 처리 (await 없이!)
    _processFrame(image).then((_) {
      if (!_isDisposed) _isProcessingFrame = false;
    }).catchError((e) {
      if (!_isDisposed) {
        _isProcessingFrame = false;
        _addLog('Detection error: $e');
      }
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDisposed || !mounted) return;
    
    final controller = _cameraController;
    if (controller == null) return;
    
    _processedFrames++;
    
    // 30프레임마다 로그
    if (_processedFrames % 30 == 1) {
      _addLog('Processing frame #$_processedFrames, format: ${image.format.group}, planes: ${image.planes.length}');
      _addLog('Image size: ${image.width}x${image.height}');
      for (int i = 0; i < image.planes.length; i++) {
        _addLog('Plane $i: bytes=${image.planes[i].bytes.length}, bytesPerRow=${image.planes[i].bytesPerRow}');
      }
    }
    
    try {
      final result = await KwonMediapipeLandmarker.detectFromCamera(
        planes: image.planes.map((p) => p.bytes).toList(),
        width: image.width,
        height: image.height,
        rotation: controller.description.sensorOrientation,
        format: 'YUV420',
        bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
      );
      
      // dispose 후에는 결과 처리 안함
      if (_isDisposed || !mounted) return;
      
      if (result != null && result.hasFace) {
        _detectedFrames++;
        
        // 30프레임마다 로그
        if (_detectedFrames % 30 == 1) {
          _addLog('Face DETECTED! Landmarks: ${result.face!.landmarks.length}');
        }
        
        // FPS 계산
        _fpsFrameCount++;
        final now = DateTime.now();
        final elapsed = now.difference(_lastFpsUpdate!).inMilliseconds;
        if (elapsed >= 1000) {
          _fps = _fpsFrameCount * 1000 / elapsed;
          _fpsFrameCount = 0;
          _lastFpsUpdate = now;
        }
        
        // UI 업데이트
        _lastResult = result;
        if (_detectedFrames % 3 == 0 && mounted && !_isDisposed) {
          setState(() {});
        }
      }
    } catch (e) {
      if (_processedFrames % 30 == 1 && !_isDisposed) {
        _addLog('Detection error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediaPipe Face Landmarker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 2,
            child: _buildCameraPreview(),
          ),
          
          // Results
          Expanded(
            flex: 1,
            child: _buildResults(),
          ),
          
          // Debug logs
          Expanded(
            flex: 1,
            child: _buildDebugLogs(),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildCameraPreview() {
    // 1. 카메라 준비 안됨
    if (!_isCameraReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 준비 중...'),
          ],
        ),
      );
    }
    
    // 2. 컨트롤러 없음
    final controller = _cameraController;
    if (controller == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 초기화 중...'),
          ],
        ),
      );
    }
    
    // 3. 컨트롤러 초기화 안됨
    if (!controller.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('카메라 시작 중...'),
          ],
        ),
      );
    }
    
    // 4. 정상 - 카메라 프리뷰 표시
    return Container(
      color: Colors.black,
      child: Center(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize!.height,
                height: controller.value.previewSize!.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Results',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text('Total frames: $_frameCount | Processed: $_processedFrames | Detected: $_detectedFrames'),
          Text('FPS: ${_fps.toStringAsFixed(1)} | Skip rate: ${_frameCount > 0 ? (100 * (_frameCount - _processedFrames) / _frameCount).toStringAsFixed(1) : 0}%'),
          if (_lastResult != null && _lastResult!.face != null) ...[
            const SizedBox(height: 4),
            Text('Landmarks: ${_lastResult!.face!.landmarks.length}'),
            Text('Blendshapes: ${_lastResult!.face!.blendshapes.length}'),
            Text('Smile: ${(_lastResult!.face!.smileScore * 100).toInt()}%'),
            Text('Eye Contact: ${(_lastResult!.face!.eyeContactScore * 100).toInt()}%'),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugLogs() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black87,
      child: ListView.builder(
        itemCount: _debugLogs.length,
        itemBuilder: (context, index) {
          return Text(
            _debugLogs[index],
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    if (!_isCameraReady || !_isMediaPipeReady) {
      return const SizedBox.shrink();
    }
    
    return FloatingActionButton.extended(
      onPressed: _isDetecting ? _stopDetection : _startDetection,
      icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
      label: Text(_isDetecting ? 'Stop' : 'Start'),
      backgroundColor: _isDetecting ? Colors.red : Colors.green,
    );
  }
}
