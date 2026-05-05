import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'pronunciation_scorer.dart';

enum WhisperModelSize {
  tiny,
  base,
  small,
}

class WhisperService {
  bool _isProcessing = false;
  bool _isAvailable = false;
  Whisper? _whisper;
  WhisperModelSize _currentSize = WhisperModelSize.tiny; // Prefer tiny for speed
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 2;
  
  // Model file mapping — multilingual variants (no .en suffix)
  static const Map<WhisperModelSize, String> _modelFiles = {
    WhisperModelSize.tiny: 'ggml-tiny.bin',
    WhisperModelSize.base: 'ggml-base.bin',
    WhisperModelSize.small: 'ggml-small.bin',
  };

  // Fallback: also try .en variants
  static const Map<WhisperModelSize, String> _modelFilesFallback = {
    WhisperModelSize.tiny: 'ggml-tiny.en.bin',
    WhisperModelSize.base: 'ggml-base.en.bin',
    WhisperModelSize.small: 'ggml-small.en.bin',
  };

  /// Check if the service is ready
  bool get isAvailable => _isAvailable;
  bool get isProcessing => _isProcessing;
  WhisperModelSize get currentSize => _currentSize;

  /// Initialize the service by ensuring the default model is extracted.
  /// Tries base first, falls back to tiny if base is not bundled.
  Future<bool> initialize({int retryCount = 2}) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final Directory dir = await getApplicationSupportDirectory();
        
        // Try to extract the preferred model
        bool extracted = await _tryExtractModel(dir, _currentSize);
        
        // If preferred model not found, try fallback sizes
        if (!extracted && _currentSize != WhisperModelSize.tiny) {
          debugPrint('[WhisperService] Base model not bundled, falling back to tiny...');
          _currentSize = WhisperModelSize.tiny;
          extracted = await _tryExtractModel(dir, _currentSize);
        }
        
        if (!extracted) {
          debugPrint('[WhisperService] No whisper model found in assets.');
          _isAvailable = false;
          return false;
        }

        _whisper = Whisper(
          model: _getFlutterModel(_currentSize),
          modelDir: dir.path,
        );

        _isAvailable = true;
        debugPrint('[WhisperService] Initialized with $_currentSize model.');
        return true;
      } catch (e) {
        debugPrint('[WhisperService] Init failed (attempt ${attempt + 1}): $e');
        if (attempt == retryCount) return false;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
  }

  /// Try to extract a model from assets, checking both multilingual and .en variants
  Future<bool> _tryExtractModel(Directory dir, WhisperModelSize size) async {
    // First try multilingual variant
    final String modelName = _modelFiles[size]!;
    final String modelPath = '${dir.path}/$modelName';
    final File modelFile = File(modelPath);

    if (modelFile.existsSync() && modelFile.lengthSync() > 1000) {
      return true; // Already extracted
    }

    // Try extracting multilingual from assets
    try {
      final String assetPath = 'assets/models/$modelName';
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await modelFile.writeAsBytes(bytes);
      debugPrint('[WhisperService] Extracted $modelName from assets (multilingual).');
      return true;
    } catch (e) { debugPrint("Silent error caught: $e");
      debugPrint('[WhisperService] $modelName not found in assets.');
    }

    // Try .en fallback variant
    final String fallbackName = _modelFilesFallback[size]!;
    try {
      final String assetPath = 'assets/models/$fallbackName';
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      // Save as the standard name so Whisper SDK finds it
      await modelFile.writeAsBytes(bytes);
      debugPrint('[WhisperService] Extracted $fallbackName as $modelName (English-only fallback).');
      return true;
    } catch (e) { debugPrint("Silent error caught: $e");
      debugPrint('[WhisperService] $fallbackName also not found.');
    }

    return false;
  }

  /// Switch to a high-fidelity model bundled with the APK
  Future<void> downloadAndSwitchModel(WhisperModelSize newSize) async {
    debugPrint('[WhisperService] Switching to $newSize model (bundled for now)...');
    
    _currentSize = newSize;
    await initialize();
  }

  WhisperModel _getFlutterModel(WhisperModelSize size) {
    switch (size) {
      case WhisperModelSize.tiny: return WhisperModel.tiny;
      case WhisperModelSize.base: return WhisperModel.base;
      case WhisperModelSize.small: return WhisperModel.small;
    }
  }

  /// Force-reset the Whisper engine. Call this if transcription
  /// becomes unreliable after repeated use.
  Future<void> reset() async {
    debugPrint('[WhisperService] Resetting engine...');
    _isProcessing = false;
    _consecutiveFailures = 0;
    _whisper = null;
    _isAvailable = false;
    await initialize();
  }

  /// Transcribe a WAV audio file using the local Whisper model.
  Future<String> transcribe(String audioFilePath) async {
    if (!_isAvailable || _whisper == null) {
      debugPrint('[WhisperService] Cannot transcribe - service unavailable. Attempting re-init...');
      await initialize();
      if (!_isAvailable) return '';
    }

    if (_isProcessing) {
      debugPrint('[WhisperService] Already processing — forcing unlock after 30s stale lock.');
      // Safety valve: if a previous call got stuck, force-unlock after a reasonable time
      _isProcessing = false;
    }

    _isProcessing = true;
    try {
      final TranscribeRequest request = TranscribeRequest(
        audio: audioFilePath,
        language: "auto",
        isTranslate: false,
        speedUp: true,
        isNoTimestamps: true, // Speeds up inference by skipping timestamp generation
        threads: !Platform.isIOS ? 4 : 2,
      );

      final response = await _whisper!.transcribe(transcribeRequest: request)
          .timeout(const Duration(seconds: 30));
      
      _consecutiveFailures = 0; // Success — reset failure counter
      return response.text;
    } catch (e) {
      debugPrint('[WhisperService] Transcribe error: $e');
      _consecutiveFailures++;
      
      // If native engine is corrupted after repeated failures, rebuild it
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        debugPrint('[WhisperService] $_consecutiveFailures consecutive failures — rebuilding engine...');
        _whisper = null;
        _isAvailable = false;
        // Re-init will happen on next call (lazy recovery)
      }
      return '';
    } finally {
      _isProcessing = false;
    }
  }

  /// Transcribe audio and score pronunciation against expected text.
  /// Returns a map with 'text', 'score' (0-100), and 'label'.
  Future<Map<String, dynamic>> transcribeAndScore(
    String audioFilePath,
    String expectedText,
  ) async {
    final transcribed = await transcribe(audioFilePath);
    if (transcribed.isEmpty) {
      return {'text': '', 'score': 0, 'label': 'Could not process audio'};
    }

    final score = PronunciationScorer.score(transcribed, expectedText);
    final label = PronunciationScorer.label(score);

    return {
      'text': transcribed,
      'score': score,
      'label': label,
    };
  }
}
