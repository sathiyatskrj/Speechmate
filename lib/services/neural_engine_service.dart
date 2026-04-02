import 'package:flutter/foundation.dart';
import 'package:speechmate/services/dictionary_service.dart';

// The "Offline Brain" of SpeechMate
// Uses Symbolic AI + Fuzzy Logic instead of huge neural networks
class NeuralEngineService {
  static final NeuralEngineService _instance = NeuralEngineService._internal();
  factory NeuralEngineService() => _instance;
  NeuralEngineService._internal();

  final DictionaryService _dictionaryService = DictionaryService();
  bool _isInit = false;

  // Simple "Stop Words" that we might want to ignore if not found
  final Set<String> _stopWords = {
    'is', 'am', 'are', 'was', 'were', 'the', 'a', 'an', 'to', 'of', 'in', 'on', 'at', 'very', 'really'
  };

  // Maps common English synonyms to words we MIGHT have in our dictionary
  final Map<String, String> _synonyms = {
    'hello': 'greeting', 'hi': 'greeting', 'kid': 'child', 'dad': 'father', 'mom': 'mother',
    'mum': 'mother', 'glad': 'happy', 'joy': 'happy', 'sadness': 'sad', 'angry': 'anger',
    'mad': 'angry', 'scared': 'afraid', 'frightened': 'afraid', 'home': 'house', 
    'run': 'running', 'walk': 'walking', 'beach': 'sand', 'jungle': 'forest', 
    'magic': 'mystery', 'ocean': 'sea', 'eat': 'food', 'drink': 'water'
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
    int wordsProcessed = 0;

    for (String token in tokens) {
      if (token.trim().isEmpty) continue;
      wordsProcessed++;
      
      // Remove punctuation for lookup
      String cleanToken = token.replaceAll(RegExp(r'[^\w\s]'), '');
      String punctuation = token.replaceAll(RegExp(r'[\w\s]'), ''); 
      
      final String lowerToken = cleanToken.toLowerCase();
      
      // 0. Skip Stop Words (Auxiliary verbs) entirely
      if (_stopWords.contains(lowerToken)) continue; 

      String? translation;

      // 1. Exact Lookup
      translation = await _dictionaryService.lookupExact(cleanToken);

      // 2. Stemming Lookup (remove 'ing', 'ed', 's')
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
        translatedTokens.add(translation + punctuation);
        confidenceAccumulator += 1.0;
      } else {
         // Keep original word (e.g. Names)
         translatedTokens.add(token);
         confidenceAccumulator += 0.2; 
      }
    }

    double finalConfidence = wordsProcessed == 0 ? 0.0 : (confidenceAccumulator / wordsProcessed);
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
    return text.split(RegExp(r'\s+'));
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
