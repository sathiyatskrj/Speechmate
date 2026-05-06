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
  // which was causing crashes after 1-2 uses of the voice dialog.
  static final WhisperService _instance = WhisperService._internal();
  factory WhisperService() => _instance;
  WhisperService._internal();

  bool _isProcessing = false;
  bool _isAvailable = false;
  Whisper? _whisper;
  WhisperModelSize _currentSize = WhisperModelSize.base; // Prefer base multilingual
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 2; // Rebuild engine faster
  DateTime? _lastTranscribeTime;
  static const Duration _engineCooldown = Duration(milliseconds: 300);
  
  // Track initialization to prevent double-init races
  bool _isInitializing = false;
  
  // Track temp audio files for cleanup
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

  /// Initialize the service by ensuring the default model is extracted.
  /// Tries base first, falls back to tiny if base is not bundled.
  /// Now safe to call multiple times — will skip if already initialized.
  Future<bool> initialize({int retryCount = 2}) async {
    // Already initialized and ready — skip re-init
    if (_isAvailable && _whisper != null) {
      debugPrint('[WhisperService] Already initialized, skipping.');
      return true;
    }

    // Prevent concurrent init calls from racing
    if (_isInitializing) {
      debugPrint('[WhisperService] Init already in progress, waiting...');
      // Wait for existing init to finish (up to 10s)
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
    // Force re-initialization with new model
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

  /// Force-reset the Whisper engine. Call this if transcription
  /// becomes unreliable after repeated use.
  Future<void> reset() async {
    debugPrint('[WhisperService] Resetting engine...');
    _isProcessing = false;
    _consecutiveFailures = 0;
    _whisper = null;
    _isAvailable = false;
    await _cleanupTempFiles();
    await initialize();
  }

  /// Clean up temporary audio files to prevent disk bloat
  Future<void> _cleanupTempFiles() async {
    for (final path in _tempAudioFiles) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
          debugPrint('[WhisperService] Cleaned temp file: $path');
        }
      } catch (e) {
        debugPrint('[WhisperService] Cleanup error: $e');
      }
    }
    _tempAudioFiles.clear();
  }

  /// Register a temp audio file for later cleanup
  void trackTempFile(String path) {
    _tempAudioFiles.add(path);
    // Auto-cleanup if too many files accumulate
    if (_tempAudioFiles.length > 10) {
      _cleanupOldFiles();
    }
  }

  /// Clean files beyond the most recent 3
  Future<void> _cleanupOldFiles() async {
    while (_tempAudioFiles.length > 3) {
      final path = _tempAudioFiles.removeAt(0);
      try {
        final file = File(path);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  /// Validate audio file before sending to Whisper engine.
  /// Returns true if file exists and has sufficient audio data.
  bool _isValidAudioFile(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        debugPrint('[WhisperService] Audio file not found: $path');
        return false;
      }
      final size = file.lengthSync();
      // WAV header is 44 bytes, anything less than 1KB is likely empty/corrupt
      if (size < 1024) {
        debugPrint('[WhisperService] Audio file too small ($size bytes): $path');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[WhisperService] File validation error: $e');
      return false;
    }
  }

  /// Transcribe a WAV audio file using the local Whisper model.
  /// Optimized for speed: uses tiny model-friendly settings,
  /// avoids language detection overhead, and has tight timeouts.
  Future<String> transcribe(String audioFilePath) async {
    // Pre-flight: validate the audio file
    if (!_isValidAudioFile(audioFilePath)) {
      return '';
    }
    
    if (!_isAvailable || _whisper == null) {
      debugPrint('[WhisperService] Cannot transcribe - service unavailable. Attempting re-init...');
      await initialize();
      if (!_isAvailable) return '';
    }

    // Engine cooldown — prevent rapid-fire calls that corrupt native memory
    if (_lastTranscribeTime != null) {
      final elapsed = DateTime.now().difference(_lastTranscribeTime!);
      if (elapsed < _engineCooldown) {
        final waitTime = _engineCooldown - elapsed;
        debugPrint('[WhisperService] Cooldown: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }

    if (_isProcessing) {
      debugPrint('[WhisperService] Already processing — skipping duplicate call.');
      return '';
    }

    _isProcessing = true;
    try {
      // Track file for cleanup
      trackTempFile(audioFilePath);

      // SPEED OPTIMIZATIONS:
      // 1. language: "en" → bypasses slow auto-detection (~2-3s saved)
      // 2. isNoTimestamps: true → skips timestamp generation (~0.5s saved)
      // 3. speedUp: false → CRITICAL: speedUp=true causes audio aliasing
      //    that produces gibberish on base model, leading to empty results
      //    and perceived "crashes" after 2-3 uses
      // 4. threads: 4 on Android → utilizes multi-core for faster inference
      final TranscribeRequest request = TranscribeRequest(
        audio: audioFilePath,
        language: "en", // Bypass expensive language detection for speed
        isTranslate: false,
        speedUp: false, // DO NOT enable — causes quality degradation on base model
        isNoTimestamps: true, // Speeds up inference by skipping timestamp generation
        threads: !Platform.isIOS ? 4 : 2,
      );

      final response = await _whisper!.transcribe(transcribeRequest: request)
          .timeout(const Duration(seconds: 30)); // Tight timeout — base model finishes in 5-15s typically
      
      _lastTranscribeTime = DateTime.now();
      _consecutiveFailures = 0; // Success — reset failure counter
      
      final text = response.text.trim();
      debugPrint('[WhisperService] Transcribed: "${text.length > 80 ? text.substring(0, 80) : text}"');
      return text;
    } catch (e) {
      debugPrint('[WhisperService] Transcribe error: $e');
      _consecutiveFailures++;
      _lastTranscribeTime = DateTime.now();
      
      // If native engine is corrupted after repeated failures, rebuild it
      if (_consecutiveFailures >= _maxConsecutiveFailures) {
        debugPrint('[WhisperService] $_consecutiveFailures consecutive failures — rebuilding engine...');
        _whisper = null;
        _isAvailable = false;
        _consecutiveFailures = 0;
        // Immediately try to re-init for next use
        await Future.delayed(const Duration(milliseconds: 300));
        await initialize();
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
