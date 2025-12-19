import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _tts.setLanguage("en-US"); // Nicobarese not available, English voice
    _tts.setSpeechRate(0.4);
    _tts.setPitch(1.0);
  }

  /// 🔊 Speak Nicobarese word (fallback TTS)
  Future<void> speakNicobarese(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }
}
