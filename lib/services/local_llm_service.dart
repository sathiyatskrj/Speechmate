import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:speechmate/services/model_downloader_service.dart';

/// Local LLM Service designed specifically for SmolLM2 135M.
/// This service loads the model via an FFI bridge (like llama_cpp_dart)
/// and uses `dictionary.json` as In-Context Knowledge (RAG).
///
/// **Status**: GGUF inference is not yet integrated. The three public
/// methods provide dictionary-powered fallback logic so callers receive
/// meaningful results instead of hardcoded stubs.
class LocalLlmService {
  bool _isInitialized = false;
  List<dynamic> _dictionaryCache = [];
  
  bool get isInitialized => _isInitialized;

  /// Initializes the SmolLM2 inference engine and loads the dictionary.
  Future<void> initialize() async {
    try {
      debugPrint('[LocalLlmService] Loading dictionary.json for context injection...');
      final String jsonString = await rootBundle.loadString('assets/data/dictionary.json');
      final decoded = json.decode(jsonString);
      // Support watermarked structure: {"_speechmate_metadata": {...}, "entries": [...]}
      _dictionaryCache = (decoded is Map && decoded.containsKey('entries'))
          ? decoded['entries'] as List<dynamic>
          : decoded as List<dynamic>;

      final downloader = ModelDownloaderService();
      final isDownloaded = await downloader.isModelDownloaded();
      
      if (isDownloaded) {
        final localPath = await downloader.getModelPath();
        debugPrint('[LocalLlmService] Loaded Local AI Tutor (TinyLlama) from: $localPath');
        _isInitialized = true;
      } else {
        debugPrint('[LocalLlmService] Model not found locally. Awaiting user download.');
        // Dictionary-powered fallbacks will still work without the GGUF model.
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('[LocalLlmService] Initialization failed: $e');
    }
  }

  /// Builds the foundational system prompt, injecting Nicobarese vocabulary
  /// so the 135M model acts as a localized linguistic engine.
  // ignore: unused_element
  String _buildSystemPrompt(String taskType) {
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

  /// Translates an English sentence to Nicobarese using the offline dictionary.
  ///
  /// Performs word-by-word dictionary lookup. Words without a match are kept
  /// in English to avoid hallucination. Returns null only if the dictionary
  /// is empty or the sentence is blank.
  Future<String?> translateSentence(String sentence) async {
    if (!_isInitialized) await initialize();
    if (sentence.trim().isEmpty || _dictionaryCache.isEmpty) return null;

    // Build a fast lookup map: english → nicobarese
    final Map<String, String> lookupMap = {};
    for (final entry in _dictionaryCache) {
      final eng = (entry['english'] ?? entry['text'] ?? '').toString().toLowerCase().trim();
      final nic = (entry['nicobarese'] ?? '').toString().trim();
      if (eng.isNotEmpty && nic.isNotEmpty) {
        lookupMap[eng] = nic;
      }
    }

    // Tokenize the input sentence and translate word-by-word
    final words = sentence.trim().split(RegExp(r'\s+'));
    final translated = words.map((word) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      return lookupMap[clean] ?? word; // Keep original if no match
    }).toList();

    final result = translated.join(' ');
    debugPrint('[LocalLlmService] translateSentence: ${words.length} words → ${translated.where((w) => lookupMap.containsKey(w.toLowerCase())).length} matched');
    return result;
  }

  /// Evaluates a user's Nicobarese sentence against the dictionary.
  ///
  /// Checks how many words in the sentence are valid Nicobarese entries.
  /// Returns a validity score and specific feedback about unrecognized words.
  Future<Map<String, dynamic>> evaluateSentence(String userSentence) async {
    if (!_isInitialized) await initialize();
    if (userSentence.trim().isEmpty) {
      return {"isValid": false, "feedback": "Please enter a sentence to evaluate."};
    }

    // Build a set of known Nicobarese words for fast lookup
    final Set<String> knownNicobarese = {};
    for (final entry in _dictionaryCache) {
      final nic = (entry['nicobarese'] ?? '').toString().toLowerCase().trim();
      if (nic.isNotEmpty) {
        // Add individual words from multi-word entries
        for (final word in nic.split(RegExp(r'\s+'))) {
          knownNicobarese.add(word.replaceAll(RegExp(r'[^\w]'), ''));
        }
      }
    }

    final words = userSentence.trim().split(RegExp(r'\s+'));
    final unrecognized = <String>[];
    int matchCount = 0;

    for (final word in words) {
      final clean = word.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
      if (clean.isEmpty) continue;
      if (knownNicobarese.contains(clean)) {
        matchCount++;
      } else {
        unrecognized.add(word);
      }
    }

    final double ratio = words.isEmpty ? 0 : matchCount / words.length;
    final bool isValid = ratio >= 0.5; // At least half the words should be recognized

    String feedback;
    if (ratio >= 0.8) {
      feedback = "Excellent! Most words are valid Nicobarese vocabulary.";
    } else if (ratio >= 0.5) {
      feedback = "Good attempt! These words were not recognized: ${unrecognized.join(', ')}";
    } else if (matchCount > 0) {
      feedback = "Keep trying! Only $matchCount of ${words.length} words matched. Unrecognized: ${unrecognized.take(5).join(', ')}";
    } else {
      feedback = "No Nicobarese words detected. Try using vocabulary from the dictionary.";
    }

    return {"isValid": isValid, "feedback": feedback, "matchRatio": ratio};
  }

  /// Suggests the next 3 learning focus areas based on the student's category scores.
  ///
  /// Analyzes the score map to find the weakest categories and recommends
  /// specific learning paths. Categories scoring below 50% are prioritized.
  Future<List<String>> generateAdaptivePath(Map<String, int> categoryScores) async {
    if (!_isInitialized) await initialize();
    if (categoryScores.isEmpty) {
      return ["Start with Basic Vocabulary", "Try the Numbers Module", "Explore Animal Words"];
    }

    // Sort categories by score (ascending = weakest first)
    final sorted = categoryScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Map category keys to human-readable learning suggestions
    const categoryLabels = {
      'animals': 'Practice Animal Words',
      'nature': 'Explore Nature Vocabulary',
      'numbers': 'Review Number Words',
      'colors': 'Learn More Color Terms',
      'family': 'Study Family Relationships',
      'things': 'Master Everyday Objects',
      'feelings': 'Express Emotions in Nicobarese',
      'body_parts': 'Learn Body Part Names',
      'magic': 'Discover Magic Words',
      'vocabulary': 'Expand General Vocabulary',
    };

    final suggestions = <String>[];
    for (final entry in sorted) {
      if (suggestions.length >= 3) break;
      final label = categoryLabels[entry.key] ?? 'Review ${entry.key}';
      if (entry.value < 50) {
        suggestions.add('$label (needs work — ${entry.value}%)');
      } else {
        suggestions.add(label);
      }
    }

    // Pad if less than 3 categories have scores
    while (suggestions.length < 3) {
      suggestions.add('Explore a new category');
    }

    debugPrint('[LocalLlmService] Adaptive path: ${suggestions.join(', ')}');
    return suggestions;
  }
}
