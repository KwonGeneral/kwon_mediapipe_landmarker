# kwon_mediapipe_landmarker - Claude Code 작업 컨텍스트

## 📍 프로젝트 위치
```
/Users/kwontaewan/Desktop/Project/kwon_mediapipe_landmarker
```

---

## 1. 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **패키지명** | kwon_mediapipe_landmarker |
| **org** | com.kwon |
| **플랫폼** | Android, iOS |
| **라이선스** | Apache 2.0 |
| **용도** | 영어 면접/프레젠테이션 연습 앱에서 표정, 시선, 자세 실시간 분석 |

### 핵심 기능
- **Face Landmarker**: 478개 얼굴 랜드마크 + 52개 블렌드쉐입(표정) + Transformation Matrix
- **Pose Landmarker**: 33개 몸 랜드마크 (visibility + presence)
- 실시간 카메라 프레임 분석

---

## 2. 구현 완료 상태

### ✅ 완료된 기능

| 기능 | Android | iOS | 비고 |
|------|---------|-----|------|
| Face Landmarker (478점) | ✅ | ✅ | 블렌드쉐입 52개 포함 |
| Pose Landmarker (33점) | ✅ | ✅ | World Landmarks 포함 |
| Face+Pose 동시 분석 | ✅ | ✅ | |
| YUV→RGB 네이티브 변환 | ✅ | ✅ (Core Video) | |
| 카메라 라이프사이클 | ✅ | ✅ | resume/pause 처리 |
| Dart Extensions | ✅ | ✅ | Face 14개, Pose 19개 헬퍼 |

### 성능 벤치마크

#### Android (Samsung SM-S938N, Snapdragon 8 Gen 3)
| 모드 | YUV 변환 | Detection | Total | FPS |
|------|----------|-----------|-------|-----|
| Face Only | 6-9ms | 35-45ms | 41-54ms | ~20 FPS |
| Face+Pose | 7-13ms | 41-68ms | 52-80ms | 12-15 FPS |

#### iOS (iPhone 16, A18 GPU)
| 모드 | Conversion | Detection | Total | FPS |
|------|------------|-----------|-------|-----|
| Face Only | 8-12ms | 6-10ms | 14-22ms | ~55 FPS |
| Face+Pose | 10-12ms | 13-19ms | 24-31ms | 32-40 FPS |

---

## 3. 디렉토리 구조

```
kwon_mediapipe_landmarker/
├── lib/
│   ├── kwon_mediapipe_landmarker.dart      # 메인 export
│   └── src/
│       ├── landmarker.dart                  # KwonMediapipeLandmarker 클래스
│       ├── options.dart                     # FaceOptions, PoseOptions
│       ├── result.dart                      # LandmarkerResult, FaceResult, PoseResult
│       ├── landmark.dart                    # Landmark 클래스
│       ├── constants/
│       │   ├── face_landmark_index.dart     # 478개 얼굴 랜드마크 인덱스
│       │   ├── face_blendshape.dart         # 52개 블렌드쉐입 상수
│       │   └── pose_landmark_index.dart     # 33개 포즈 랜드마크 인덱스
│       ├── extensions/
│       │   ├── face_result_helper.dart      # FaceResult 헬퍼 (14개 메서드)
│       │   └── pose_result_helper.dart      # PoseResult 헬퍼 (19개 메서드)
│       └── platform/
│           └── platform_channel.dart        # Platform Channel 정의
├── android/
│   └── src/main/kotlin/com/kwon/mediapipe_landmarker/
│       ├── KwonMediapipeLandmarkerPlugin.kt # 메인 플러그인
│       ├── FaceLandmarkerHelper.kt          # Face 분석 헬퍼
│       └── PoseLandmarkerHelper.kt          # Pose 분석 헬퍼
├── ios/
│   ├── kwon_mediapipe_landmarker.podspec
│   └── Classes/
│       ├── KwonMediapipeLandmarkerPlugin.swift
│       ├── FaceLandmarkerHelper.swift
│       └── PoseLandmarkerHelper.swift
├── example/
│   └── lib/
│       ├── main.dart                        # 기본 테스트 앱 (Face only)
│       └── main_with_pose.dart              # Face+Pose 테스트 앱
├── pubspec.yaml
├── README.md                                # ⬜ 작성 필요
├── LICENSE
└── CHANGELOG.md
```

---

## 4. 주요 파일 상세

### 4.1 Dart API

#### KwonMediapipeLandmarker (lib/src/landmarker.dart)
```dart
class KwonMediapipeLandmarker {
  static Future<void> initialize({
    bool face = true,
    bool pose = false,
    FaceOptions? faceOptions,
    PoseOptions? poseOptions,
  });
  
  static Future<LandmarkerResult> detect(Uint8List imageBytes);
  static Stream<LandmarkerResult> detectStream(CameraImage cameraImage);
  static Future<void> dispose();
  static bool get isInitialized;
}
```

