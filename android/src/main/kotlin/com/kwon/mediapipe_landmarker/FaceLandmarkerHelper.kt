package com.kwon.mediapipe_landmarker

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult

/**
 * Face Landmarker Helper
 * MediaPipe Face Landmarker 래퍼 클래스
 *
 * 478개 얼굴 랜드마크 + 52개 블렌드쉐입 + Transformation Matrix 지원
 */
class FaceLandmarkerHelper(
    private val context: Context,
    private val numFaces: Int = 1,
    private val minDetectionConfidence: Float = 0.5f,
    private val minTrackingConfidence: Float = 0.5f,
    private val outputBlendshapes: Boolean = true,
    private val outputTransformationMatrix: Boolean = false,
    private val runningMode: RunningMode = RunningMode.IMAGE
) {
    private var faceLandmarker: FaceLandmarker? = null

    companion object {
        private const val MODEL_FACE_LANDMARKER = "face_landmarker.task"
    }

    init {
        setupFaceLandmarker()
    }

    private fun setupFaceLandmarker() {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(MODEL_FACE_LANDMARKER)
                .setDelegate(Delegate.CPU)
                .build()

            val options = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setRunningMode(runningMode)
                .setNumFaces(numFaces)
                .setMinFaceDetectionConfidence(minDetectionConfidence)
                .setMinTrackingConfidence(minTrackingConfidence)
                .setMinFacePresenceConfidence(minDetectionConfidence)
                .setOutputFaceBlendshapes(outputBlendshapes)
                .setOutputFacialTransformationMatrixes(outputTransformationMatrix)
                .build()

            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            throw RuntimeException("Failed to initialize Face Landmarker: ${e.message}", e)
        }
    }

    /**
     * 이미지에서 얼굴 감지
     * @param bitmap 입력 이미지
     * @param timestampMs 타임스탬프 (밀리초)
     * @return 감지 결과 Map (Flutter로 전송용)
     */
    fun detect(bitmap: Bitmap, timestampMs: Long): Map<String, Any>? {
        val landmarker = faceLandmarker ?: return null

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
     * FaceLandmarkerResult를 Flutter 전송용 Map으로 변환
     */
    private fun convertResultToMap(result: FaceLandmarkerResult): Map<String, Any>? {
        if (result.faceLandmarks().isEmpty()) {
            return null
        }

        // 첫 번째 얼굴만 처리 (numFaces=1 기준)
        val faceLandmarks = result.faceLandmarks()[0]

        // 랜드마크 변환
        val landmarks = mutableListOf<Map<String, Any>>()
        faceLandmarks.forEachIndexed { index, landmark ->
            landmarks.add(
                mapOf(
                    "index" to index,
                    "x" to landmark.x(),
                    "y" to landmark.y(),
                    "z" to landmark.z()
                )
            )
        }

        // 블렌드쉐입 변환
        val blendshapes = mutableMapOf<String, Double>()
        if (outputBlendshapes && result.faceBlendshapes().isPresent && result.faceBlendshapes().get().isNotEmpty()) {
            val faceBlendshapes = result.faceBlendshapes().get()[0]
            faceBlendshapes.forEach { category ->
                blendshapes[category.categoryName()] = category.score().toDouble()
            }
        }

        // Transformation Matrix 변환
        var transformationMatrix: List<Double>? = null
        if (outputTransformationMatrix && result.facialTransformationMatrixes().isPresent && 
            result.facialTransformationMatrixes().get().isNotEmpty()) {
            val matrix = result.facialTransformationMatrixes().get()[0]
            val matrixList = mutableListOf<Double>()
            for (row in 0 until matrix.numRows) {
                for (col in 0 until matrix.numColumns) {
                    matrixList.add(matrix[row, col].toDouble())
                }
            }
            transformationMatrix = matrixList
        }

        val resultMap = mutableMapOf<String, Any>(
            "landmarks" to landmarks,
            "blendshapes" to blendshapes
        )

        if (transformationMatrix != null) {
            resultMap["transformationMatrix"] = transformationMatrix
        }

        return resultMap
    }

    /**
     * 리소스 해제
     */
    fun close() {
        faceLandmarker?.close()
        faceLandmarker = null
    }
}
