import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:speechmate/services/dictionary_service.dart';

// The "Offline Brain" of SpeechMate
// Uses Symbolic AI + Fuzzy Logic instead of huge neural networks
class NeuralEngineService {
  final DictionaryService _dictionaryService = DictionaryService();
  bool _isInit = false;

  // Simple "Stop Words" that we might want to ignore if not found
  final Set<String> _stopWords = {
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'to', 'of', 'in', 'on', 'at'
  };

  // Maps common English synonyms to words we MIGHT have in our dictionary
  final Map<String, String> _synonyms = {
    'hello': 'greeting',
    'hi': 'greeting',
    'kid': 'child',
    'dad': 'father',
    'mom': 'mother',
    'mum': 'mother',
    'glad': 'happy',
    'joy': 'happy',
    'sadness': 'sad',
    'angry': 'anger',
    'mad': 'angry',
    'scared': 'afraid',
    'frightened': 'afraid',
    'home': 'house', 
    'run': 'running',
    'walk': 'walking',
  };

  Future<void> init() async {
    if (_isInit) return;
    await _dictionaryService.loadDictionary(DictionaryType.words);
    _isInit = true;
    debugPrint("🧠 NeuralEngine: Online and Ready");
  }

  // The Main "Think" Function
  Future<NeuralResult> predict(String sentence) async {
    if (!_isInit) await init();

    final List<String> tokens = _tokenize(sentence);
    List<String> translatedTokens = [];
    double confidenceAccumulator = 0.0;
    int wordsTranslated = 0;

    for (String token in tokens) {
      if (token.trim().isEmpty) continue;
      final String lowerToken = token.toLowerCase();
      String? translation;

      // 1. Exact Lookup
      translation = await _dictionaryService.lookupExact(lowerToken);

      // 2. Stemming Lookup (remove 'ing', 'ed', 's')
      // Only stem if no exact match (e.g. "running" -> "run")
      if (translation == null) {
         String stem = _simpleStemmer(lowerToken);
         if (stem != lowerToken) {
            translation = await _dictionaryService.lookupExact(stem);
         }
      }

      // 3. Synonym Lookup
      if (translation == null && _synonyms.containsKey(lowerToken)) {
          String synonym = _synonyms[lowerToken]!;
          translation = await _dictionaryService.lookupExact(synonym);
      }

      // Result Handling
      if (translation != null) {
        translatedTokens.add(translation);
        confidenceAccumulator += 1.0;
        wordsTranslated++;
      } else {
        // If it's a stop word and we missed it, mark confidence down but check context
        if (_stopWords.contains(lowerToken)) {
           translatedTokens.add(token);
           confidenceAccumulator += 0.5; // Partial credit
        } else {
           translatedTokens.add(token); // Keep original
           confidenceAccumulator += 0.0; // No credit
        }
      }
    }

    double finalConfidence = tokens.isEmpty ? 0.0 : (confidenceAccumulator / tokens.where((t) => t.trim().isNotEmpty).length);
    // Cap confidence
    if (finalConfidence > 1.0) finalConfidence = 1.0;

    String resultText = translatedTokens.join(" ");

    // Smart capitalization
    if (resultText.isNotEmpty) {
      resultText = resultText[0].toUpperCase() + resultText.substring(1);
    }

    return NeuralResult(
      text: resultText,
      confidence: finalConfidence,
      isAiGenerated: true,
    );
  }

  List<String> _tokenize(String text) {
    // Simple split by space, preserving basic punctuation could be an enhancement
    // For now, simple split
    return text.split(' ');
  }

  String _simpleStemmer(String word) {
    if (word.endsWith('ing')) return word.substring(0, word.length - 3);
    if (word.endsWith('ed')) return word.substring(0, word.length - 2);
    if (word.endsWith('s') && !word.endsWith('ss')) return word.substring(0, word.length - 1);
    return word;
  }
}

class NeuralResult {
  final String text;
  final double confidence;
  final bool isAiGenerated;

  NeuralResult({
    required this.text,
    required this.confidence,
    required this.isAiGenerated,
  });
}
