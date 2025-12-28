package com.speechmate.speechmate

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "speechmate/whisper"

    // Declare the native method
    external fun transcribe(modelPath: String, audioPath: String): String

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "transcribe") {
                val modelPath = call.argument<String>("model")
                val audioPath = call.argument<String>("audio")

                if (modelPath != null && audioPath != null) {
                    val text = transcribe(modelPath, audioPath)
                    result.success(text)
                } else {
                    result.error("INVALID_ARGUMENT", "Model path or audio path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    companion object {
        init {
            System.loadLibrary("whisper-lib")
        }
    }
}
