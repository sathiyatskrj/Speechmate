import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// Typedefs for C++ function signatures
typedef TranscribeFfiC = Pointer<Utf8> Function(Pointer<Utf8> model, Pointer<Utf8> audio);
typedef TranscribeFfiDart = Pointer<Utf8> Function(Pointer<Utf8> model, Pointer<Utf8> audio);

typedef FreeFfiStringC = Void Function(Pointer<Utf8> str);
typedef FreeFfiStringDart = void Function(Pointer<Utf8> str);

typedef BinarizeImageFfiC = Void Function(Pointer<Uint8> imageBytes, Int32 width, Int32 height);
typedef BinarizeImageFfiDart = void Function(Pointer<Uint8> imageBytes, int width, int height);

typedef EncryptPayloadFfiC = Void Function(Pointer<Utf8> data, Pointer<Utf8> key);
typedef EncryptPayloadFfiDart = void Function(Pointer<Utf8> data, Pointer<Utf8> key);

typedef DecryptPayloadFfiC = Void Function(Pointer<Utf8> data, Pointer<Utf8> key);
typedef DecryptPayloadFfiDart = void Function(Pointer<Utf8> data, Pointer<Utf8> key);

typedef FindSimilarWordFfiC = Int32 Function(Pointer<Float> queryVector);
typedef FindSimilarWordFfiDart = int Function(Pointer<Float> queryVector);

/// Bridge Service executing high-performance native operations (C++ via FFI)
/// completely offline for SpeechMate's primary workflows.
class NativeLibraryService {
  static final NativeLibraryService _instance = NativeLibraryService._internal();
  factory NativeLibraryService() => _instance;

  NativeLibraryService._internal() {
    _initDynamicLibrary();
  }

  late DynamicLibrary _dylib;
  bool _dylibAvailable = false;

  // Bindings
  late TranscribeFfiDart _transcribe;
  late FreeFfiStringDart _freeString;
  late BinarizeImageFfiDart _binarizeImage;
  late EncryptPayloadFfiDart _encryptPayload;
  late DecryptPayloadFfiDart _decryptPayload;
  late FindSimilarWordFfiDart _findSimilarWord;

  bool get isAvailable => _dylibAvailable;

  void _initDynamicLibrary() {
    try {
      if (Platform.isAndroid) {
        // Loads the shared library compiled by CMakeLists.txt
        _dylib = DynamicLibrary.open('libwhisper-lib.so');
        _dylibAvailable = true;
      } else if (Platform.isIOS) {
        _dylib = DynamicLibrary.process();
        _dylibAvailable = true;
      } else {
        debugPrint('[NativeLibraryService] Platform not supported for native FFI');
        return;
      }

      // Dynamic library lookup hooks
      _transcribe = _dylib.lookupFunction<TranscribeFfiC, TranscribeFfiDart>('transcribe_ffi');
      _freeString = _dylib.lookupFunction<FreeFfiStringC, FreeFfiStringDart>('free_ffi_string');
      _binarizeImage = _dylib.lookupFunction<BinarizeImageFfiC, BinarizeImageFfiDart>('binarize_image_ffi');
      _encryptPayload = _dylib.lookupFunction<EncryptPayloadFfiC, EncryptPayloadFfiDart>('encrypt_payload_ffi');
      _decryptPayload = _dylib.lookupFunction<DecryptPayloadFfiC, DecryptPayloadFfiDart>('decrypt_payload_ffi');
      _findSimilarWord = _dylib.lookupFunction<FindSimilarWordFfiC, FindSimilarWordFfiDart>('find_similar_word_ffi');

      debugPrint('[NativeLibraryService] Successfully loaded and bound all C++ native functions.');
    } catch (e) {
      debugPrint('[NativeLibraryService] Dynamic Library load failed: $e');
    }
  }

  /// High-performance audio transcription using the direct native FFI bridge
  String transcribeAudio(String modelPath, String audioPath) {
    if (!_dylibAvailable) return 'Error: FFI library not loaded';

    final Pointer<Utf8> modelPtr = modelPath.toNativeUtf8();
    final Pointer<Utf8> audioPtr = audioPath.toNativeUtf8();

    try {
      final Pointer<Utf8> resultPtr = _transcribe(modelPtr, audioPtr);
      final String transcription = resultPtr.toDartString();
      _freeString(resultPtr); // Clean up memory allocated by strdup
      return transcription;
    } catch (e) {
      return 'Error in Native FFI: $e';
    } finally {
      malloc.free(modelPtr);
      malloc.free(audioPtr);
    }
  }

  /// Binarize raw image bytes locally in C++ memory
  Uint8List binarizeGrayscaleImage(Uint8List grayscaleBytes, int width, int height) {
    if (!_dylibAvailable) return grayscaleBytes;

    final Pointer<Uint8> bytesPtr = malloc<Uint8>(grayscaleBytes.length);
    final Uint8List nativeList = bytesPtr.asTypedList(grayscaleBytes.length);
    nativeList.setAll(0, grayscaleBytes);

    try {
      _binarizeImage(bytesPtr, width, height);
      return Uint8List.fromList(nativeList);
    } catch (e) {
      debugPrint('[NativeLibraryService] Binarization FFI error: $e');
      return grayscaleBytes;
    } finally {
      malloc.free(bytesPtr);
    }
  }

  /// Encrypt payload locally
  String encryptSyncPayload(String payload, String key) {
    if (!_dylibAvailable) return payload;

    final Pointer<Utf8> dataPtr = payload.toNativeUtf8();
    final Pointer<Utf8> keyPtr = key.toNativeUtf8();

    try {
      _encryptPayload(dataPtr, keyPtr);
      return dataPtr.toDartString();
    } catch (e) {
      debugPrint('[NativeLibraryService] Encryption FFI error: $e');
      return payload;
    } finally {
      malloc.free(dataPtr);
      malloc.free(keyPtr);
    }
  }

  /// Decrypt payload locally
  String decryptSyncPayload(String payload, String key) {
    if (!_dylibAvailable) return payload;

    final Pointer<Utf8> dataPtr = payload.toNativeUtf8();
    final Pointer<Utf8> keyPtr = key.toNativeUtf8();

    try {
      _decryptPayload(dataPtr, keyPtr);
      return dataPtr.toDartString();
    } catch (e) {
      debugPrint('[NativeLibraryService] Decryption FFI error: $e');
      return payload;
    } finally {
      malloc.free(dataPtr);
      malloc.free(keyPtr);
    }
  }

  /// Cosine semantic search match in C++
  int findClosestSemanticIndex(List<double> queryVector) {
    if (!_dylibAvailable || queryVector.length != 16) return -1;

    final Pointer<Float> vectorPtr = malloc<Float>(16);
    final Float32List nativeList = vectorPtr.asTypedList(16);
    for (int i = 0; i < 16; i++) {
      nativeList[i] = queryVector[i].toDouble();
    }

    try {
      return _findSimilarWord(vectorPtr);
    } catch (e) {
      debugPrint('[NativeLibraryService] Semantic Search FFI error: $e');
      return -1;
    } finally {
      malloc.free(vectorPtr);
    }
  }
}
