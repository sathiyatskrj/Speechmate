import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'pronunciation_scorer.dart';

class WhisperService {
  bool _isProcessing = false;
  bool _isAvailable = false;
  Whisper? _whisper;

  /// Check if the service is ready
  bool get isAvailable => _isAvailable;
  bool get isProcessing => _isProcessing;

  /// Initialize the service by ensuring the model is extracted
  Future<bool> initialize({int retryCount = 2}) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final Directory dir = Platform.isAndroid
            ? await getApplicationSupportDirectory()
            : await getLibraryDirectory();
            
        final String modelPath = '${dir.path}/ggml-tiny.bin';
        final File modelFile = File(modelPath);

        // Extract model from assets if it doesn't exist
        if (!modelFile.existsSync()) {
          debugPrint('[WhisperService] Extracting model (attempt ${attempt + 1})...');
          final ByteData data = await rootBundle.load('assets/models/ggml-tiny.en.bin');
          final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await modelFile.writeAsBytes(bytes);
        } else {
          debugPrint('[WhisperService] Local model found at $modelPath');
        }

        _whisper = Whisper(
          model: WhisperModel.tiny,
        );

        _isAvailable = true;
        debugPrint('[WhisperService] Initialized successfully.');
        return true;
      } catch (e) {
        debugPrint('[WhisperService] Init attempt ${attempt + 1} failed: $e');
        if (attempt == retryCount) {
          _isAvailable = false;
          return false;
        }
        // Wait before retry
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return false;
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
        language: "en",
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
