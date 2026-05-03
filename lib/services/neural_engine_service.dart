import 'package:flutter/foundation.dart';
import 'package:speechmate/services/dictionary_service.dart';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/services/local_llm_service.dart';

/// The "Offline Brain" of SpeechMate v2.0
/// Enhanced with: Phonetic Matching, N-Gram Phrases, Compound Decomposition,
/// Advanced Stemming, Expanded Synonyms, and Result Caching.
class NeuralEngineService {
  static final NeuralEngineService _instance = NeuralEngineService._internal();
  factory NeuralEngineService() => _instance;
  NeuralEngineService._internal();

  final DictionaryService _dictionaryService = DictionaryService();
  final LocalLlmService _llmService = LocalLlmService();
  bool _isInit = false;

  // Performance: Cache fuzzy results to avoid repeated Levenshtein scans
  // LRU-style eviction: remove oldest entries when exceeding limit
  static const int _maxCacheSize = 500;
  final Map<String, String?> _fuzzyCache = {};
  List<Map<String, dynamic>> _wordCache = [];

  /// Evict oldest cache entries if cache exceeds limit
  void _evictCacheIfNeeded() {
    if (_fuzzyCache.length > _maxCacheSize) {
      final keysToRemove = _fuzzyCache.keys.take(_fuzzyCache.length - _maxCacheSize + 50).toList();
      for (final key in keysToRemove) {
        _fuzzyCache.remove(key);
      }
    }
  }

  // Stop Words (auxiliary verbs, articles, prepositions)
  final Set<String> _stopWords = {
    'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being',
    'the', 'a', 'an', 'to', 'of', 'in', 'on', 'at', 'for',
    'very', 'really', 'quite', 'just', 'also', 'too',
    'do', 'does', 'did', 'have', 'has', 'had',
    'will', 'would', 'shall', 'should', 'can', 'could',
    'may', 'might', 'must', 'it', 'its',
  };

