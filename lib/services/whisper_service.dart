import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ON-DEMAND MODEL DOWNLOAD — For lean APK builds without bundled model
  // ═══════════════════════════════════════════════════════════════════════════

  /// HuggingFace URLs for on-demand Whisper model download.
  /// Used when the model is NOT bundled inside the APK (lean build mode).
  static const Map<WhisperModelSize, String> _modelDownloadUrls = {
    WhisperModelSize.tiny: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
    WhisperModelSize.base: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
    WhisperModelSize.small: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin',
  };

  /// Expected file sizes for integrity verification after download.
  static const Map<WhisperModelSize, int> _modelExpectedMinBytes = {
    WhisperModelSize.tiny: 70 * 1024 * 1024,   // ~75 MB
    WhisperModelSize.base: 130 * 1024 * 1024,  // ~141 MB
    WhisperModelSize.small: 450 * 1024 * 1024, // ~466 MB
  };

  /// Whether the model needs to be downloaded (not bundled in APK).
  bool _needsDownload = false;
  bool get needsModelDownload => _needsDownload;

  /// Download progress (0.0 to 1.0) — observable by UI
  double _downloadProgress = 0.0;
  double get downloadProgress => _downloadProgress;
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  /// Check if the model exists on disk (either extracted from assets or downloaded)
  Future<bool> isModelReady() async {
    final Directory dir = await getApplicationSupportDirectory();
    for (final size in [_currentSize, WhisperModelSize.tiny]) {
      final String modelName = _modelFiles[size]!;
      final File modelFile = File('${dir.path}/$modelName');
      if (modelFile.existsSync() && modelFile.lengthSync() > 1000) {
        return true;
      }
    }
    return false;
  }

  /// Download the Whisper model on-demand.
  /// Call this when the model is not bundled in the APK.
  /// [onProgress] receives values from 0.0 to 1.0.
  Future<bool> downloadModel({
    WhisperModelSize? size,
    Function(double progress)? onProgress,
  }) async {
    final targetSize = size ?? _currentSize;
    final url = _modelDownloadUrls[targetSize];
    if (url == null) return false;

    final Directory dir = await getApplicationSupportDirectory();
    final String modelName = _modelFiles[targetSize]!;
    final String modelPath = '${dir.path}/$modelName';

    // Already downloaded?
    final File existing = File(modelPath);
    if (existing.existsSync() && existing.lengthSync() > (_modelExpectedMinBytes[targetSize] ?? 0)) {
      debugPrint('[WhisperService] Model $modelName already downloaded.');
      _needsDownload = false;
      return true;
    }

    _isDownloading = true;
    _downloadProgress = 0.0;

    try {
      final dio = Dio();
      await dio.download(
        url,
        modelPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress = received / total;
            onProgress?.call(_downloadProgress);
          }
        },
      );

      // Verify download integrity
      final downloaded = File(modelPath);
      final minExpected = _modelExpectedMinBytes[targetSize] ?? 0;
      if (!downloaded.existsSync() || downloaded.lengthSync() < minExpected) {
        debugPrint('[WhisperService] Downloaded model is too small — corrupt. Deleting.');
        if (downloaded.existsSync()) await downloaded.delete();
        return false;
      }

      // Mark as downloaded
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('whisper_model_downloaded', true);
      await prefs.setString('whisper_model_size', targetSize.name);

      _needsDownload = false;
      _currentSize = targetSize;
      debugPrint('[WhisperService] Model $modelName downloaded successfully (${downloaded.lengthSync() ~/ (1024 * 1024)} MB).');
      return true;
    } catch (e) {
      debugPrint('[WhisperService] Model download failed: $e');
      // Clean up partial download
      final partial = File(modelPath);
      if (partial.existsSync()) await partial.delete();
      return false;
    } finally {
      _isDownloading = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOISE FILTERING & GIBBERISH DETECTION CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Minimum RMS energy threshold for audio to be considered speech.
  /// Audio below this is likely silence or very faint background noise.
  /// WAV 16-bit samples range from -32768 to 32767.
  static const double _minRmsThreshold = 300.0;

  /// Maximum RMS energy — if audio exceeds this, the mic is clipping or
  /// there's extreme environmental noise (construction, wind, etc.)
  static const double _maxRmsThreshold = 28000.0;

  /// Minimum percentage of audio frames that must exceed the silence threshold
  /// to be considered actual speech (Voice Activity Detection).
  /// Prevents sending pure silence with a single spike to Whisper.
  static const double _minSpeechFrameRatio = 0.08;

  /// Known Whisper hallucination patterns that appear when processing
  /// noise-only audio. These are well-documented false positives.
  static const List<String> _hallucinationPatterns = [
    'thank you',
    'thanks for watching',
    'subscribe',
    'like and subscribe',
    'please subscribe',
    'thank you for watching',
    'thanks for listening',
    'you',
    'the end',
    'bye',
    'goodbye',
    'see you',
    'music',
    '[music]',
    '(music)',
    'applause',
    '[applause]',
    'silence',
    '[silence]',
    'blank audio',
    'so',
    'okay',
    'uh',
    'um',
    'hmm',
    'huh',
    'ah',
  ];

  /// Regex patterns for repetitive gibberish that Whisper produces
  /// when processing ambient noise (e.g., "the the the the the")
  static final RegExp _repetitivePattern = RegExp(
    r'\b(\w+)\s+(\1\s+){2,}',
    caseSensitive: false,
  );

  /// Minimum word count for a transcription to be considered valid speech.
  /// Single-word outputs from Whisper on noise are almost always hallucinations.
  static const int _minWordCount = 2;

  /// Check if the service is ready
  bool get isAvailable => _isAvailable;
  bool get isProcessing => _isProcessing;
  WhisperModelSize get currentSize => _currentSize;

  /// Initialize the service by ensuring the default model is extracted.
  /// Tries: 1) bundled asset extraction, 2) previously downloaded model,
  /// 3) marks as needing download (for lean APK builds).
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
          
          // Strategy 1: Try to extract model from bundled assets
          bool extracted = await _tryExtractModel(dir, _currentSize);
          
          // If preferred model not found, try fallback sizes
          if (!extracted && _currentSize != WhisperModelSize.tiny) {
            debugPrint('[WhisperService] Base model not bundled, falling back to tiny...');
            _currentSize = WhisperModelSize.tiny;
            extracted = await _tryExtractModel(dir, _currentSize);
          }
          
          // Strategy 2: Check if model was previously downloaded (lean APK mode)
          if (!extracted) {
            for (final size in [WhisperModelSize.base, WhisperModelSize.tiny]) {
              final String modelName = _modelFiles[size]!;
              final File modelFile = File('${dir.path}/$modelName');
              if (modelFile.existsSync() && modelFile.lengthSync() > 1000) {
                debugPrint('[WhisperService] Found previously downloaded $modelName.');
                _currentSize = size;
                extracted = true;
                break;
              }
            }
          }

          // Strategy 3: No model available — mark as needing download
          if (!extracted) {
            debugPrint('[WhisperService] No whisper model found — download required.');
            _needsDownload = true;
            _isAvailable = false;
            return false;
          }

          _whisper = Whisper(
            model: _getFlutterModel(_currentSize),
            modelDir: dir.path,
          );

          _isAvailable = true;
          _needsDownload = false;
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

  // ═══════════════════════════════════════════════════════════════════════════
  // NOISE FILTERING — Audio Energy Analysis (VAD)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Analyzes a 16-bit PCM WAV file to determine if it contains
  /// actual speech or just background noise/silence.
  ///
  /// Returns a [_AudioAnalysis] with:
  /// - rmsEnergy: Root-mean-square energy of the audio
  /// - peakAmplitude: Maximum sample value
  /// - speechFrameRatio: % of frames above the silence threshold
  /// - verdict: 'speech', 'silence', 'noise', or 'clipping'
  _AudioAnalysis _analyzeAudioEnergy(String audioFilePath) {
    try {
      final file = File(audioFilePath);
      final bytes = file.readAsBytesSync();
      
      // Skip WAV header (44 bytes for standard PCM WAV)
      if (bytes.length < 100) {
        return _AudioAnalysis(rmsEnergy: 0, peakAmplitude: 0, speechFrameRatio: 0, verdict: 'silence');
      }
      
      final data = ByteData.sublistView(Uint8List.fromList(bytes), 44);
      final int sampleCount = data.lengthInBytes ~/ 2; // 16-bit = 2 bytes per sample
      
      if (sampleCount < 100) {
        return _AudioAnalysis(rmsEnergy: 0, peakAmplitude: 0, speechFrameRatio: 0, verdict: 'silence');
      }
      
      double sumSquares = 0;
      int peakAmp = 0;
      int speechFrames = 0;
      
      // Frame-based analysis: analyze in 20ms chunks (320 samples at 16kHz)
      const int frameSize = 320;
      int frameCount = 0;
      
      for (int i = 0; i < sampleCount; i++) {
        try {
          final int sample = data.getInt16(i * 2, Endian.little);
          final int absSample = sample.abs();
          sumSquares += sample * sample;
          if (absSample > peakAmp) peakAmp = absSample;
          
          // Count speech frames
          if (i % frameSize == 0 && i + frameSize < sampleCount) {
            double frameEnergy = 0;
            for (int j = 0; j < frameSize && (i + j) < sampleCount; j++) {
              final int s = data.getInt16((i + j) * 2, Endian.little);
              frameEnergy += s * s;
            }
            frameEnergy = math.sqrt(frameEnergy / frameSize);
            if (frameEnergy > _minRmsThreshold) speechFrames++;
            frameCount++;
          }
        } catch (_) {
          break;
        }
      }
      
      final double rms = math.sqrt(sumSquares / sampleCount);
      final double speechRatio = frameCount > 0 ? speechFrames / frameCount : 0;
      
      // Determine verdict
      String verdict;
      if (rms < _minRmsThreshold) {
        verdict = 'silence';
      } else if (rms > _maxRmsThreshold || peakAmp > 32000) {
        verdict = 'clipping';
      } else if (speechRatio < _minSpeechFrameRatio) {
        verdict = 'noise'; // Energy present but no speech-like frames
      } else {
        verdict = 'speech';
      }
      
      debugPrint('[WhisperService] Audio analysis: RMS=${rms.toStringAsFixed(1)}, '
          'Peak=$peakAmp, SpeechRatio=${(speechRatio * 100).toStringAsFixed(1)}%, '
          'Verdict=$verdict');
      
      return _AudioAnalysis(
        rmsEnergy: rms,
        peakAmplitude: peakAmp.toDouble(),
        speechFrameRatio: speechRatio,
        verdict: verdict,
      );
    } catch (e) {
      debugPrint('[WhisperService] Audio analysis error: $e');
      // On error, allow transcription to proceed (fail-open)
      return _AudioAnalysis(rmsEnergy: 500, peakAmplitude: 5000, speechFrameRatio: 0.5, verdict: 'speech');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GIBBERISH DETECTION — Post-processing filter
  // ═══════════════════════════════════════════════════════════════════════════

  /// Checks if Whisper output is a known hallucination or gibberish.
  /// Returns true if the text should be REJECTED.
  bool _isGibberish(String text) {
    final cleaned = text.trim().toLowerCase();
    
    // Empty or whitespace-only
    if (cleaned.isEmpty) return true;
    
    // Too short — single-word outputs on noise are hallucinations
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length < _minWordCount) {
      // Exception: allow single words that are at least 4 characters
      // (genuine single-word responses like "hello" are rare but valid)
      if (words.length == 1 && words[0].length < 4) {
        debugPrint('[WhisperService] Rejected single short word: "$cleaned"');
        return true;
      }
    }
    
    // Check against known hallucination patterns
    for (final pattern in _hallucinationPatterns) {
      if (cleaned == pattern || cleaned == '[$pattern]' || cleaned == '($pattern)') {
        debugPrint('[WhisperService] Rejected hallucination: "$cleaned"');
        return true;
      }
    }
    
    // Check for repetitive gibberish (e.g., "the the the the")
    if (_repetitivePattern.hasMatch(cleaned)) {
      debugPrint('[WhisperService] Rejected repetitive gibberish: "$cleaned"');
      return true;
    }
    
    // Check for excessive special characters (Whisper artifacts)
    final alphaCount = cleaned.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (cleaned.length > 5 && alphaCount / cleaned.length < 0.3) {
      debugPrint('[WhisperService] Rejected non-alpha content: "$cleaned"');
      return true;
    }
    
    // Check for text that is ONLY punctuation/brackets
    final onlyPunctuation = RegExp(r'^[\[\]\(\)\{\}\.\,\!\?\-\s]+$');
    if (onlyPunctuation.hasMatch(cleaned)) {
      debugPrint('[WhisperService] Rejected punctuation-only: "$cleaned"');
      return true;
    }
    
    return false;
  }

  /// Clean up common Whisper artifacts from transcription output
  String _cleanTranscription(String text) {
    String cleaned = text.trim();
    
    // Remove leading/trailing punctuation artifacts
    cleaned = cleaned.replaceAll(RegExp(r'^\[.*?\]\s*'), ''); // [Music], [Silence], etc.
    cleaned = cleaned.replaceAll(RegExp(r'\s*\[.*?\]$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\(.*?\)\s*'), ''); // (Music), etc.
    cleaned = cleaned.replaceAll(RegExp(r'\s*\(.*?\)$'), '');
    
    // Remove leading/trailing periods and commas
    cleaned = cleaned.replaceAll(RegExp(r'^[\.\,\s]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\.\,\s]+$'), '');
    
    // Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    return cleaned.trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRANSCRIPTION — Main entry point with noise filtering
  // ═══════════════════════════════════════════════════════════════════════════

  /// Transcribe a WAV audio file using the local Whisper model.
  /// 
  /// **v2 Improvements:**
  /// - Pre-transcription audio energy analysis (VAD) to skip silence/noise
  /// - Post-transcription gibberish detection to filter Whisper hallucinations
  /// - Cleaned output with artifact removal
  /// - Optimized for speed with tight timeouts and thread tuning
  Future<String> transcribe(String audioFilePath) async {
    // Pre-flight: validate the audio file
    if (!_isValidAudioFile(audioFilePath)) {
      return '';
    }

    // ── NOISE FILTER STEP 1: Audio energy analysis (VAD) ──
    // Analyze the raw PCM data before sending to Whisper.
    // This prevents wasting 5-15s of Whisper inference on silence/noise.
    final analysis = _analyzeAudioEnergy(audioFilePath);
    
    if (analysis.verdict == 'silence') {
      debugPrint('[WhisperService] ⏭️ Skipping transcription — audio is silence '
          '(RMS: ${analysis.rmsEnergy.toStringAsFixed(1)})');
      return '';
    }
    
    if (analysis.verdict == 'clipping') {
      debugPrint('[WhisperService] ⚠️ Audio is clipping/extremely loud — '
          'results may be unreliable');
      // Still attempt transcription but warn
    }
    
    if (analysis.verdict == 'noise') {
      debugPrint('[WhisperService] ⏭️ Skipping transcription — audio is ambient noise '
          'without speech (SpeechRatio: ${(analysis.speechFrameRatio * 100).toStringAsFixed(1)}%)');
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
          .timeout(const Duration(seconds: 25)); // Tighter timeout — base model finishes in 5-15s
      
      _lastTranscribeTime = DateTime.now();
      _consecutiveFailures = 0; // Success — reset failure counter
      
      // ── NOISE FILTER STEP 2: Clean and validate output ──
      final rawText = response.text.trim();
      final cleanedText = _cleanTranscription(rawText);
      
      // ── NOISE FILTER STEP 3: Gibberish detection ──
      if (_isGibberish(cleanedText)) {
        debugPrint('[WhisperService] 🚫 Filtered gibberish output: "$rawText"');
        return '';
      }
      
      debugPrint('[WhisperService] ✅ Transcribed: "${cleanedText.length > 80 ? cleanedText.substring(0, 80) : cleanedText}"');
      return cleanedText;
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

// ═══════════════════════════════════════════════════════════════════════════════
// Audio Analysis Result
// ═══════════════════════════════════════════════════════════════════════════════

class _AudioAnalysis {
  final double rmsEnergy;
  final double peakAmplitude;
  final double speechFrameRatio;
  final String verdict; // 'speech', 'silence', 'noise', 'clipping'
  
  const _AudioAnalysis({
    required this.rmsEnergy,
    required this.peakAmplitude,
    required this.speechFrameRatio,
    required this.verdict,
  });
}
