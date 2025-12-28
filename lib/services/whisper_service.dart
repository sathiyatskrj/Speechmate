import 'package:flutter/services.dart';

class WhisperService {
  static const _channel = MethodChannel('speechmate/whisper');
  bool _isProcessing = false;

  Future<String> transcribe(String modelPath, String audioPath) async {
    if (_isProcessing) {
      debugPrint("Whisper: Already processing a request. Ignored.");
      return "";
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