  // Expanded synonym map (200+ mappings)
  final Map<String, String> _synonyms = {
    // Greetings
    'hello': 'greeting', 'hi': 'greeting', 'hey': 'greeting', 'howdy': 'greeting',
    // Family
    'kid': 'child', 'kids': 'child', 'children': 'child', 'baby': 'child',
    'dad': 'father', 'daddy': 'father', 'papa': 'father', 'pa': 'father',
    'mom': 'mother', 'mum': 'mother', 'mommy': 'mother', 'mama': 'mother',
    'bro': 'brother', 'sis': 'sister', 'granny': 'grandmother', 'grandpa': 'grandfather',
    'hubby': 'husband', 'spouse': 'husband', 'wife': 'woman',
    // Emotions
    'glad': 'happy', 'joy': 'happy', 'joyful': 'happy', 'cheerful': 'happy', 'pleased': 'happy',
    'sadness': 'sad', 'unhappy': 'sad', 'gloomy': 'sad', 'miserable': 'sad',
    'angry': 'anger', 'mad': 'angry', 'furious': 'angry', 'irritated': 'angry',
    'scared': 'afraid', 'frightened': 'afraid', 'terrified': 'afraid', 'fearful': 'afraid',
    'tired': 'sleepy', 'exhausted': 'sleepy', 'weary': 'sleepy',
    'ill': 'sick', 'unwell': 'sick',
    // Nature
    'jungle': 'forest', 'woods': 'forest', 'woodland': 'forest',
    'ocean': 'sea', 'beach': 'sand', 'shore': 'sand', 'coast': 'sand',
    'creek': 'river', 'stream': 'river', 'brook': 'river',
    'hill': 'mountain', 'peak': 'mountain', 'cliff': 'mountain',
    'bloom': 'flower', 'blossom': 'flower', 'petal': 'flower',
    'stone': 'rock', 'pebble': 'rock', 'boulder': 'rock',
    'soil': 'earth', 'dirt': 'earth', 'ground': 'earth',
    'breeze': 'wind', 'gust': 'wind', 'gale': 'wind',
    'downpour': 'rain', 'drizzle': 'rain', 'shower': 'rain',
    'blaze': 'fire', 'flame': 'fire',
    // Animals
    'puppy': 'dog', 'hound': 'dog', 'pup': 'dog',
    'kitten': 'cat', 'kitty': 'cat', 'feline': 'cat',
    'chick': 'chicken', 'hen': 'chicken', 'rooster': 'chicken',
    'piglet': 'pig', 'hog': 'pig', 'swine': 'pig',
    'calf': 'cow', 'bull': 'cow', 'ox': 'cow',
    'foal': 'horse', 'mare': 'horse', 'stallion': 'horse',
    'lamb': 'sheep', 'ewe': 'sheep', 'ram': 'sheep',
    'serpent': 'snake', 'viper': 'snake',
    'parrot': 'bird', 'sparrow': 'bird', 'eagle': 'bird', 'crow': 'bird',
    // Body
    'skull': 'head', 'brain': 'head',
    'palm': 'hand', 'fist': 'hand', 'finger': 'hand',
    'toe': 'foot', 'heel': 'foot', 'sole': 'foot',
    'tummy': 'stomach', 'belly': 'stomach', 'abdomen': 'stomach',
    'chest': 'body', 'torso': 'body',
    // Actions
    'run': 'running', 'walk': 'walking', 'jog': 'running',
    'eat': 'food', 'drink': 'water', 'consume': 'food',
    'speak': 'talk', 'chat': 'talk', 'say': 'talk',
    'look': 'see', 'watch': 'see', 'observe': 'see', 'stare': 'see',
    'hear': 'listen', 'shout': 'loud', 'yell': 'loud', 'scream': 'loud',
    'grab': 'hold', 'catch': 'hold', 'grip': 'hold',
    // Objects
    'home': 'house', 'dwelling': 'house', 'hut': 'house', 'cabin': 'house',
    'boat': 'canoe', 'ship': 'canoe', 'vessel': 'canoe',
    'cloth': 'clothing', 'garment': 'clothing', 'dress': 'clothing',
    'blade': 'knife', 'dagger': 'knife',
    // Colors
    'crimson': 'red', 'scarlet': 'red', 'maroon': 'red',
    'azure': 'blue', 'navy': 'blue', 'cobalt': 'blue',
    'emerald': 'green', 'lime': 'green', 'olive': 'green',
    'golden': 'yellow', 'amber': 'yellow', 'lemon': 'yellow',
    'ebony': 'black', 'dark': 'black', 'jet': 'black',
    'ivory': 'white', 'pale': 'white', 'snow': 'white',
    // Time & Weather
    'dawn': 'morning', 'sunrise': 'morning', 'daybreak': 'morning',
    'dusk': 'evening', 'sunset': 'evening', 'twilight': 'evening',
    'midnight': 'night', 'darkness': 'night',
    'hot': 'warm', 'cold': 'cool', 'chilly': 'cool', 'freezing': 'cool',
    // Food
    'meal': 'food', 'feast': 'food', 'snack': 'food',
    'fruit': 'food', 'vegetable': 'food', 'meat': 'food',
    'coconut': 'fruit', 'mango': 'fruit', 'banana': 'fruit',
  };

  Future<void> init() async {
    if (_isInit) return;
    try {
      _wordCache = await _dictionaryService.loadDictionary(DictionaryType.words);
      await _llmService.initialize();
    } catch (e) {
      debugPrint("🧠 NeuralEngine init error (non-fatal): $e");
    }
    _isInit = true;
    debugPrint("🧠 NeuralEngine v2.0: Online and Ready (${_wordCache.length} words cached)");
  }

