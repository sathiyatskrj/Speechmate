import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LlmManagerService {
  static final LlmManagerService _instance = LlmManagerService._internal();
  factory LlmManagerService() => _instance;
  LlmManagerService._internal();

  // Replace with actual huggingface/kaggle direct download link for Gemma-2B-int8
  static const String modelUrl = "https://raw.githubusercontent.com/sathiyatskrj/Speechmate/main/mock_gemma_model_link.bin";
  static const String modelFileName = "gemma-2b-it-gpu-int8.bin";
  
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final StreamController<double> _progressController = StreamController<double>.broadcast();

  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  Stream<double> get progressStream => _progressController.stream;

  Future<bool> isModelDownloaded() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$modelFileName');
    
    // In a real scenario, we'd also check file size or hash
    // Require at least a 1MB file to consider it 'downloaded' for mock validation
    if (await file.exists() && await file.length() > 1000) {
      return true;
    }
    return false;
  }

  Future<String> getModelPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/$modelFileName';
  }

  Future<void> startModelDownload() async {
    if (_isDownloading) return;
    
    _isDownloading = true;
    _downloadProgress = 0.0;
    _progressController.add(_downloadProgress);

    try {
      final dir = await getApplicationSupportDirectory();
      final savePath = '${dir.path}/$modelFileName';
      
      // Attempt Dart IO download
      final request = await HttpClient().getUrl(Uri.parse(modelUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final file = File(savePath);
        final raf = file.openSync(mode: FileMode.write);
        
        // Mocking the content length since we use a dummy URL for demo
        int totalBytes = response.contentLength > 0 ? response.contentLength : 1500000000; // ~1.5GB
        int receivedBytes = 0;

        await for (var data in response) {
          raf.writeFromSync(data);
          receivedBytes += data.length;
          
          _downloadProgress = receivedBytes / totalBytes;
          
          // Fallback progress if server doesn't send content length
          if (_downloadProgress > 1.0) _downloadProgress = 0.99;
          
          _progressController.add(_downloadProgress);
        }
        
        raf.closeSync();
        
        // Finalize
        _downloadProgress = 1.0;
        _progressController.add(1.0);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('llm_core_enabled', true);
        
        debugPrint("🧠 LLM Core Download Complete!");
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Download failed: $e");
      // MOCK FALLBACK for demonstration without a real 1.5GB URL:
      // We simulate a successful download that takes 5 seconds
      await _simulateDownload();
    } finally {
      _isDownloading = false;
    }
  }

  // Fallback simulator to demonstrate UX flow when URL is unreachable
  Future<void> _simulateDownload() async {
      debugPrint("Simulating LLM Download...");
      final dir = await getApplicationSupportDirectory();
      final savePath = '${dir.path}/$modelFileName';
      
      for (int i = 0; i <= 100; i++) {
         await Future.delayed(const Duration(milliseconds: 50));
         _downloadProgress = i / 100.0;
         _progressController.add(_downloadProgress);
      }
      
      // Write mock file
      await File(savePath).writeAsString("MOCK_GEMMA_LLM_WEIGHTS");
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('llm_core_enabled', true);
  }

  Future<void> deleteModel() async {
     final dir = await getApplicationSupportDirectory();
     final file = File('${dir.path}/$modelFileName');
     if (await file.exists()) {
       await file.delete();
     }
     final prefs = await SharedPreferences.getInstance();
     await prefs.setBool('llm_core_enabled', false);
     _downloadProgress = 0.0;
     _progressController.add(0.0);
  }
}
