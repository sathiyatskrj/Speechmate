import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Call this once (ex: in initState)
  Future<void> init() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    // Track speaking state
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });
  }

  /// Speak English text
  Future<void> speakEnglish(String text) async {
    await _tts.stop();
    await _tts.setLanguage("en-US");
    await _tts.speak(text);
  }

  /// Speak Nicobarese (fallback voice)
  /// Since Nicobarese has no official TTS voice,
  /// we use a neutral/Indian English fallback.
  Future<void> speakNicobarese(String text) async {
    await _tts.stop();

    // Best practical fallback options:
    // "en-IN", "hi-IN", or "id-ID"
    await _tts.setLanguage("en-IN");

    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Dispose when no longer needed
  void dispose() {
    _tts.stop();
  }
}
