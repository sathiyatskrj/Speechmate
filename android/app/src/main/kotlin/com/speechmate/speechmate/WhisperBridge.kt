package com.speechmate.speechmate

class WhisperBridge {
    companion object {
        init {
            System.loadLibrary("whisper-lib")
        }
    }

    external fun transcribe(
        modelPath: String,
        audioPath: String
    ): String
}
