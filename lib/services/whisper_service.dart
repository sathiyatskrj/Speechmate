import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef TranscribeC = Pointer<Utf8> Function(Pointer<Utf8> model, Pointer<Utf8> audio);
typedef TranscribeDart = Pointer<Utf8> Function(Pointer<Utf8> model, Pointer<Utf8> audio);

typedef FreeStringC = Void Function(Pointer<Utf8> str);
typedef FreeStringDart = void Function(Pointer<Utf8> str);

class WhisperService {
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
      final String text = await compute(_transcribeInBackground, {
        'model': modelPath,
        'audio': audioPath,
      });
      
      _isProcessing = false;
      return text;
    } catch (e) {
        _isProcessing = false;
        debugPrint("Whisper Unexpected Error: $e");
        return "Error: $e";
    }
  }

  // Top-level function for compute
  static Future<String> _transcribeInBackground(Map<String, dynamic> params) async {
     final modelStr = params['model'] as String;
     final audioStr = params['audio'] as String;
     
     final dylib = Platform.isAndroid
        ? DynamicLibrary.open('libwhisper-lib.so')
        : DynamicLibrary.process();

     final transcribeFunc = dylib.lookupFunction<TranscribeC, TranscribeDart>('transcribe_ffi');
     final freeFunc = dylib.lookupFunction<FreeStringC, FreeStringDart>('free_ffi_string');

     final modelPtr = modelStr.toNativeUtf8();
     final audioPtr = audioStr.toNativeUtf8();
     
     final resultPtr = transcribeFunc(modelPtr, audioPtr);
     
     final result = resultPtr.toDartString();
     
     freeFunc(resultPtr);
     malloc.free(modelPtr);
     malloc.free(audioPtr);
     
     return result;
  }
}
