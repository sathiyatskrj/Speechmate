import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ModelDownloaderService {
  static const String modelFileName = 'tinyllama-1.1b-chat-q4_k_m.gguf';
  static const String modelUrl = 'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';

  final Dio _dio = Dio();
  
  /// Get the local path where the model should be stored to survive app updates and persist offline
  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$modelFileName';
  }

  /// Check if the model is already downloaded and fully intact
  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      // Basic sanity check: TinyLlama Q4_K_M is around 637 MB
      final length = await file.length();
      if (length > 600 * 1024 * 1024) { 
        return true;
      }
      // If it's too small, it's corrupt. Delete it.
      await file.delete();
    }
    return false;
  }

  /// Download the model with a progress callback
  Future<void> downloadModel(Function(double progress) onProgress) async {
    final path = await getModelPath();
    
    try {
      await _dio.download(
        modelUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            onProgress(progress);
          }
        },
      );
      debugPrint('[ModelDownloaderService] Model downloaded successfully to $path');
    } catch (e) {
      debugPrint('[ModelDownloaderService] Download failed: $e');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }
}
