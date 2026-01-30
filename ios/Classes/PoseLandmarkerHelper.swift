import Foundation

/**
 * Pose Landmarker Helper
 * MediaPipe Pose Landmarker 래퍼 클래스
 *
 * TODO: 실제 MediaPipe 구현 예정
 */
class PoseLandmarkerHelper {
    
    private let numPoses: Int
    private let minDetectionConfidence: Float
    private let minTrackingConfidence: Float
    
    init(
        numPoses: Int = 1,
        minDetectionConfidence: Float = 0.5,
        minTrackingConfidence: Float = 0.5
    ) {
        self.numPoses = numPoses
        self.minDetectionConfidence = minDetectionConfidence
        self.minTrackingConfidence = minTrackingConfidence
    }
    
    func close() {
        // TODO: 리소스 해제
    }
}
