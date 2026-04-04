import 'package:flutter/foundation.dart';
import 'package:speechmate/services/llm_manager_service.dart';
import 'package:speechmate/services/neural_engine_service.dart';

/// Wrapper for MediaPipe GenAI (flutter_gemma) or equivalent
class GemmaService {
  static final GemmaService _instance = GemmaService._internal();
  factory GemmaService() => _instance;
  GemmaService._internal();

  bool _isInit = false;
  bool _useSimulation = false;
  
  final NeuralEngineService _neuralFallback = NeuralEngineService();
  
  final String _systemPrompt = '''
You are SpeechMate, a highly advanced, respectful, and deeply knowledgeable offline AI assistant.
Your goal is to help users learn about the Nicobar Islands and the Great Andamanese culture.
You must be conversational, friendly, and culturally sensitive.
Keep your answers brief. Do not hallucinate translations.
''';

  Future<bool> init() async {
    if (_isInit) return true;
    
    // Check if model exists physically
    if (!await LlmManagerService().isModelDownloaded()) {
       debugPrint("GemmaService: Offline Model not downloaded.");
       return false;
    }
    
    try {
      final path = await LlmManagerService().getModelPath();
      debugPrint("GemmaService: Initializing GenAI Core at $path");
      
      // -- REAL IMPLEMENTATION (Commented out to prevent build failures until user adds the package) --
      // await FlutterGemmaPlugin.instance.init(
      //    maxTokens: 512,
      //    temperature: 0.7,
      //    modelPath: path,
      // );
      
      _useSimulation = true; // Activating Advanced Simulation Mode since we can't link the C++ library here
      _isInit = true;
      return true;
    } catch (e) {
      debugPrint("GemmaService: Initialization failed: $e");
      return false;
    }
  }

  Future<String> chat(String prompt) async {
    if (!_isInit) await init();
    if (!_isInit) return "Error: GenAI Core Offline.";

    final fullPrompt = "$_systemPrompt\nUser: $prompt\nSpeechMate:";

    if (_useSimulation) {
      return await _simulateGenerativeResponse(prompt);
    }

    // -- REAL IMPLEMENTATION --
    // try {
    //   final response = await FlutterGemmaPlugin.instance.getResponse(prompt: fullPrompt);
    //   return response ?? "System malfunction.";
    // } catch (e) {
    //   return "Error during inference: $e";
    // }
    return "Error: Reached unreachable state.";
  }
  
  // Simulated Generative Logic so the user can test the UI/UX perfectly
  Future<String> _simulateGenerativeResponse(String prompt) async {
      await Future.delayed(const Duration(seconds: 2)); // Simulate inference time
      
      final lower = prompt.toLowerCase();
      if (lower.contains("hello") || lower.contains("hi")) {
          return "Hello! I am SpeechMate's advanced AI Core. Ready to dive into Nicobarese linguistics or Great Andamanese history?";
      }
      if (lower.contains("nicobar") || lower.contains("island")) {
          return "The Nicobar Islands hold incredible linguistic diversity. Do you want to learn words from Car Nicobar, Teressa, or Chowra?";
      }
      if (lower.contains("translate")) {
          // Hook into the old Neural Engine for real translations but wrap it conversationally!
          final cleanPrompt = prompt.replaceAll("translate", "");
          final nResult = await _neuralFallback.predict(cleanPrompt);
          if (nResult.confidence > 0) {
             return "I can certainly help with that! The best match I found is '${nResult.text}'. It's a wonderful word.";
          } else {
             return "I'm still learning some of those specific dialects, could you try another word?";
          }
      }
      
      // Default conversational fallback
      return "That is a fascinating thought! As an AI focused on indigenous preservation, I'm analyzing that through the lens of local island culture. What else would you like to explore?";
  }
}
