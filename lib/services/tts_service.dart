import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isSpeaking = false;
  bool _isInit = false;

  bool get isSpeaking => _isSpeaking;

  /// All known audio subdirectories in assets/audio/
  static const List<String> _audioFolders = [
    'words',
    'phrases',
    'animals',
    'body_parts',
    'colors',
    'family',
    'feelings',
    'magic',
    'nature',
    'numbers',
    'things',
  ];

  /// Call this once (ex: in initState)
  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0); // Normal pitch

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
    } catch (e) {
      debugPrint("[TTS Init Error] $e");
    }
  }

  /// Speak English text
  Future<void> speakEnglish(String text) async {
    await _tts.stop();
    await _tts.setLanguage("en-US");
    await _tts.speak(text);
  }

  /// Speak Regional text
  Future<void> speakRegional(String text, String localeId) async {
    await _tts.stop();
    await _tts.setLanguage(localeId);
    await _tts.speak(text);
  }

  /// Play audio from a specific category and file path.
  /// [category] maps to a subfolder under assets/audio/ (e.g. "phrases", "animals")
  /// [filename] is the mp3 file name (e.g. "good_morning.mp3")
  Future<bool> playFromCategory(String category, String filename) async {
    try {
      final path = 'audio/$category/$filename';
      // Verify asset exists first before passing to audio player
      await rootBundle.load('assets/$path'); 
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path));
      return true;
    } catch (e) {
      debugPrint("Audio play failed for $category/$filename: $e");
      return false;
    }
  }

  /// Speak Nicobarese (with smart audio lookup)
  /// - [text]: The Nicobarese text to speak (used for TTS fallback).
  /// - [englishWord]: (Optional) The English word to look for as an .mp3 file.
  /// - [audioCategory]: (Optional) Specific audio folder to check first.
  /// - [audioFile]: (Optional) Specific audio filename to play.
  Future<void> speakNicobarese(String text, {
    String? englishWord, 
    String? audioCategory,
    String? audioFile,
  }) async {
    await stop(); // Stop any current audio

    // 1. If a specific audio category+file is provided, use that directly
    if (audioCategory != null && audioFile != null && audioFile.isNotEmpty) {
      final success = await playFromCategory(audioCategory, audioFile);
      if (success) return;
    }

    // 2. Try to find audio by english word across all known folders
    if (englishWord != null && englishWord.isNotEmpty) {
      final String cleanName = englishWord.toLowerCase().replaceAll(RegExp(r'[^\w\s]+'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      
      for (final folder in _audioFolders) {
        try {
          final assetPath = 'audio/$folder/$cleanName.mp3';
          await rootBundle.load('assets/$assetPath');
          await _audioPlayer.play(AssetSource(assetPath));
          return; // Success!
        } catch (e) { debugPrint("Silent error caught: $e");
          // Not in this folder, try next
        }
      }

      // Also try root audio/ folder
      try {
        await rootBundle.load('assets/audio/$cleanName.mp3');
        await _audioPlayer.play(AssetSource('audio/$cleanName.mp3'));
        return;
      } catch (e) { debugPrint('Silent error caught: $e'); }
    }

    // 3. Fallback to TTS
    await _tts.setLanguage("en-IN");
    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
    _isSpeaking = false;
  }

  /// Stop without disposing the underlying player (since it's a singleton)
  void dispose() {
    stop();
  }
}
