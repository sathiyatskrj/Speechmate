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
  WhisperModelSize _currentSize = WhisperModelSize.tiny;
  
  // Model mapping
  static const Map<WhisperModelSize, String> _modelFiles = {
    WhisperModelSize.tiny: 'ggml-tiny.bin',
    WhisperModelSize.base: 'ggml-base.bin',
    WhisperModelSize.small: 'ggml-small.bin',
  };

  /// Check if the service is ready
  bool get isAvailable => _isAvailable;
  bool get isProcessing => _isProcessing;
  WhisperModelSize get currentSize => _currentSize;

  /// Initialize the service by ensuring the default model is extracted.
  /// To upgrade to base/small, call [downloadAndSwitchModel].
  Future<bool> initialize({int retryCount = 2}) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final Directory dir = await getApplicationSupportDirectory();
        final String modelName = _modelFiles[_currentSize]!;
        final String modelPath = '${dir.path}/$modelName';
        final File modelFile = File(modelPath);

        // Extract from assets if it doesn't exist
        if (!modelFile.existsSync()) {
          final String assetPath = 'assets/models/ggml-${_currentSize.name}.bin';
          // Note: .en.bin for tiny as per current project spec
          final String actualAsset = _currentSize == WhisperModelSize.tiny ? 'assets/models/ggml-tiny.en.bin' : assetPath;
          
          debugPrint('[WhisperService] Extracting bundled $modelName from $actualAsset...');
          try {
            final ByteData data = await rootBundle.load(actualAsset);
            final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            await modelFile.writeAsBytes(bytes);
          } catch (e) {
            debugPrint('[WhisperService] Bundle extraction failed for $modelName: $e');
            // If it's not bundled, we can't initialize this size for now
            if (_currentSize != WhisperModelSize.tiny) {
               _isAvailable = false;
               return false;
            }
          }
        }

        _whisper = Whisper(
          model: _getFlutterModel(_currentSize),
        );

        _isAvailable = true;
        debugPrint('[WhisperService] Initialized with $_currentSize model.');
        return true;
      } catch (e) {
        debugPrint('[WhisperService] Init failed: $e');
        if (attempt == retryCount) return false;
        await Future.delayed(const Duration(seconds: 1));
      }
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

  /// Transcribe a WAV audio file using the local Whisper model.
  Future<String> transcribe(String audioFilePath) async {
    if (!_isAvailable || _whisper == null) {
      debugPrint('[WhisperService] Cannot transcribe - service unavailable.');
      return '';
    }

    if (_isProcessing) {
      debugPrint('[WhisperService] Already processing a request. Ignored.');
      return '';
    }

    _isProcessing = true;
    try {
      final TranscribeRequest request = TranscribeRequest(
        audio: audioFilePath,
        language: "auto", // Upgrade: Auto-detect language (supports Multilingual models)
        isTranslate: false,
      );

      final response = await _whisper!.transcribe(transcribeRequest: request);
      
      _isProcessing = false;
      return response.text;
    } catch (e) {
      _isProcessing = false;
      debugPrint('[WhisperService] Error: $e');
      return '';
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
