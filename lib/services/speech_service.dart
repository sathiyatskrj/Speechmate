import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  
  // Singleton pattern
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  /// Initialize the speech engine. Returns true if successful.
  Future<bool> init() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) => print('STT Status: $status'),
      onError: (error) => print('STT Error: $error'),
      debugLogging: true,
    );
    return _isAvailable;
  }

  /// Start listening and stream results callback
  void listen({
    required Function(String text) onResult, 
    String localeId = 'en_US',
  }) {
    if (!_isAvailable) return;

    _speech.listen(
      onResult: (val) {
        onResult(val.recognizedWords);
      },
      localeId: localeId,
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening
  Future<void> stop() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _isAvailable;
}
