import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class WhisperService {
  static const _channel = MethodChannel('speechmate/whisper');
  bool _isProcessing = false;

  Future<String> transcribe(String modelPath, String audioPath) async {
    if (_isProcessing) {
      debugPrint("Whisper: Already processing a request. Ignored.");
      return "";
    }

    if (!await File(modelPath).exists()) {
        return "Error: Model file not found at $modelPath";
    }
    if (!await File(audioPath).exists()) {
        return "Error: Audio file not found at $audioPath";
    }

    _isProcessing = true;
    try {
      final String text = await _channel.invokeMethod('transcribe', {
        'model': modelPath,
        'audio': audioPath,
      });
      _isProcessing = false;
      return text;
    } on PlatformException catch (e) {
      _isProcessing = false;
      debugPrint("Whisper Error: ${e.code} - ${e.message}");
      return "Error: Could not transcribe. Details: ${e.message}";
    } catch (e) {
        _isProcessing = false;
        debugPrint("Whisper Unexpected Error: $e");
        return "Error: $e";
    }
  }
}