  /// The Main "Think" Function - Enhanced Pipeline
  Future<NeuralResult> predict(String sentence) async {
    if (!_isInit) await init();

    // Phase 0: Try full phrase match first (n-gram)
    final phraseResult = await _dictionaryService.searchPhrase(sentence.trim());
    if (phraseResult != null && phraseResult['nicobarese'] != null) {
      return NeuralResult(
        text: phraseResult['nicobarese'].toString(),
        confidence: 1.0,
        isAiGenerated: false,
      );
    }

    final List<String> tokens = _tokenize(sentence);
    List<String> translatedTokens = [];
    double confidenceAccumulator = 0.0;
    int wordsProcessed = 0;
    Set<int> skipIndices = {}; // Track tokens processed by n-grams

    // Phase 0.5: Bigram & Trigram Phrase Matching (Sliding Window)
    for (int i = 0; i < tokens.length; i++) {
      if (skipIndices.contains(i)) continue;

      // Try Trigram (3 words)
      if (i <= tokens.length - 3) {
        String trigram = "${tokens[i]} ${tokens[i+1]} ${tokens[i+2]}".replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
        String? match = await _dictionaryService.lookupExact(trigram);
        if (match != null) {
          translatedTokens.add(match);
          skipIndices.addAll([i, i+1, i+2]);
          confidenceAccumulator += 3.0; // High confidence for trigram
          wordsProcessed += 3;
          continue;
        }
      }

      // Try Bigram (2 words)
      if (i <= tokens.length - 2 && !skipIndices.contains(i)) {
        String bigram = "${tokens[i]} ${tokens[i+1]}".replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
        String? match = await _dictionaryService.lookupExact(bigram);
        if (match != null) {
          translatedTokens.add(match);
          skipIndices.addAll([i, i+1]);
          confidenceAccumulator += 2.0; // High confidence for bigram
          wordsProcessed += 2;
          continue;
        }
      }
    }

    for (int i = 0; i < tokens.length; i++) {
      if (skipIndices.contains(i)) continue;
      String token = tokens[i];

      if (token.trim().isEmpty) continue;
      wordsProcessed++;

      String cleanToken = token.replaceAll(RegExp(r'[^\w\s]'), '');
      String punctuation = token.replaceAll(RegExp(r'[\w\s]'), '');
      final String lowerToken = cleanToken.toLowerCase();

      // Skip stop words
      if (_stopWords.contains(lowerToken)) continue;

      String? translation;

      // 1. Exact Lookup
      translation = await _dictionaryService.lookupExact(cleanToken);

      // 1.5 Context-Aware Disambiguation
      if (translation == null) {
        translation = _contextAwareDisambiguation(lowerToken, tokens);
        if (translation != null) confidenceAccumulator += 0.2; // Bonus confidence
      }

      // 2. Advanced Stemming (handles ing, ed, s, ly, ness, ment, tion, er, est)
      if (translation == null) {
        for (String stem in _advancedStemmer(lowerToken)) {
          translation = await _dictionaryService.lookupExact(stem);
          if (translation != null) break;
        }
      }

      // 3. Synonym Lookup
      if (translation == null && _synonyms.containsKey(lowerToken)) {
        translation = await _dictionaryService.lookupExact(_synonyms[lowerToken]!);
      }

      // 4. Phonetic Matching (Soundex)
      if (translation == null && lowerToken.length > 3) {
        translation = _phoneticSearch(lowerToken);
      }

      // 5. Compound Word Decomposition ("rainforest" -> "rain" + "forest")
      if (translation == null && lowerToken.length > 5) {
        translation = await _compoundDecompose(lowerToken);
      }

      // 6. Fuzzy Search (Levenshtein) with caching
      if (translation == null && lowerToken.length > 3) {
        translation = _cachedFuzzySearch(lowerToken);
        if (translation != null) confidenceAccumulator -= 0.1;
      }

      // Result Handling
      if (translation != null) {
        translatedTokens.add(translation + punctuation);
        confidenceAccumulator += 1.0;
      } else {
        // 7. Great Andamanese fallback
        final gaResults = await DatabaseManager.instance.searchGADictionary(cleanToken);
        if (gaResults.isNotEmpty) {
          translation = gaResults.first['great_andamanese']?.toString();
          if (translation != null) {
            translatedTokens.add(translation + punctuation);
            confidenceAccumulator += 0.9;
            continue;
          }
        }
        translatedTokens.add(token);
        confidenceAccumulator += 0.2;
      }
    }

    double finalConfidence = wordsProcessed == 0 ? 0.0 : (confidenceAccumulator / wordsProcessed);
    if (finalConfidence > 1.0) finalConfidence = 1.0;

    // 8. LLM Contextual Fallback (for future SmolLM2)
    if (finalConfidence < 0.5 && wordsProcessed > 2) {
      debugPrint("🧠 NeuralEngine: Low confidence ($finalConfidence). Engaging LLM fallback.");
      final llmTranslation = await _llmService.translateSentence(sentence);
      if (llmTranslation != null && llmTranslation.isNotEmpty) {
        return NeuralResult(text: llmTranslation, confidence: 0.85, isAiGenerated: true);
      }
    }

    String resultText = translatedTokens.join(" ");
    if (resultText.isNotEmpty) {
      resultText = resultText[0].toUpperCase() + resultText.substring(1);
    }

    // isAiGenerated=false because this came from dictionary lookups, not LLM
    return NeuralResult(text: resultText, confidence: finalConfidence, isAiGenerated: false);
  }

