import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class WhisperService {
  static const _channel = MethodChannel('speechmate/whisper');
  bool _isProcessing = false;

  Future<String> transcribe(String modelPath, String audioPath) async {
    if (_isProcessing) {
      debugPrint("Whisper: Already processing a request. Ignored.");
      return "";
    }
    
    // Check files on main isolate before spawning
    if (!await File(modelPath).exists()) {
        return "Error: Model file not found at $modelPath";
    }
    if (!await File(audioPath).exists()) {
        return "Error: Audio file not found at $audioPath";
    }

    _isProcessing = true;
    try {
      // Run native call in background isolate
      final token = RootIsolateToken.instance!;
      final String text = await compute(_transcribeInBackground, {
        'model': modelPath,
        'audio': audioPath,
        'token': token,
      });
      
      _isProcessing = false;
      return text;
    } on PlatformException catch (e) {
      _isProcessing = false;
      debugPrint("Whisper Error: ${e.code} - ${e.message}");
      return "Error: Could not transcribe. Details: ${e.message}";
    } catch (e) {
        _isProcessing = false;
        debugPrint("Whisper Unexpected Error: $e");
        return "Error: $e";
    }
  }

  // Top-level function for compute
  static Future<String> _transcribeInBackground(Map<String, dynamic> params) async {
     BackgroundIsolateBinaryMessenger.ensureInitialized(params['token'] as RootIsolateToken);
     const channel = MethodChannel('speechmate/whisper');
     return await channel.invokeMethod('transcribe', {
        'model': params['model'], 
        'audio': params['audio']
     });
  }
}
