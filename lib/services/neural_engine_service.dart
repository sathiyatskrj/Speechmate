import 'package:flutter/foundation.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/database_manager.dart';

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

      // 4. Fuzzy Search Fallback (Levenshtein)
      if (translation == null && lowerToken.length > 3) {
          translation = await _fuzzySearch(lowerToken);
          // Decrease confidence slightly because it's a guess
          if (translation != null) {
             confidenceAccumulator -= 0.1; 
          }
      }

      // Result Handling
      if (translation != null) {
        translatedTokens.add(translation + punctuation);
        confidenceAccumulator += 1.0;
      } else {
         // 5. Great Andamanese fallback
         final gaResults = await DatabaseManager.instance.searchGADictionary(cleanToken);
         if (gaResults.isNotEmpty) {
           translation = gaResults.first['great_andamanese']?.toString();
           if (translation != null) {
             translatedTokens.add(translation + punctuation);
             confidenceAccumulator += 0.9;
             continue;
           }
         }
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

  // --- Fuzzy Logic (Levenshtein Distance) ---
  int _levenshteinDistance(String a, String b) {
    if (a.length == 0) return b.length;
    if (b.length == 0) return a.length;

    var matrix = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));

    for (int i = 0; i <= a.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= b.length; j++) matrix[0][j] = j;

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        ].reduce((min, val) => val < min ? val : min);
      }
    }
    return matrix[a.length][b.length];
  }

  Future<String?> _fuzzySearch(String target) async {
    // 1. Get all words (optimally this should be cached if DB is large, but acceptable for now offline)
    final wordsMapList = await _dictionaryService.loadDictionary(DictionaryType.words);
    
    String? bestMatch;
    int lowestDistance = 999;
    
    // We only accept corrections if they are very close (max 2 character difference)
    int maxAllowedDistance = target.length <= 4 ? 1 : 2;

    for (var wordMap in wordsMapList) {
       String englishWord = (wordMap['english'] ?? '').toString().toLowerCase();
       if (englishWord.isEmpty) continue;

       int dist = _levenshteinDistance(target, englishWord);
       if (dist < lowestDistance && dist <= maxAllowedDistance) {
         lowestDistance = dist;
         bestMatch = wordMap['nicobarese'];
       }
    }
    
    if (lowestDistance <= maxAllowedDistance) {
      debugPrint("🧠 NeuralEngine: Fuzzy matched '$target' to nearest match (dist: $lowestDistance)");
      return bestMatch;
    }
    return null;
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