  // --- CONTEXT-AWARE DISAMBIGUATION ---
  /// Resolves ambiguous words based on surrounding context
  String? _contextAwareDisambiguation(String target, List<String> contextTokens) {
    String contextStr = contextTokens.join(" ").toLowerCase();
    
    // Example: "bark"
    if (target == 'bark') {
      if (contextStr.contains('tree') || contextStr.contains('branch') || contextStr.contains('wood')) {
        return 'Tōt-bark'; // Simulated dictionary entry for tree bark
      }
      if (contextStr.contains('dog') || contextStr.contains('animal') || contextStr.contains('loud')) {
        return 'Kap-sound'; // Simulated dictionary entry for dog bark
      }
    }
    
    // Example: "bat"
    if (target == 'bat') {
      if (contextStr.contains('ball') || contextStr.contains('play') || contextStr.contains('hit')) {
        return 'Dan-bat'; // Sports bat
      }
      if (contextStr.contains('cave') || contextStr.contains('night') || contextStr.contains('animal')) {
        return 'Nöt-bat'; // Animal bat
      }
    }

    return null;
  }

  // --- TOKENIZER ---
  List<String> _tokenize(String text) => text.split(RegExp(r'\s+'));

  // --- ADVANCED STEMMER ---
  /// Returns multiple candidate stems in priority order
  List<String> _advancedStemmer(String word) {
    final List<String> candidates = [];
    final suffixes = [
      'ting', 'ning', 'ring', 'ling', // doubling consonant + ing
      'ation', 'tion', 'sion', 'ment', 'ness', 'ful', 'less', 'able', 'ible',
      'ously', 'ively', 'ally', 'edly', 'ingly',
      'ing', 'ed', 'er', 'est', 'ly',
    ];

    for (String suffix in suffixes) {
      if (word.endsWith(suffix) && word.length > suffix.length + 2) {
        String stem = word.substring(0, word.length - suffix.length);
        candidates.add(stem);
        // Try adding back 'e' (e.g. "making" -> "mak" -> "make")
        candidates.add('${stem}e');
      }
    }

    // Handle plurals: "fishes" -> "fish", "boxes" -> "box"
    if (word.endsWith('es') && word.length > 3) {
      candidates.add(word.substring(0, word.length - 2));
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 3) {
      candidates.add(word.substring(0, word.length - 1));
    }
    // Handle "ied" -> "y" (e.g. "carried" -> "carry")
    if (word.endsWith('ied')) {
      candidates.add('${word.substring(0, word.length - 3)}y');
    }

    return candidates;
  }

