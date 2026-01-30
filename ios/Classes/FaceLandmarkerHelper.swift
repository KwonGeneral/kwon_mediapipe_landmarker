import Foundation
import UIKit
import MediaPipeTasksVision

/**
 * Face Landmarker Helper - VIDEO 모드
 * MediaPipe Face Landmarker 래퍼 클래스
 *
 * 478개 얼굴 랜드마크 + 52개 블렌드쉐입 지원
 */
class FaceLandmarkerHelper {
    
    private var faceLandmarker: FaceLandmarker?
    private var lastTimestampMs: Int = 0
    
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
    ) throws {
        self.numFaces = numFaces
        self.minDetectionConfidence = minDetectionConfidence
        self.minTrackingConfidence = minTrackingConfidence
        self.outputBlendshapes = outputBlendshapes
        self.outputTransformationMatrix = outputTransformationMatrix
        
        try setupFaceLandmarker()
    }
    
    private func setupFaceLandmarker() throws {
        // 모델 파일 경로 찾기
        guard let modelPath = Bundle.main.path(forResource: "face_landmarker", ofType: "task") else {
            // 플러그인 번들에서 찾기
            let bundle = Bundle(for: type(of: self))
            guard let path = bundle.path(forResource: "face_landmarker", ofType: "task") else {
                throw NSError(domain: "FaceLandmarkerHelper", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Model file not found: face_landmarker.task"])
            }
            try initializeLandmarker(modelPath: path)
            return
        }
        try initializeLandmarker(modelPath: modelPath)
    }
    
    private func initializeLandmarker(modelPath: String) throws {
        let options = FaceLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .video  // VIDEO 모드 - tracking 활용!
        options.numFaces = numFaces
        options.minFaceDetectionConfidence = minDetectionConfidence
        options.minFacePresenceConfidence = minDetectionConfidence
        options.minTrackingConfidence = minTrackingConfidence
        options.outputFaceBlendshapes = outputBlendshapes
        options.outputFacialTransformationMatrixes = outputTransformationMatrix
        
        faceLandmarker = try FaceLandmarker(options: options)
        print("[FaceLandmarkerHelper] Initialized with VIDEO mode")
    }
    
    /**
     * 이미지에서 얼굴 감지 (VIDEO 모드)
     * @param image 입력 이미지
     * @return 감지 결과 Dictionary (Flutter로 전송용)
     */
    func detect(image: UIImage) -> [String: Any]? {
        guard let landmarker = faceLandmarker else { return nil }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            return nil
        }
        
        // VIDEO 모드는 timestamp가 항상 증가해야 함
        let currentTimestampMs = Int(Date().timeIntervalSince1970 * 1000)
        let safeTimestamp = currentTimestampMs > lastTimestampMs ? currentTimestampMs : lastTimestampMs + 1
        lastTimestampMs = safeTimestamp
        
        do {
            // VIDEO 모드: detect(videoFrame:timestampInMilliseconds:) 사용
            let result = try landmarker.detect(videoFrame: mpImage, timestampInMilliseconds: safeTimestamp)
            return convertResultToDict(result: result)
        } catch {
            print("Face detection error: \(error)")
            return nil
        }
    }
    
    /**
     * FaceLandmarkerResult를 Flutter 전송용 Dictionary로 변환
     */
    private func convertResultToDict(result: FaceLandmarkerResult) -> [String: Any]? {
        guard !result.faceLandmarks.isEmpty else {
            return nil
        }
        
        // 첫 번째 얼굴만 처리
        let faceLandmarks = result.faceLandmarks[0]
        
        // 랜드마크 변환 (478개)
        var landmarks: [[String: Any]] = []
        for (index, landmark) in faceLandmarks.enumerated() {
            landmarks.append([
                "index": index,
                "x": landmark.x,
                "y": landmark.y,
                "z": landmark.z
            ])
        }
        
        // 블렌드쉐입 변환 (52개)
        var blendshapes: [String: Double] = [:]
        if outputBlendshapes, !result.faceBlendshapes.isEmpty {
            let faceBlendshapes = result.faceBlendshapes[0]
            for i in 0..<faceBlendshapes.categories.count {
                let category = faceBlendshapes.categories[i]
                if let name = category.categoryName {
                    blendshapes[name] = Double(category.score)
                }
            }
        }
        
        return [
            "landmarks": landmarks,
            "blendshapes": blendshapes
        ]
    }
    
    /**
     * 리소스 해제
     */
    func close() {
        faceLandmarker = nil
    }
}
