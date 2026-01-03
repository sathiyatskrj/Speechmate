import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart'; // For rootBundle check (optional, or just try-catch)

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

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
  /// - [text]: The Nicobarese text to speak (used for TTS fallback).
  /// - [englishWord]: (Optional) The English word to look for as an .mp3 file (e.g., "apple" -> "assets/audio/words/apple.mp3").
  Future<void> speakNicobarese(String text, {String? englishWord}) async {
    await stop(); // Stop any current audio

    // 1. Try Custom Audio File if englishWord is provided
    if (englishWord != null && englishWord.isNotEmpty) {
      final String cleanName = englishWord.toLowerCase().trim();
      final String assetPath = 'audio/words/$cleanName.mp3';
      
      try {
        // We can't easily check file existence in assets without loading, 
        // but AudioPlayer throws if not found. Cleanest is try-catch.
        await _audioPlayer.play(AssetSource(assetPath));
        return; // Success! Don't do TTS.
      } catch (e) {
        // File not found or error -> Proceed to TTS Fallback
        // debugPrint("Custom audio not found for $englishWord: $e");
      }
    }

    // 2. Fallback to TTS
    // Best practical fallback options: "en-IN", "hi-IN", or "id-ID"
    await _tts.setLanguage("en-IN");
    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
    _isSpeaking = false;
  }

  /// Dispose when no longer needed
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose(); // Fix memory leak
  }
}