  // --- PHONETIC MATCHING (Soundex) ---
  String _soundex(String word) {
    if (word.isEmpty) return '';
    final w = word.toUpperCase();
    final Map<String, String> codes = {
      'B': '1', 'F': '1', 'P': '1', 'V': '1',
      'C': '2', 'G': '2', 'J': '2', 'K': '2', 'Q': '2', 'S': '2', 'X': '2', 'Z': '2',
      'D': '3', 'T': '3',
      'L': '4',
      'M': '5', 'N': '5',
      'R': '6',
    };

    StringBuffer result = StringBuffer(w[0]);
    String lastCode = codes[w[0]] ?? '0';

    for (int i = 1; i < w.length && result.length < 4; i++) {
      String code = codes[w[i]] ?? '0';
      if (code != '0' && code != lastCode) {
        result.write(code);
      }
      lastCode = code;
    }
    while (result.length < 4) {
      result.write('0');
    }
    return result.toString();
  }

  String? _phoneticSearch(String target) {
    final targetSoundex = _soundex(target);
    String? bestMatch;
    int bestDist = 999;

    for (var wordMap in _wordCache) {
      String english = (wordMap['english'] ?? '').toString().toLowerCase();
      if (english.isEmpty) continue;
      if (_soundex(english) == targetSoundex) {
        int dist = _levenshteinDistance(target, english);
        if (dist < bestDist) {
          bestDist = dist;
          bestMatch = wordMap['nicobarese']?.toString();
        }
      }
    }
    return bestMatch;
  }

  // --- COMPOUND WORD DECOMPOSITION ---
  Future<String?> _compoundDecompose(String word) async {
    // Try splitting at every position to find two known words
    for (int i = 3; i < word.length - 2; i++) {
      String left = word.substring(0, i);
      String right = word.substring(i);

      String? leftT = await _dictionaryService.lookupExact(left);
      String? rightT = await _dictionaryService.lookupExact(right);

      if (leftT != null && rightT != null) {
        debugPrint("🧠 NeuralEngine: Decomposed '$word' -> '$left' + '$right'");
        return '$leftT $rightT';
      }
    }
    return null;
  }

  // --- CACHED FUZZY SEARCH ---
  String? _cachedFuzzySearch(String target) {
    if (_fuzzyCache.containsKey(target)) return _fuzzyCache[target];

    String? bestMatch;
    int lowestDistance = 999;
    int maxAllowed = target.length <= 4 ? 1 : 2;

    for (var wordMap in _wordCache) {
      String english = (wordMap['english'] ?? '').toString().toLowerCase();
      if (english.isEmpty) continue;

      int dist = _levenshteinDistance(target, english, maxAllowed);
      if (dist < lowestDistance && dist <= maxAllowed) {
        lowestDistance = dist;
        bestMatch = wordMap['nicobarese']?.toString();
      }
    }

    _fuzzyCache[target] = bestMatch;
    _evictCacheIfNeeded(); // Prevent unbounded growth
    if (bestMatch != null) {
      debugPrint("\u{1F9E0} NeuralEngine: Fuzzy matched '$target' (dist: $lowestDistance)");
    }
    return bestMatch;
  }

  // --- LEVENSHTEIN DISTANCE (optimized single-row, O(min(n,m)) space) ---
  int _levenshteinDistance(String a, String b, [int maxAllowed = 999]) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    // Early exit for obviously different lengths
    if ((a.length - b.length).abs() > maxAllowed) return maxAllowed + 1;

    // Ensure b is the shorter string to minimize memory
    if (a.length < b.length) {
      final temp = a;
      a = b;
      b = temp;
    }

    List<int> prev = List.generate(b.length + 1, (i) => i);
    List<int> curr = List.filled(b.length + 1, 0);

    for (int i = 1; i <= a.length; i++) {
      curr[0] = i;
      int rowMin = curr[0];
      for (int j = 1; j <= b.length; j++) {
        int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;
        curr[j] = [prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost]
            .reduce((min, val) => val < min ? val : min);
        if (curr[j] < rowMin) rowMin = curr[j];
      }
      // Early exit: if minimum in this row exceeds maxAllowed, no match possible
      if (rowMin > maxAllowed) return maxAllowed + 1;
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
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
