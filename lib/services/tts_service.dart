import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speechmate/services/coqui_tts_service.dart';

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

  /// Call this once (ex: in initState).
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;
    try {
      // Ensure engine is ready on Android before setting parameters
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      // Check if a TTS engine is available on this device
      final engines = await _tts.getEngines;
      if (engines is List && engines.isEmpty) {
        debugPrint('[TTS] WARNING: No TTS engine installed on this device.');
      } else {
        debugPrint('[TTS] Engine ready: ${engines is List ? engines.first : engines}');
      }

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

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('[TTS Error] $msg');
      });
    } catch (e) {
      debugPrint("[TTS Init Error] $e");
      // Allow re-init on next call if init failed
      _isInit = false;
    }
  }

  /// Internal helper: ensure init is called before any speak operation.
  Future<void> _ensureInit() async {
    if (!_isInit) await init();
  }

  /// Speak English text with optional custom pitch morphing
  Future<void> speakEnglish(String text, {double? pitch}) async {
    if (text.isEmpty) return;
    await _ensureInit();
    try {
      await _tts.stop();
      await _tts.setLanguage("en-US");
      await _tts.setPitch(pitch ?? 1.0);
      await _tts.setSpeechRate(0.45);
      final result = await _tts.speak(text);
      if (result != 1) {
        debugPrint('[TTS] speakEnglish failed with result: $result for text: "$text"');
      }
    } catch (e) {
      debugPrint('[TTS] speakEnglish error: $e');
    }
  }

  /// Speak Regional text
  Future<void> speakRegional(String text, String localeId) async {
    if (text.isEmpty) return;
    await _ensureInit();
    try {
      await _tts.stop();
      await _tts.setLanguage(localeId);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      final result = await _tts.speak(text);
      if (result != 1) {
        debugPrint('[TTS] speakRegional failed with result: $result for locale: $localeId');
      }
    } catch (e) {
      debugPrint('[TTS] speakRegional error: $e');
    }
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

    // 0. CoquiTTS model (if available) → synthesize and play
    try {
      final coqui = CoquiTtsService();
      if (coqui.isModelAvailable && coqui.canSynthesize(text)) {
        final audioBytes = await coqui.synthesize(text);
        if (audioBytes != null && audioBytes.isNotEmpty) {
          await _audioPlayer.stop();
          await _audioPlayer.play(BytesSource(audioBytes));
          return; // Success!
        }
      }
    } catch (e) {
      debugPrint('[TTS] CoquiTTS synthesis/play failed, falling back: $e');
    }

    // 1. If a specific audio category+file is provided, use that directly
    if (audioCategory != null && audioFile != null && audioFile.isNotEmpty) {
      final success = await playFromCategory(audioCategory, audioFile);
      if (success) return;
    }

    // 2. Try to find audio by english word across all known folders
    if (englishWord != null && englishWord.isNotEmpty) {
      // Fix: raw strings don't need double-escaped backslashes
      final String cleanName = englishWord
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      
      for (final folder in _audioFolders) {
        try {
          final assetPath = 'audio/$folder/$cleanName.mp3';
          await rootBundle.load('assets/$assetPath');
          await _audioPlayer.play(AssetSource(assetPath));
          return; // Success!
        } catch (_) {
          // Not in this folder, try next
        }
      }

      // Also try root audio/ folder
      try {
        await rootBundle.load('assets/audio/$cleanName.mp3');
        await _audioPlayer.play(AssetSource('audio/$cleanName.mp3'));
        return;
      } catch (_) { /* Not found in root either */ }
    }

    // 3. Fallback to TTS engine
    if (text.isEmpty) return;
    await _ensureInit();
    try {
      await _tts.setLanguage("en-IN");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.45);
      final result = await _tts.speak(text);
      if (result != 1) {
        debugPrint('[TTS] speakNicobarese TTS fallback failed with result: $result');
      }
    } catch (e) {
      debugPrint('[TTS] speakNicobarese error: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _tts.stop();
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[TTS] stop error: $e');
    }
    _isSpeaking = false;
  }

  /// Stop without disposing the underlying player (since it's a singleton)
  void dispose() {
    stop();
  }
}
