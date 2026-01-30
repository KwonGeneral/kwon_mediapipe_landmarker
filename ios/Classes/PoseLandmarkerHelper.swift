import Foundation
import UIKit
import MediaPipeTasksVision

/**
 * Pose Landmarker Helper
 * MediaPipe Pose Landmarker 래퍼 클래스
 *
 * 33개 몸 랜드마크 (visibility + presence) 지원
 */
class PoseLandmarkerHelper {
    
    private var poseLandmarker: PoseLandmarker?
    
    private let numPoses: Int
    private let minDetectionConfidence: Float
    private let minTrackingConfidence: Float
    
    init(
        numPoses: Int = 1,
        minDetectionConfidence: Float = 0.5,
        minTrackingConfidence: Float = 0.5
    ) throws {
        self.numPoses = numPoses
        self.minDetectionConfidence = minDetectionConfidence
        self.minTrackingConfidence = minTrackingConfidence
        
        try setupPoseLandmarker()
    }
    
    private func setupPoseLandmarker() throws {
        // 모델 파일 경로 찾기
        guard let modelPath = Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task") else {
            // 플러그인 번들에서 찾기
            let bundle = Bundle(for: type(of: self))
            guard let path = bundle.path(forResource: "pose_landmarker_lite", ofType: "task") else {
                throw NSError(domain: "PoseLandmarkerHelper", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Model file not found: pose_landmarker_lite.task"])
            }
            try initializeLandmarker(modelPath: path)
            return
        }
        try initializeLandmarker(modelPath: modelPath)
    }
    
    private func initializeLandmarker(modelPath: String) throws {
        let options = PoseLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.numPoses = numPoses
        options.minPoseDetectionConfidence = minDetectionConfidence
        options.minPosePresenceConfidence = minDetectionConfidence
        options.minTrackingConfidence = minTrackingConfidence
        
        poseLandmarker = try PoseLandmarker(options: options)
    }
    
    /**
     * 이미지에서 포즈 감지
     * @param image 입력 이미지
     * @return 감지 결과 Dictionary (Flutter로 전송용)
     */
    func detect(image: UIImage) -> [String: Any]? {
        guard let landmarker = poseLandmarker else { return nil }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            return nil
        }
        
        do {
            let result = try landmarker.detect(image: mpImage)
            return convertResultToDict(result: result)
        } catch {
            print("Pose detection error: \(error)")
            return nil
        }
    }
    
    /**
     * PoseLandmarkerResult를 Flutter 전송용 Dictionary로 변환
     */
    private func convertResultToDict(result: PoseLandmarkerResult) -> [String: Any]? {
        guard !result.landmarks.isEmpty else {
            return nil
        }
        
        // 첫 번째 포즈만 처리
        let poseLandmarks = result.landmarks[0]
        
        // 정규화된 랜드마크 (33개)
        var landmarks: [[String: Any]] = []
        for (index, landmark) in poseLandmarks.enumerated() {
            var landmarkDict: [String: Any] = [
                "index": index,
                "x": landmark.x,
                "y": landmark.y,
                "z": landmark.z
            ]
            
            // visibility와 presence 추가
            if let visibility = landmark.visibility?.floatValue {
                landmarkDict["visibility"] = Double(visibility)
            }
            if let presence = landmark.presence?.floatValue {
                landmarkDict["presence"] = Double(presence)
            }
            
            landmarks.append(landmarkDict)
        }
        
        var resultDict: [String: Any] = [
            "landmarks": landmarks
        ]
        
        // 월드 랜드마크 (실제 3D 좌표, 미터 단위)
        if !result.worldLandmarks.isEmpty {
            let worldLandmarksList = result.worldLandmarks[0]
            var worldLandmarks: [[String: Any]] = []
            
            for (index, landmark) in worldLandmarksList.enumerated() {
                var landmarkDict: [String: Any] = [
                    "index": index,
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z
                ]
                
                if let visibility = landmark.visibility?.floatValue {
                    landmarkDict["visibility"] = Double(visibility)
                }
                if let presence = landmark.presence?.floatValue {
                    landmarkDict["presence"] = Double(presence)
                }
                
                worldLandmarks.append(landmarkDict)
            }
            
            resultDict["worldLandmarks"] = worldLandmarks
        }
        
        return resultDict
    }
    
    /**
     * 리소스 해제
     */
    func close() {
        poseLandmarker = nil
    }
}