#### Options (lib/src/options.dart)
```dart
class FaceOptions {
  final int numFaces;                    // 기본: 1
  final double minDetectionConfidence;   // 기본: 0.5
  final double minTrackingConfidence;    // 기본: 0.5
  final bool outputBlendshapes;          // 기본: true
  final bool outputTransformationMatrix; // 기본: false
}

class PoseOptions {
  final int numPoses;                    // 기본: 1
  final double minDetectionConfidence;   // 기본: 0.5
  final double minTrackingConfidence;    // 기본: 0.5
}
```

#### Result Classes (lib/src/result.dart)
```dart
class LandmarkerResult {
  final FaceResult? face;
  final PoseResult? pose;
  final int timestampMs;
}

class FaceResult {
  final List<Landmark> landmarks;           // 478개
  final Map<String, double> blendshapes;    // 52개
  final List<double>? transformationMatrix; // 4x4 (선택)
}

class PoseResult {
  final List<Landmark> landmarks;           // 33개
  final List<Landmark>? worldLandmarks;     // 33개 (미터 단위)
}
```

### 4.2 Extensions 상세

#### FaceResultHelper (14개 메서드)
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `eyeContactScore` | double | 시선 점수 (0~1, 정면 응시) |
| `smileScore` | double | 미소 점수 (0~1) |
| `tensionScore` | double | 긴장도 (눈 찡그림+눈썹 내림) |
| `isBlinking` | bool | 눈 깜빡임 감지 |
| `isBothEyesBlinking` | bool | 양쪽 눈 깜빡임 |
| `mouthOpenness` | double | 입 벌림 정도 |
| `isSpeaking` | bool | 말하는 중 감지 |
| `isSurprised` | bool | 놀람 표정 |
| `isFrowning` | bool | 찡그림 표정 |
| `isLipsPursed` | bool | 입술 오므림 |
| `horizontalGazeDirection` | double | 수평 시선 (-1:왼쪽, 1:오른쪽) |
| `verticalGazeDirection` | double | 수직 시선 (-1:위, 1:아래) |
| `naturalExpressionScore` | double | 자연스러움 점수 |
| `symmetryScore` | double | 좌우 대칭 점수 |

#### PoseResultHelper (19개 메서드)
| 메서드 | 반환 | 설명 |
|--------|------|------|
| `shoulderSymmetryScore` | double | 어깨 대칭 점수 (수평도) |
| `isShoulderTensed` | bool | 어깨 움츠림 감지 |
| `isLeftHandVisible` | bool | 왼손 보임 |
| `isRightHandVisible` | bool | 오른손 보임 |
| `areBothHandsVisible` | bool | 양손 보임 |
| `headTilt` | double | 고개 기울기 (라디안) |
| `headTiltDegrees` | double | 고개 기울기 (도) |
| `torsoTilt` | double | 몸통 기울기 (라디안) |
| `torsoTiltDegrees` | double | 몸통 기울기 (도) |
| `postureScore` | double | 자세 바름 종합 점수 |
| `isLeftArmRaised` | bool | 왼팔 들어올림 |
| `isRightArmRaised` | bool | 오른팔 들어올림 |
| `areBothArmsRaised` | bool | 양팔 들어올림 |
| `isHandNearFace` | bool | 손이 얼굴 근처 (긴장 신호) |
| `isArmsCrossed` | bool | 팔짱 끼기 감지 |
| `shoulderWidth` | double | 어깨 너비 |
| `horizontalPosition` | double | 프레임 내 수평 위치 |
| `centerPositionScore` | double | 화면 중앙 위치 점수 |
| `isUpperBodyVisible` | bool | 상체 보임 여부 |

### 4.3 Native Models

| 플랫폼 | 파일 위치 |
|--------|----------|
| Android | `android/src/main/assets/face_landmarker.task` |
| Android | `android/src/main/assets/pose_landmarker_lite.task` |
| iOS | `ios/Assets/face_landmarker.task` |
| iOS | `ios/Assets/pose_landmarker_lite.task` |

### 4.4 네이티브 의존성

| 플랫폼 | 라이브러리 | 버전 |
|--------|-----------|------|
| Android | `com.google.mediapipe:tasks-vision` | latest.release |
| iOS | `MediaPipeTasksVision` | ~> 0.10.21 |

---

## 5. 에러 핸들링 요구사항

### 5.1 현재 에러 처리 현황
- 기본적인 null 체크만 존재
- 모델 로드 실패 시 예외 throw
- 상세한 에러 코드/메시지 없음

### 5.2 추가해야 할 에러 핸들링

#### Dart 레벨
```dart
/// 에러 코드 enum
enum LandmarkerError {
  notInitialized,        // 초기화 안됨
  modelLoadFailed,       // 모델 로드 실패
  invalidImage,          // 잘못된 이미지
  detectionFailed,       // 감지 실패
  cameraPermissionDenied,// 카메라 권한 없음
  platformNotSupported,  // 지원하지 않는 플랫폼
}

/// 커스텀 예외 클래스
class LandmarkerException implements Exception {
  final LandmarkerError error;
  final String message;
  final dynamic originalError;
}
```

