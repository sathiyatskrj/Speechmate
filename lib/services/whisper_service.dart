import 'package:flutter/services.dart';

class WhisperService {
  static const _channel = MethodChannel('speechmate/whisper');

  Future<String> transcribe(String modelPath, String audioPath) async {
    try {
      final String text = await _channel.invokeMethod('transcribe', {
        'model': modelPath,
        'audio': audioPath,
      });
      return text;
    } on PlatformException catch (e) {
      print("Whisper Error: ${e.message}");
      return "Error: Could not transcribe.";
    }
  }
}
