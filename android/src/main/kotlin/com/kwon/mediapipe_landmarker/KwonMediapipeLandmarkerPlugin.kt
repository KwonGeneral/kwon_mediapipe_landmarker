package com.kwon.mediapipe_landmarker

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import java.nio.ByteBuffer

/** KwonMediapipeLandmarkerPlugin */
class KwonMediapipeLandmarkerPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    private var faceLandmarkerHelper: FaceLandmarkerHelper? = null
    private var poseLandmarkerHelper: PoseLandmarkerHelper? = null

    private var isInitialized = false
    private var faceEnabled = false
    private var poseEnabled = false

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.kwon.mediapipe_landmarker")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.kwon.mediapipe_landmarker/stream")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "detect" -> handleDetect(call, result)
            "startStream" -> handleStartStream(result)
            "stopStream" -> handleStopStream(result)
            "dispose" -> handleDispose(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val ctx = context
        if (ctx == null) {
            result.error("NO_CONTEXT", "Application context is not available", null)
            return
        }

        try {
            faceEnabled = call.argument<Boolean>("enableFace") ?: true
            poseEnabled = call.argument<Boolean>("enablePose") ?: false

            // Face Landmarker 초기화
            if (faceEnabled) {
                val numFaces = call.argument<Int>("faceNumFaces") ?: 1
                val minDetectionConfidence = call.argument<Double>("faceMinDetectionConfidence")?.toFloat() ?: 0.5f
                val minTrackingConfidence = call.argument<Double>("faceMinTrackingConfidence")?.toFloat() ?: 0.5f
                val outputBlendshapes = call.argument<Boolean>("faceOutputBlendshapes") ?: true
                val outputTransformationMatrix = call.argument<Boolean>("faceOutputTransformationMatrix") ?: false

                faceLandmarkerHelper = FaceLandmarkerHelper(
                    context = ctx,
                    numFaces = numFaces,
                    minDetectionConfidence = minDetectionConfidence,
                    minTrackingConfidence = minTrackingConfidence,
                    outputBlendshapes = outputBlendshapes,
                    outputTransformationMatrix = outputTransformationMatrix
                )
            }

            // Pose Landmarker 초기화
            if (poseEnabled) {
                val numPoses = call.argument<Int>("poseNumPoses") ?: 1
                val minDetectionConfidence = call.argument<Double>("poseMinDetectionConfidence")?.toFloat() ?: 0.5f
                val minTrackingConfidence = call.argument<Double>("poseMinTrackingConfidence")?.toFloat() ?: 0.5f

                poseLandmarkerHelper = PoseLandmarkerHelper(
                    context = ctx,
                    numPoses = numPoses,
                    minDetectionConfidence = minDetectionConfidence,
                    minTrackingConfidence = minTrackingConfidence
                )
            }

            isInitialized = true
            result.success(null)
        } catch (e: Exception) {
            result.error("INITIALIZATION_FAILED", e.message, e.stackTraceToString())
        }
    }

    private fun handleDetect(call: MethodCall, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Landmarker is not initialized", null)
            return
        }

        try {
            val bitmap: Bitmap? = when {
                // 이미지 바이트 (JPEG, PNG 등)
                call.argument<ByteArray>("imageBytes") != null -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")!!
                    BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                }
                // 카메라 YUV 프레임
                call.argument<List<ByteArray>>("planes") != null -> {
                    val planes = call.argument<List<ByteArray>>("planes")!!
                    val width = call.argument<Int>("imageWidth") ?: 0
                    val height = call.argument<Int>("imageHeight") ?: 0
                    val rotation = call.argument<Int>("imageRotation") ?: 0
                    val format = call.argument<String>("imageFormat") ?: "yuv420"

                    convertYuvToBitmap(planes, width, height, rotation, format)
                }
                else -> null
            }

            if (bitmap == null) {
                result.error("INVALID_IMAGE", "Could not decode image", null)
                return
            }

            val timestampMs = System.currentTimeMillis()
            val response = hashMapOf<String, Any?>(
                "timestampMs" to timestampMs
            )

            // Face 분석
            if (faceEnabled && faceLandmarkerHelper != null) {
                val faceResult = faceLandmarkerHelper!!.detect(bitmap, timestampMs)
                if (faceResult != null) {
                    response["face"] = faceResult
                }
            }

            // Pose 분석
            if (poseEnabled && poseLandmarkerHelper != null) {
                val poseResult = poseLandmarkerHelper!!.detect(bitmap, timestampMs)
                if (poseResult != null) {
                    response["pose"] = poseResult
                }
            }

            // Bitmap 메모리 해제
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }

            result.success(response)
        } catch (e: Exception) {
            result.error("DETECTION_FAILED", e.message, e.stackTraceToString())
        }
    }

    private fun convertYuvToBitmap(
        planes: List<ByteArray>,
        width: Int,
        height: Int,
        rotation: Int,
        format: String
    ): Bitmap? {
        if (planes.isEmpty() || width == 0 || height == 0) {
            return null
        }

        try {
            val yuvBytes = planes[0]
            val uBytes = if (planes.size > 1) planes[1] else ByteArray(0)
            val vBytes = if (planes.size > 2) planes[2] else ByteArray(0)

            // NV21 형식으로 변환
            val nv21: ByteArray
            when (format.lowercase()) {
                "nv21" -> {
                    nv21 = yuvBytes
                }
                "yuv420", "yuv420p" -> {
                    // YUV420 -> NV21 변환
                    nv21 = ByteArray(width * height * 3 / 2)
                    System.arraycopy(yuvBytes, 0, nv21, 0, width * height)

                    var uvIndex = width * height
                    val uvSize = width * height / 4
                    for (i in 0 until uvSize) {
                        if (i < vBytes.size) nv21[uvIndex++] = vBytes[i]
                        if (i < uBytes.size) nv21[uvIndex++] = uBytes[i]
                    }
                }
                else -> {
                    nv21 = yuvBytes
                }
            }

            // NV21 -> Bitmap 변환
            val yuvImage = android.graphics.YuvImage(
                nv21,
                android.graphics.ImageFormat.NV21,
                width,
                height,
                null
            )

            val out = java.io.ByteArrayOutputStream()
            yuvImage.compressToJpeg(android.graphics.Rect(0, 0, width, height), 90, out)
            val jpegBytes = out.toByteArray()

            var bitmap = BitmapFactory.decodeByteArray(jpegBytes, 0, jpegBytes.size)

            // 회전 적용
            if (rotation != 0 && bitmap != null) {
                val matrix = Matrix()
                matrix.postRotate(rotation.toFloat())
                val rotatedBitmap = Bitmap.createBitmap(
                    bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
                )
                if (rotatedBitmap != bitmap) {
                    bitmap.recycle()
                }
                bitmap = rotatedBitmap
            }

            return bitmap
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun handleStartStream(result: Result) {
        // EventChannel을 통해 스트림 결과 전송
        result.success(null)
    }

    private fun handleStopStream(result: Result) {
        result.success(null)
    }

    private fun handleDispose(result: Result) {
        try {
            faceLandmarkerHelper?.close()
            poseLandmarkerHelper?.close()
            faceLandmarkerHelper = null
            poseLandmarkerHelper = null
            isInitialized = false
            faceEnabled = false
            poseEnabled = false
            result.success(null)
        } catch (e: Exception) {
            result.error("DISPOSE_FAILED", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        faceLandmarkerHelper?.close()
        poseLandmarkerHelper?.close()
        context = null
    }

    // EventChannel.StreamHandler
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // EventSink로 결과 전송 (실시간 스트림용)
    fun sendResultToFlutter(result: Map<String, Any?>) {
        eventSink?.success(result)
    }
}
