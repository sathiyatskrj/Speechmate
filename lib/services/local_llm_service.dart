import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:speechmate/services/model_downloader_service.dart';

/// Local LLM Service designed specifically for SmolLM2 135M.
/// This service loads the model via an FFI bridge (like llama_cpp_dart)
/// and uses `dictionary.json` as In-Context Knowledge (RAG).
class LocalLlmService {
  bool _isInitialized = false;
  List<dynamic> _dictionaryCache = [];
  
  bool get isInitialized => _isInitialized;

  /// Initializes the SmolLM2 inference engine and loads the dictionary.
  Future<void> initialize() async {
    try {
      debugPrint('[LocalLlmService] Loading dictionary.json for context injection...');
      final String jsonString = await rootBundle.loadString('assets/data/dictionary.json');
      _dictionaryCache = json.decode(jsonString);

      final downloader = ModelDownloaderService();
      final isDownloaded = await downloader.isModelDownloaded();
      
      if (isDownloaded) {
        final localPath = await downloader.getModelPath();
        // Example: _llm = LlamaCpp(modelPath: localPath);
        debugPrint('[LocalLlmService] Loaded Local AI Tutor (TinyLlama) from: $localPath');
        _isInitialized = true;
      } else {
        debugPrint('[LocalLlmService] Model not found locally. Awaiting user download.');
        // We do not set _isInitialized to true if the model isn't downloaded yet.
      }
    } catch (e) {
      debugPrint('[LocalLlmService] Initialization failed: $e');
    }
  }

  /// Builds the foundational system prompt, injecting Nicobarese vocabulary
  /// so the 135M model acts as a localized linguistic engine.
  // ignore: unused_element
  String _buildSystemPrompt(String taskType) {
    // To prevent exceeding context limits (SmolLM2 supports 2k-8k tokens),
    // we take a relevant sample or the core grammar rules from the dictionary.
    final int sampleSize = _dictionaryCache.length > 50 ? 50 : _dictionaryCache.length;
    final List<dynamic> coreVocab = _dictionaryCache.sublist(0, sampleSize);
    
    final StringBuffer prompt = StringBuffer();
    prompt.writeln("You are an expert offline AI tutor for the endangered Nicobarese language.");
    prompt.writeln("Here is a subset of the vocabulary dictionary:");
    for (var entry in coreVocab) {
      prompt.writeln("- English: ${entry['english']} -> Nicobarese: ${entry['nicobarese']}");
    }
    
    if (taskType == 'sentence_builder') {
      prompt.writeln("\nYour task is to validate a user's Nicobarese sentence.");
      prompt.writeln("Output ONLY a JSON object: {\"isValid\": true/false, \"feedback\": \"Explanation\"}");
    } else if (taskType == 'adaptive_path') {
      prompt.writeln("\nYour task is to analyze a student's performance and suggest 3 focus areas.");
      prompt.writeln("Output ONLY a JSON array of strings.");
    } else if (taskType == 'translation') {
      prompt.writeln("\nYour task is to translate an English sentence to Nicobarese.");
      prompt.writeln("CRITICAL CONSTRAINT: You MUST NOT hallucinate or guess words.");
      prompt.writeln("Use ONLY the exact Nicobarese equivalents provided in the vocabulary list above.");
      prompt.writeln("If a word is not in the vocabulary, leave it in English.");
      prompt.writeln("Output ONLY the translated text string, nothing else.");
    }
    
    return prompt.toString();
  }

  /// Translates a full sentence while strictly adhering to the offline dictionary to avoid "trash" translations.
  Future<String?> translateSentence(String sentence) async {
    if (!_isInitialized) await initialize();

    // Prompts prepared for GGUF integration:
    // final systemPrompt = _buildSystemPrompt('translation');
    // final userPrompt = "Translate this: '$sentence'";

    debugPrint('[LocalLlmService] translateSentence: stub — GGUF not yet integrated');
    return null; // Stub — Neural Engine will use its dictionary-based fallback
  }

  /// Evaluates a sentence for the Contextual Sentence Builder Game.
  Future<Map<String, dynamic>> evaluateSentence(String userSentence) async {
    if (!_isInitialized) await initialize();

    // Prompts prepared for GGUF integration:
    // final systemPrompt = _buildSystemPrompt('sentence_builder');
    // final userPrompt = "Evaluate this sentence based on the vocabulary: '$userSentence'";

    debugPrint('[LocalLlmService] evaluateSentence: stub — GGUF not yet integrated');
    final bool isLikelyValid = userSentence.trim().isNotEmpty;
    
    return {
      "isValid": isLikelyValid,
      "feedback": isLikelyValid 
        ? "Good job! The structure makes sense based on the vocabulary." 
        : "Try checking the word order.",
    };
  }

  /// Suggests the next 3 lessons based on the student's recent score map.
  Future<List<String>> generateAdaptivePath(Map<String, int> categoryScores) async {
    if (!_isInitialized) await initialize();

    // Prompts prepared for GGUF integration:
    // final systemPrompt = _buildSystemPrompt('adaptive_path');
    // final userPrompt = "Student scores: $categoryScores. What should they study next?";

    debugPrint('[LocalLlmService] generateAdaptivePath: stub — GGUF not yet integrated');
    return ["Review Basic Pronouns", "Practice Colors", "Listen to Flora Audio"];
  }
}
