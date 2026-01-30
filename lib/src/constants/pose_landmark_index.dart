/// Pose 랜드마크 인덱스 (0-32)
class PoseLandmarkIndex {
  PoseLandmarkIndex._();

  /// Pose 랜드마크 총 개수
  static const int count = 33;

  // ===== 얼굴 (Face) - 0~10 =====
  /// 코
  static const int nose = 0;

  /// 왼쪽 눈 안쪽
  static const int leftEyeInner = 1;

  /// 왼쪽 눈
  static const int leftEye = 2;

  /// 왼쪽 눈 바깥쪽
  static const int leftEyeOuter = 3;

  /// 오른쪽 눈 안쪽
  static const int rightEyeInner = 4;

  /// 오른쪽 눈
  static const int rightEye = 5;

  /// 오른쪽 눈 바깥쪽
  static const int rightEyeOuter = 6;

  /// 왼쪽 귀
  static const int leftEar = 7;

  /// 오른쪽 귀
  static const int rightEar = 8;

  /// 입 왼쪽
  static const int mouthLeft = 9;

  /// 입 오른쪽
  static const int mouthRight = 10;

  // ===== 상체 (Upper Body) - 11~22 =====
  /// 왼쪽 어깨
  static const int leftShoulder = 11;

  /// 오른쪽 어깨
  static const int rightShoulder = 12;

  /// 왼쪽 팔꿈치
  static const int leftElbow = 13;

  /// 오른쪽 팔꿈치
  static const int rightElbow = 14;

  /// 왼쪽 손목
  static const int leftWrist = 15;

  /// 오른쪽 손목
  static const int rightWrist = 16;

  /// 왼쪽 새끼손가락
  static const int leftPinky = 17;

  /// 오른쪽 새끼손가락
  static const int rightPinky = 18;

  /// 왼쪽 검지손가락
  static const int leftIndex = 19;

  /// 오른쪽 검지손가락
  static const int rightIndex = 20;

  /// 왼쪽 엄지손가락
  static const int leftThumb = 21;

  /// 오른쪽 엄지손가락
  static const int rightThumb = 22;

  // ===== 하체 (Lower Body) - 23~32 =====
  /// 왼쪽 엉덩이
  static const int leftHip = 23;

  /// 오른쪽 엉덩이
  static const int rightHip = 24;

  /// 왼쪽 무릎
  static const int leftKnee = 25;

  /// 오른쪽 무릎
  static const int rightKnee = 26;

  /// 왼쪽 발목
  static const int leftAnkle = 27;

  /// 오른쪽 발목
  static const int rightAnkle = 28;

  /// 왼쪽 발뒤꿈치
  static const int leftHeel = 29;

  /// 오른쪽 발뒤꿈치
  static const int rightHeel = 30;

  /// 왼쪽 발가락 끝
  static const int leftFootIndex = 31;

  /// 오른쪽 발가락 끝
  static const int rightFootIndex = 32;

  // ===== 유용한 그룹 =====

  /// 얼굴 랜드마크 인덱스들
  static const List<int> faceIndices = [
    nose,
    leftEyeInner,
    leftEye,
    leftEyeOuter,
    rightEyeInner,
    rightEye,
    rightEyeOuter,
    leftEar,
    rightEar,
    mouthLeft,
    mouthRight,
  ];

  /// 상체 랜드마크 인덱스들
  static const List<int> upperBodyIndices = [
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftPinky,
    rightPinky,
    leftIndex,
    rightIndex,
    leftThumb,
    rightThumb,
  ];

  /// 하체 랜드마크 인덱스들
  static const List<int> lowerBodyIndices = [
    leftHip,
    rightHip,
    leftKnee,
    rightKnee,
    leftAnkle,
    rightAnkle,
    leftHeel,
    rightHeel,
    leftFootIndex,
    rightFootIndex,
  ];

  /// 왼팔 랜드마크 인덱스들
  static const List<int> leftArmIndices = [
    leftShoulder,
    leftElbow,
    leftWrist,
    leftPinky,
    leftIndex,
    leftThumb,
  ];

  /// 오른팔 랜드마크 인덱스들
  static const List<int> rightArmIndices = [
    rightShoulder,
    rightElbow,
    rightWrist,
    rightPinky,
    rightIndex,
    rightThumb,
  ];

  /// 왼다리 랜드마크 인덱스들
  static const List<int> leftLegIndices = [
    leftHip,
    leftKnee,
    leftAnkle,
    leftHeel,
    leftFootIndex,
  ];

  /// 오른다리 랜드마크 인덱스들
  static const List<int> rightLegIndices = [
    rightHip,
    rightKnee,
    rightAnkle,
    rightHeel,
    rightFootIndex,
  ];

  /// 몸통 중심선 랜드마크 인덱스들 (자세 분석에 유용)
  static const List<int> torsoIndices = [
    nose,
    leftShoulder,
    rightShoulder,
    leftHip,
    rightHip,
  ];

  /// 어깨 라인 (좌우 대칭 분석용)
  static const List<int> shoulderLine = [
    leftShoulder,
    rightShoulder,
  ];

  /// 엉덩이 라인 (좌우 대칭 분석용)
  static const List<int> hipLine = [
    leftHip,
    rightHip,
  ];

  /// 손 끝점들 (손 제스처 분석용)
  static const List<int> handTips = [
    leftPinky,
    leftIndex,
    leftThumb,
    rightPinky,
    rightIndex,
    rightThumb,
  ];
}
