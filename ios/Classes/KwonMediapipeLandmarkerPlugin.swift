import Flutter
import UIKit

public class KwonMediapipeLandmarkerPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    
    private var faceLandmarkerHelper: FaceLandmarkerHelper?
    private var poseLandmarkerHelper: PoseLandmarkerHelper?
    
    private var isInitialized = false
    private var faceEnabled = false
    private var poseEnabled = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.kwon.mediapipe_landmarker",
            binaryMessenger: registrar.messenger()
        )
        
        let eventChannel = FlutterEventChannel(
            name: "com.kwon.mediapipe_landmarker/stream",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = KwonMediapipeLandmarkerPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "detect":
            handleDetect(call, result: result)
        case "startStream":
            result(nil)
        case "stopStream":
            result(nil)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        do {
            faceEnabled = args["enableFace"] as? Bool ?? true
            poseEnabled = args["enablePose"] as? Bool ?? false
            
            // TODO: MediaPipe 초기화 로직 추가 예정
            
            isInitialized = true
            result(nil)
        } catch {
            result(FlutterError(code: "INITIALIZATION_FAILED", message: error.localizedDescription, details: nil))
        }
    }
    
    private func handleDetect(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Landmarker is not initialized", details: nil))
            return
        }
        
        // TODO: MediaPipe 감지 로직 추가 예정
        
        // 임시 빈 결과 반환
        let response: [String: Any?] = [
            "timestampMs": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        result(response)
    }
    
    private func handleDispose(result: @escaping FlutterResult) {
        faceLandmarkerHelper?.close()
        poseLandmarkerHelper?.close()
        faceLandmarkerHelper = nil
        poseLandmarkerHelper = nil
        isInitialized = false
        faceEnabled = false
        poseEnabled = false
        result(nil)
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
