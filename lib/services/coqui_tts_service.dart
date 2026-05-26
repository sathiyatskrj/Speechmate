import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speechmate/services/native_edge_service.dart';

// ============================================================================
// COQUI TTS SERVICE — On-Device Neural Nicobarese Text-to-Speech
// Uses a custom VITS model trained on Voice Vault native speaker recordings.
// Falls back gracefully on non-Android or when model is unavailable.
// ============================================================================

class CoquiTtsService {
  static final CoquiTtsService _instance = CoquiTtsService._internal();
  factory CoquiTtsService() => _instance;
  CoquiTtsService._internal();

  final NativeEdgeService _native = NativeEdgeService();
  bool _modelLoaded = false;
  static const String modelPath = 'assets/models/nicobarese_tts.bin';

  /// Check if the Coqui TTS model is available on this device
  bool get isModelAvailable => _modelLoaded;

  /// Initialize the TTS model (loads from assets on first call)
  Future<bool> init() async {
    if (_modelLoaded) return true;
    try {
      if (_native.isNativeAvailable) {
        // Load the VITS model via FFI
        _modelLoaded = await _native.coquiTTSLoadModel(modelPath);
        debugPrint('[CoquiTTS] Model loaded: $_modelLoaded');
      } else {
        debugPrint('[CoquiTTS] Native FFI unavailable — Coqui TTS disabled (mock mode).');
        _modelLoaded = false;
      }
    } catch (e) {
      debugPrint('[CoquiTTS] Init error: $e');
      _modelLoaded = false;
    }
    return _modelLoaded;
  }

  /// Synthesize Nicobarese text to raw PCM/WAV audio bytes
  /// Returns null if model is unavailable or synthesis fails.
  Future<Uint8List?> synthesize(String nicobareseText) async {
    if (!_modelLoaded || nicobareseText.isEmpty) return null;
    try {
      final audioBytes = await _native.coquiTTSSynthesize(nicobareseText, modelPath);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        debugPrint('[CoquiTTS] Synthesized ${audioBytes.length} bytes for: "$nicobareseText"');
        return audioBytes;
      }
    } catch (e) {
      debugPrint('[CoquiTTS] Synthesis error: $e');
    }
    return null;
  }

  /// Check if synthesis is supported for a given text
  /// (basic validation: non-empty, reasonable length)
  bool canSynthesize(String text) {
    return _modelLoaded && text.isNotEmpty && text.length < 500;
  }

  /// Release model resources
  void dispose() {
    _modelLoaded = false;
    debugPrint('[CoquiTTS] Model released.');
  }
}
