import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize();
    return _isInitialized;
  }

  Future<String?> listen() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) return null;

    String? recognizedText;
    
    await _speech.listen(
      onResult: (result) {
        recognizedText = result.recognizedWords;
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
    );

    await Future.delayed(const Duration(seconds: 6));
    
    return recognizedText;
  }

  void stop() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