#### 처리해야 할 케이스
1. **초기화 전 detect 호출** → LandmarkerException(notInitialized)
2. **모델 파일 없음** → LandmarkerException(modelLoadFailed)
3. **잘못된 이미지 포맷** → LandmarkerException(invalidImage)
4. **네이티브 감지 실패** → LandmarkerException(detectionFailed)
5. **카메라 권한 거부** → LandmarkerException(cameraPermissionDenied)

#### Native 레벨
- Android: try-catch로 예외 잡아서 Flutter에 에러 코드 전달
- iOS: do-catch로 예외 잡아서 Flutter에 에러 코드 전달

---

## 6. README.md 작성 가이드

### 필수 포함 섹션

1. **배지 (Badges)**
   - pub.dev 버전
   - 라이선스
   - 플랫폼 (Android/iOS)

2. **소개**
   - 프로젝트 목적
   - 핵심 기능 3줄 요약

3. **Features**
   - Face Landmarker (478점, 52 블렌드쉐입)
   - Pose Landmarker (33점)
   - 실시간 카메라 분석
   - 풍부한 헬퍼 Extension

4. **성능**
   - Android/iOS 벤치마크 표
   - 테스트 기기 스펙

5. **Installation**
   ```yaml
   dependencies:
     kwon_mediapipe_landmarker: ^1.0.0
   ```
   - Android 추가 설정 (minSdk, permissions)
   - iOS 추가 설정 (Podfile, Info.plist)

6. **Quick Start**
   - 초기화 코드
   - 단일 이미지 분석
   - 카메라 스트림 분석

7. **API Reference**
   - KwonMediapipeLandmarker 메서드
   - Options 클래스
   - Result 클래스

8. **Extensions (헬퍼)**
   - FaceResultHelper 전체 목록 + 설명
   - PoseResultHelper 전체 목록 + 설명
   - 사용 예시

9. **Constants**
   - FaceLandmarkIndex 주요 인덱스
   - PoseLandmarkIndex 전체
   - FaceBlendshape 전체

10. **Use Cases**
    - 면접 연습 앱 (시선+미소+긴장도)
    - 프레젠테이션 분석 (자세+제스처)
    - 실시간 피드백 UI 예시

11. **Troubleshooting**
    - 자주 발생하는 에러와 해결법

12. **License**
    - Apache 2.0

---

## 7. 테스트 앱 정보

### 7.1 main.dart (Face Only)
- Face Landmarker만 테스트
- 블렌드쉐입 표시
- 시선 점수, 미소 점수 표시

### 7.2 main_with_pose.dart (Face + Pose)
- Face + Pose 동시 테스트
- 토글 버튼으로 on/off
- Pose 메트릭 표시:
  - 어깨 대칭 점수
  - 어깨 움츠림 감지
  - 왼손/오른손 보임
- 성능 로그 출력

---

## 8. 주의사항

### 절대 수정하면 안 되는 부분
1. **YUV 변환 로직** (Android: nativeYuvToRgb, iOS: Core Video)
   - 현재 최적화 완료 상태
2. **Helper 클래스 초기화 순서**
3. **iOS MPImage orientation 처리**
4. **카메라 라이프사이클 처리 로직**

### 알려진 Warning (무시해도 됨)
- `landmark_projection_calculator.cc:186` - MediaPipe 내부 경고
- `inference_feedback_manager.cc:114` - TensorFlow Lite 경고

---

## 9. 작업 체크리스트

### Task 1: 에러 핸들링 추가
- [ ] lib/src/exceptions.dart 생성 (LandmarkerError, LandmarkerException)
- [ ] lib/src/landmarker.dart에 에러 처리 추가
- [ ] Android Plugin에 에러 코드 전달 로직 추가
- [ ] iOS Plugin에 에러 코드 전달 로직 추가
- [ ] example 앱에서 에러 처리 예시 추가

### Task 2: README.md 작성
- [ ] 위 가이드 섹션 전부 포함
- [ ] 코드 예시는 실제 동작하는 코드로
- [ ] 성능 벤치마크 표 포함
- [ ] Extension 메서드 전체 문서화

### Task 3: 최종 검증
- [ ] flutter analyze 통과
- [ ] example 앱 Android 빌드 성공
- [ ] example 앱 iOS 빌드 성공
- [ ] Face+Pose 동시 동작 확인

---

## 10. 참고 자료

- [MediaPipe Face Landmarker](https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker)
- [MediaPipe Pose Landmarker](https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker)
- [Face Landmarker Android Guide](https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker/android)
- [Face Landmarker iOS Guide](https://ai.google.dev/edge/mediapipe/solutions/vision/face_landmarker/ios)
