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
  // ═══ SINGLETON ═══
  // Prevents multiple native Whisper engines from being created,
  // which causes crashes after 2-3 uses of voice features.
  static final WhisperService _instance = WhisperService._internal();
  factory WhisperService() => _instance;
  WhisperService._internal();

  bool _isProcessing = false;
  bool _isAvailable = false;
  Whisper? _whisper;
  WhisperModelSize _currentSize = WhisperModelSize.base;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 2;
  DateTime? _lastTranscribeTime;
  static const Duration _engineCooldown = Duration(milliseconds: 300);
  bool _isInitializing = false;
  final List<String> _tempAudioFiles = [];
  
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

  /// Initialize the service. Safe to call multiple times.
  Future<bool> initialize({int retryCount = 2}) async {
    if (_isAvailable && _whisper != null) return true;

    if (_isInitializing) {
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!_isInitializing) return _isAvailable;
      }
      return _isAvailable;
    }

    _isInitializing = true;
    try {
      for (int attempt = 0; attempt <= retryCount; attempt++) {
        try {
          final Directory dir = await getApplicationSupportDirectory();
          
          bool extracted = await _tryExtractModel(dir, _currentSize);
          
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
          _consecutiveFailures = 0;
          debugPrint('[WhisperService] Initialized with $_currentSize model.');
          return true;
        } catch (e) {
          debugPrint('[WhisperService] Init failed (attempt ${attempt + 1}): $e');
          if (attempt == retryCount) return false;
          await Future.delayed(const Duration(seconds: 1));
        }
      }
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Try to extract a model from assets
  Future<bool> _tryExtractModel(Directory dir, WhisperModelSize size) async {
    final String modelName = _modelFiles[size]!;
    final String modelPath = '${dir.path}/$modelName';
    final File modelFile = File(modelPath);

    if (modelFile.existsSync() && modelFile.lengthSync() > 1000) {
      return true;
    }

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

    final String fallbackName = _modelFilesFallback[size]!;
    try {
      final String assetPath = 'assets/models/$fallbackName';
      final ByteData data = await rootBundle.load(assetPath);
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await modelFile.writeAsBytes(bytes);
      debugPrint('[WhisperService] Extracted $fallbackName as $modelName (English-only fallback).');
      return true;
    } catch (e) { debugPrint("Silent error caught: $e");
      debugPrint('[WhisperService] $fallbackName also not found.');
    }

    return false;
  }

  /// Switch to a different model size
  Future<void> downloadAndSwitchModel(WhisperModelSize newSize) async {
    debugPrint('[WhisperService] Switching to $newSize model (bundled for now)...');
    _currentSize = newSize;
    _whisper = null;
    _isAvailable = false;
    await initialize();
  }

  WhisperModel _getFlutterModel(WhisperModelSize size) {
    switch (size) {
      case WhisperModelSize.tiny: return WhisperModel.tiny;
      case WhisperModelSize.base: return WhisperModel.base;
      case WhisperModelSize.small: return WhisperModel.small;
    }
  }

  /// Force-reset the Whisper engine
  Future<void> reset() async {
    debugPrint('[WhisperService] Resetting engine...');
    _isProcessing = false;
    _consecutiveFailures = 0;
    _whisper = null;
    _isAvailable = false;
    await _cleanupTempFiles();
    await initialize();
  }

  Future<void> _cleanupTempFiles() async {
    for (final path in _tempAudioFiles) {
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (e) {
        debugPrint('[WhisperService] Cleanup error: $e');
      }
    }
    _tempAudioFiles.clear();
  }

  void trackTempFile(String path) {
    _tempAudioFiles.add(path);
    if (_tempAudioFiles.length > 10) _cleanupOldFiles();
  }

  Future<void> _cleanupOldFiles() async {
    while (_tempAudioFiles.length > 3) {
      final path = _tempAudioFiles.removeAt(0);
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  bool _isValidAudioFile(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      if (file.lengthSync() < 1024) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Transcribe a WAV audio file using the local Whisper model.
  Future<String> transcribe(String audioFilePath) async {
    if (!_isValidAudioFile(audioFilePath)) return '';
    
    if (!_isAvailable || _whisper == null) {
      debugPrint('[WhisperService] Cannot transcribe - service unavailable. Attempting re-init...');
      await initialize();
      if (!_isAvailable) return '';
    }

    // Engine cooldown
    if (_lastTranscribeTime != null) {
      final elapsed = DateTime.now().difference(_lastTranscribeTime!);
      if (elapsed < _engineCooldown) {
        await Future.delayed(_engineCooldown - elapsed);
      }
    }

    if (_isProcessing) {
      debugPrint('[WhisperService] Already processing — skipping duplicate call.');
      return '';
    }

    _isProcessing = true;
    try {
      trackTempFile(audioFilePath);

      // CRITICAL: speedUp must be FALSE — it causes audio aliasing
      // that produces gibberish on base model after 2-3 uses
      final TranscribeRequest request = TranscribeRequest(
        audio: audioFilePath,
        language: "en",
        isTranslate: false,
        speedUp: false,
        isNoTimestamps: true,
        threads: !Platform.isIOS ? 4 : 2,
      );

      final response = await _whisper!.transcribe(transcribeRequest: request)
          .timeout(const Duration(seconds: 30));
      
      _lastTranscribeTime = DateTime.now();
      _consecutiveFailures = 0;
      
      final text = response.text.trim();
      debugPrint('[WhisperService] Transcribed: "${text.length > 80 ? text.substring(0, 80) : text}"');
      return text;
    } catch (e) {
      debugPrint('[WhisperService] Transcribe error: $e');
      _consecutiveFailures++;
      _lastTranscribeTime = DateTime.now();
      
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        debugPrint('[WhisperService] $_consecutiveFailures failures — rebuilding engine...');
        _whisper = null;
        _isAvailable = false;
        _consecutiveFailures = 0;
        await Future.delayed(const Duration(milliseconds: 300));
        await initialize();
      }
      return '';
    } finally {
      _isProcessing = false;
    }
  }

  /// Transcribe audio and score pronunciation against expected text
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
