package com.kwon.mediapipe_landmarker

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult

/**
 * Pose Landmarker Helper
 * MediaPipe Pose Landmarker 래퍼 클래스
 *
 * 33개 몸 랜드마크 (visibility + presence) 지원
 */
class PoseLandmarkerHelper(
    private val context: Context,
    private val numPoses: Int = 1,
    private val minDetectionConfidence: Float = 0.5f,
    private val minTrackingConfidence: Float = 0.5f,
    private val runningMode: RunningMode = RunningMode.IMAGE
) {
    private var poseLandmarker: PoseLandmarker? = null

    companion object {
        private const val MODEL_POSE_LANDMARKER = "pose_landmarker_lite.task"
    }

    init {
        setupPoseLandmarker()
    }

    private fun setupPoseLandmarker() {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(MODEL_POSE_LANDMARKER)
                .setDelegate(Delegate.CPU)
                .build()

            val options = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(runningMode)
                .setNumPoses(numPoses)
                .setMinPoseDetectionConfidence(minDetectionConfidence)
                .setMinTrackingConfidence(minTrackingConfidence)
                .setMinPosePresenceConfidence(minDetectionConfidence)
                .setOutputSegmentationMasks(false)
                .build()

            poseLandmarker = PoseLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            throw RuntimeException("Failed to initialize Pose Landmarker: ${e.message}", e)
        }
    }

    /**
     * 이미지에서 포즈 감지
     * @param bitmap 입력 이미지
     * @param timestampMs 타임스탬프 (밀리초)
     * @return 감지 결과 Map (Flutter로 전송용)
     */
    fun detect(bitmap: Bitmap, timestampMs: Long): Map<String, Any>? {
        val landmarker = poseLandmarker ?: return null

        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = landmarker.detect(mpImage)

            return convertResultToMap(result)
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    /**
     * PoseLandmarkerResult를 Flutter 전송용 Map으로 변환
     */
    private fun convertResultToMap(result: PoseLandmarkerResult): Map<String, Any>? {
        if (result.landmarks().isEmpty()) {
            return null
        }

        // 첫 번째 포즈만 처리 (numPoses=1 기준)
        val poseLandmarks = result.landmarks()[0]

        // 정규화된 랜드마크 (이미지 좌표계)
        val landmarks = mutableListOf<Map<String, Any>>()
        poseLandmarks.forEachIndexed { index, landmark ->
            val landmarkMap = mutableMapOf<String, Any>(
                "index" to index,
                "x" to landmark.x(),
                "y" to landmark.y(),
                "z" to landmark.z()
            )

            // visibility와 presence 추가 (있으면)
            if (landmark.visibility().isPresent) {
                landmarkMap["visibility"] = landmark.visibility().get().toDouble()
            }
            if (landmark.presence().isPresent) {
                landmarkMap["presence"] = landmark.presence().get().toDouble()
            }

            landmarks.add(landmarkMap)
        }

        val resultMap = mutableMapOf<String, Any>(
            "landmarks" to landmarks
        )

        // 월드 랜드마크 (실제 3D 좌표, 미터 단위)
        if (result.worldLandmarks().isNotEmpty()) {
            val worldLandmarksList = result.worldLandmarks()[0]
            val worldLandmarks = mutableListOf<Map<String, Any>>()

            worldLandmarksList.forEachIndexed { index, landmark ->
                val landmarkMap = mutableMapOf<String, Any>(
                    "index" to index,
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z()
                )

                if (landmark.visibility().isPresent) {
                    landmarkMap["visibility"] = landmark.visibility().get().toDouble()
                }
                if (landmark.presence().isPresent) {
                    landmarkMap["presence"] = landmark.presence().get().toDouble()
                }

                worldLandmarks.add(landmarkMap)
            }

            resultMap["worldLandmarks"] = worldLandmarks
        }

        return resultMap
    }

    /**
     * 리소스 해제
     */
    fun close() {
        poseLandmarker?.close()
        poseLandmarker = null
    }
}
