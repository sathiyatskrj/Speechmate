import 'package:flutter/foundation.dart';

/// WhisperService - Offline speech transcription
/// 
/// IMPORTANT: This service requires a native `.so` library (libwhisper-lib.so)
/// to be bundled with the APK. Without it, the app will crash on initialization.
/// 
/// Currently disabled (stubbed) until native library bundling is implemented.
/// To enable, follow these steps:
/// 1. Build the Whisper C++ library for target arch (arm64-v8a, armeabi-v7a)
/// 2. Place .so files in android/app/src/main/jniLibs/<arch>/
/// 3. Remove the stub guards below and uncomment the FFI code
class WhisperService {
  bool _isProcessing = false;
  bool _isAvailable = false;

  /// Check if the native library is available
  bool get isAvailable => _isAvailable;

  /// Try to initialize the service. Returns false if native lib is missing.
  Future<bool> initialize() async {
    // TODO: Implement native library detection
    // For now, always return false since .so isn't bundled
    _isAvailable = false;
    debugPrint('[WhisperService] Native library not bundled. Service unavailable.');
    return false;
  }

  /// Transcribe audio file using Whisper model.
  /// Returns empty string if service is unavailable.
  Future<String> transcribe(String modelPath, String audioPath) async {
    if (!_isAvailable) {
      debugPrint('[WhisperService] Cannot transcribe - service unavailable.');
      return '';
    }

    if (_isProcessing) {
      debugPrint('[WhisperService] Already processing a request. Ignored.');
      return '';
    }

    _isProcessing = true;
    try {
      // FFI call would go here when native library is available
      // final text = await compute(_transcribeInBackground, {...});
      _isProcessing = false;
      return '';
    } catch (e) {
      _isProcessing = false;
      debugPrint('[WhisperService] Error: $e');
      return '';
    }
  }
}
