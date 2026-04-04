import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

class WhisperService {
  bool _isProcessing = false;
  bool _isAvailable = false;
  Whisper? _whisper;

  /// Check if the service is ready
  bool get isAvailable => _isAvailable;

  /// Initialize the service by ensuring the model is extracted
  Future<bool> initialize() async {
    try {
      final Directory dir = Platform.isAndroid
          ? await getApplicationSupportDirectory()
          : await getLibraryDirectory();
          
      final String modelPath = '${dir.path}/ggml-tiny.bin';
      final File modelFile = File(modelPath);

      // Extract model from assets if it doesn't exist
      if (!modelFile.existsSync()) {
        debugPrint('[WhisperService] Extracting model from assets to $modelPath...');
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
      _isAvailable = false;
      debugPrint('[WhisperService] Initialization failed: $e');
      return false;
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
        language: "en", // English model
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
}

