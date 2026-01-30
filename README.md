# kwon_mediapipe_landmarker

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green.svg)](https://flutter.dev)

Flutter plugin for **MediaPipe Face and Pose Landmarker**.  
Real-time facial expression, eye contact, and posture analysis for interview/presentation practice apps.

## Features

- **Face Landmarker**: 478 facial landmarks + 52 blendshapes (expressions) + Transformation Matrix
- **Pose Landmarker**: 33 body landmarks with visibility & presence scores
- Real-time camera frame analysis (30fps target)
- Built-in helper extensions for common metrics:
  - Eye contact score
  - Smile score
  - Tension score
  - Shoulder symmetry
  - Posture score

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  kwon_mediapipe_landmarker:
    git:
      url: https://github.com/your-username/kwon_mediapipe_landmarker.git
```

## Usage

### Basic Setup

```dart
import 'package:kwon_mediapipe_landmarker/kwon_mediapipe_landmarker.dart';

// Initialize
await KwonMediapipeLandmarker.initialize(
  face: true,
  pose: true,
  faceOptions: FaceOptions(
    numFaces: 1,
    outputBlendshapes: true,
  ),
  poseOptions: PoseOptions(
    numPoses: 1,
  ),
);
```

### Single Image Analysis

```dart
final imageBytes = await file.readAsBytes();
final result = await KwonMediapipeLandmarker.detect(imageBytes);

if (result.face != null) {
  print('Eye Contact: ${result.face!.eyeContactScore}');
  print('Smile: ${result.face!.smileScore}');
  print('Tension: ${result.face!.tensionScore}');
}

if (result.pose != null) {
  print('Shoulder Symmetry: ${result.pose!.shoulderSymmetryScore}');
  print('Posture Score: ${result.pose!.postureScore}');
}
```

### Real-time Camera Analysis

```dart
import 'package:camera/camera.dart';

CameraController controller;

controller.startImageStream((CameraImage image) async {
  final result = await KwonMediapipeLandmarker.detectFromCamera(
    planes: image.planes.map((p) => p.bytes).toList(),
    width: image.width,
    height: image.height,
    rotation: camera.sensorOrientation,
    format: image.format.group.name,
  );
  
  // Update UI with result
});
```

### Cleanup

```dart
@override
void dispose() {
  KwonMediapipeLandmarker.dispose();
  super.dispose();
}
```

## API Reference

### Face Metrics (via `FaceResultHelper` extension)

| Property | Type | Description |
|----------|------|-------------|
| `eyeContactScore` | `double` | 0.0~1.0, higher = looking at camera |
| `smileScore` | `double` | 0.0~1.0, smile intensity |
| `tensionScore` | `double` | 0.0~1.0, facial tension level |
| `isBlinking` | `bool` | Eye blink detection |
| `isSpeaking` | `bool` | Mouth movement detection |
| `mouthOpenness` | `double` | 0.0~1.0, jaw open amount |
| `horizontalGazeDirection` | `double` | -1.0 (left) to 1.0 (right) |
| `verticalGazeDirection` | `double` | -1.0 (up) to 1.0 (down) |

### Pose Metrics (via `PoseResultHelper` extension)

| Property | Type | Description |
|----------|------|-------------|
| `shoulderSymmetryScore` | `double` | 0.0~1.0, shoulder levelness |
| `isShoulderTensed` | `bool` | Shoulders raised (tension) |
| `postureScore` | `double` | 0.0~1.0, overall posture quality |
| `headTiltDegrees` | `double` | Head tilt in degrees |
| `isHandNearFace` | `bool` | Hand touching face detection |
| `isArmsCrossed` | `bool` | Arms crossed detection |
| `centerPositionScore` | `double` | 0.0~1.0, centered in frame |

## Requirements

- Flutter 3.0+
- Android: minSdk 24+
- iOS: 12.0+

## License

Apache License 2.0 - see [LICENSE](LICENSE) file.

## Acknowledgments

- [Google MediaPipe](https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker) for the ML models
