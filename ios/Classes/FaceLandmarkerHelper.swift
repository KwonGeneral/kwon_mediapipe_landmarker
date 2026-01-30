import Foundation

/**
 * Face Landmarker Helper
 * MediaPipe Face Landmarker 래퍼 클래스
 *
 * TODO: 실제 MediaPipe 구현 예정
 */
class FaceLandmarkerHelper {
    
    private let numFaces: Int
    private let minDetectionConfidence: Float
    private let minTrackingConfidence: Float
    private let outputBlendshapes: Bool
    private let outputTransformationMatrix: Bool
    
    init(
        numFaces: Int = 1,
        minDetectionConfidence: Float = 0.5,
        minTrackingConfidence: Float = 0.5,
        outputBlendshapes: Bool = true,
        outputTransformationMatrix: Bool = false
    ) {
        self.numFaces = numFaces
        self.minDetectionConfidence = minDetectionConfidence
        self.minTrackingConfidence = minTrackingConfidence
        self.outputBlendshapes = outputBlendshapes
        self.outputTransformationMatrix = outputTransformationMatrix
    }
    
    func close() {
        // TODO: 리소스 해제
    }
}
