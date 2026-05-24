package com.speechmate.edu

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val KEYBOARD_CHANNEL = "com.speechmate.general/keyboard"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSystemKeyboard" -> {
                    try {
                        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Settings intent failed", e.message)
                    }
                }
                "showKeyboardPicker" -> {
                    try {
                        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                        imm.showInputMethodPicker()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Keyboard picker failed", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    companion object {
        init {
            System.loadLibrary("whisper-lib")
        }
    }
}
