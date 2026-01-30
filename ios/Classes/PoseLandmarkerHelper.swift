import Foundation
import MediaPipeTasksVision
import UIKit

/**
 * Pose Landmarker Helper
 * MediaPipe Pose Landmarker 래퍼 클래스 (iOS)
 *
 * 33개 신체 랜드마크 감지
 */
class PoseLandmarkerHelper {
    
    private var poseLandmarker: PoseLandmarker?
    
    private let numPoses: Int
    private let minDetectionConfidence: Float
    private let minTrackingConfidence: Float
    private let minPosePresenceConfidence: Float
    private let runningMode: RunningMode
    
    init(
        numPoses: Int = 1,
        minDetectionConfidence: Float = 0.5,
        minTrackingConfidence: Float = 0.5,
        minPosePresenceConfidence: Float = 0.5,
        runningMode: RunningMode = .video
    ) throws {
        self.numPoses = numPoses
        self.minDetectionConfidence = minDetectionConfidence
        self.minTrackingConfidence = minTrackingConfidence
        self.minPosePresenceConfidence = minPosePresenceConfidence
        self.runningMode = runningMode
        
        try setupPoseLandmarker()
    }
    
    private func setupPoseLandmarker() throws {
        // 모델 파일 찾기 (Bundle에서)
        guard let modelPath = Bundle.main.path(
            forResource: "pose_landmarker_lite",
            ofType: "task"
        ) else {
            // Frameworks에서 찾기
            let frameworkBundle = Bundle(for: PoseLandmarkerHelper.self)
            guard let frameworkModelPath = frameworkBundle.path(
                forResource: "pose_landmarker_lite",
                ofType: "task"
            ) else {
                throw NSError(
                    domain: "PoseLandmarkerHelper",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "pose_landmarker_lite.task not found in bundle"]
                )
            }
            try createLandmarker(modelPath: frameworkModelPath)
            return
        }
        
        try createLandmarker(modelPath: modelPath)
    }
    
    private func createLandmarker(modelPath: String) throws {
        let baseOptions = BaseOptions()
        baseOptions.modelAssetPath = modelPath
        
        let options = PoseLandmarkerOptions()
        options.baseOptions = baseOptions
        options.numPoses = numPoses
        options.minPoseDetectionConfidence = minDetectionConfidence
        options.minTrackingConfidence = minTrackingConfidence
        options.minPosePresenceConfidence = minPosePresenceConfidence
        options.runningMode = runningMode
        // Note: outputSegmentationMasks는 iOS SDK에서 지원 안함
        
        poseLandmarker = try PoseLandmarker(options: options)
        
        print("[PoseLandmarkerHelper] Initialized successfully")
    }
    
    /**
     * UIImage에서 포즈 감지
     */
    func detect(image: UIImage) -> [String: Any?]? {
        guard let landmarker = poseLandmarker else {
            print("[PoseLandmarkerHelper] Landmarker not initialized")
            return nil
        }
        
        guard let mpImage = try? MPImage(uiImage: image) else {
            print("[PoseLandmarkerHelper] Failed to create MPImage from UIImage")
            return nil
        }
        
        do {
            let result: PoseLandmarkerResult
            
            switch runningMode {
            case .video:
                let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
                result = try landmarker.detect(videoFrame: mpImage, timestampInMilliseconds: timestampMs)
            case .image:
                result = try landmarker.detect(image: mpImage)
            default:
                return nil
            }
            
            return convertResultToMap(result: result)
        } catch {
            print("[PoseLandmarkerHelper] Detection failed: \(error)")
            return nil
        }
    }
    
    /**
     * CVPixelBuffer에서 포즈 감지 (카메라 프레임용)
     */
    func detect(pixelBuffer: CVPixelBuffer, orientation: UIImage.Orientation = .up) -> [String: Any?]? {
        guard let landmarker = poseLandmarker else {
            print("[PoseLandmarkerHelper] Landmarker not initialized")
            return nil
        }
        
        guard let mpImage = try? MPImage(pixelBuffer: pixelBuffer, orientation: orientation) else {
            print("[PoseLandmarkerHelper] Failed to create MPImage from CVPixelBuffer")
            return nil
        }
        
        do {
            let result: PoseLandmarkerResult
            
            switch runningMode {
            case .video:
                let timestampMs = Int(Date().timeIntervalSince1970 * 1000)
                result = try landmarker.detect(videoFrame: mpImage, timestampInMilliseconds: timestampMs)
            case .image:
                result = try landmarker.detect(image: mpImage)
            default:
                return nil
            }
            
            return convertResultToMap(result: result)
        } catch {
            print("[PoseLandmarkerHelper] Detection failed: \(error)")
            return nil
        }
    }
    
    /**
     * PoseLandmarkerResult를 Flutter 전달용 Dictionary로 변환
     */
    private func convertResultToMap(result: PoseLandmarkerResult) -> [String: Any?]? {
        guard !result.landmarks.isEmpty else {
            return nil
        }
        
        // 첫 번째 포즈만 사용
        let landmarks = result.landmarks[0]
        let worldLandmarks = result.worldLandmarks.isEmpty ? nil : result.worldLandmarks[0]
        
        print("[PoseLandmarkerHelper] Pose detected! landmarks=\(landmarks.count)")
        
        // Normalized landmarks (0.0~1.0)
        var landmarksList: [[String: Any]] = []
        for (index, landmark) in landmarks.enumerated() {
            landmarksList.append([
                "index": index,
                "x": landmark.x,
                "y": landmark.y,
                "z": landmark.z,
                "visibility": landmark.visibility?.floatValue ?? 0.0,
                "presence": landmark.presence?.floatValue ?? 0.0
            ])
        }
        
        // World landmarks (미터 단위)
        var worldLandmarksList: [[String: Any]]? = nil
        if let worldLandmarks = worldLandmarks {
            worldLandmarksList = []
            for (index, landmark) in worldLandmarks.enumerated() {
                worldLandmarksList?.append([
                    "index": index,
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "visibility": landmark.visibility?.floatValue ?? 0.0,
                    "presence": landmark.presence?.floatValue ?? 0.0
                ])
            }
        }
        
        return [
            "landmarks": landmarksList,
            "worldLandmarks": worldLandmarksList as Any
        ]
    }
    
    /**
     * 리소스 해제
     */
    func close() {
        poseLandmarker = nil
        print("[PoseLandmarkerHelper] Closed")
    }
}
