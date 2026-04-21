import 'package:flutter/foundation.dart';
import 'package:speechmate/services/database_manager.dart';

/// Nicobarese Linguistics Engine
/// Implements the five core components of language science:
/// 1. Phonology — Sound system and pronunciation patterns
/// 2. Morphology — Word formation and structure
/// 3. Syntax — Sentence structure and word order
/// 4. Semantics — Meaning and vocabulary relationships
/// 5. Pragmatics — Contextual and cultural usage

class LinguisticsService {
  static final LinguisticsService instance = LinguisticsService._();
  LinguisticsService._();

  // Cached dictionary for fast lookups
  List<Map<String, dynamic>> _dictionary = [];
  List<Map<String, dynamic>> _phrases = [];
  bool _loaded = false;

  /// Load all language data for analysis
  Future<void> loadCorpus() async {
    if (_loaded) return;
    try {
      _dictionary = await DatabaseManager.instance.queryAll('words');
      _phrases = await DatabaseManager.instance.queryAll('phrases');
      _loaded = true;
      debugPrint('[Linguistics] Corpus loaded: ${_dictionary.length} words, ${_phrases.length} phrases');
    } catch (e) {
      debugPrint('[Linguistics] Corpus load error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 1. PHONOLOGY — Sound System Analysis
  // ═══════════════════════════════════════════════════════════════

  /// Nicobarese phonological inventory
  /// Based on Car Nicobarese sound system
  static const Map<String, List<String>> phonemeInventory = {
    'vowels': ['a', 'ā', 'e', 'ē', 'i', 'ī', 'o', 'ō', 'u', 'ū', 'ö', 'ü'],
    'long_vowels': ['ā', 'ē', 'ī', 'ō', 'ū'],
    'short_vowels': ['a', 'e', 'i', 'o', 'u', 'ö', 'ü'],
    'nasals': ['m', 'n', 'ng', 'ŋ'],
    'stops': ['p', 't', 'k', 'ch', 'h'],
    'fricatives': ['f', 's', 'h'],
    'liquids': ['l', 'r'],
    'glides': ['y', 'w'],
  };

  /// Audio file mapping for phoneme training
  /// Maps english words to their audio category and file
  static const Map<String, Map<String, String>> audioPhonemeMap = {
    // Animals — good for stop consonants and nasals
    'dog': {'category': 'animals', 'file': 'dog.mp3', 'phonemes': 'a-m'},
    'pig': {'category': 'animals', 'file': 'pig.mp3', 'phonemes': 'h-a-ö-n'},
    'chicken': {'category': 'animals', 'file': 'chicken.mp3', 'phonemes': 'k-o-t-ö-k'},
    'fish': {'category': 'animals', 'file': 'fish.mp3', 'phonemes': 'h-ī-ch-ā'},
    'goat': {'category': 'animals', 'file': 'goat.mp3', 'phonemes': 'k-a-m-ö-ng'},
    // Body parts — diverse phonemic coverage
    'eye': {'category': 'body_parts', 'file': 'eye.mp3', 'phonemes': 'm-ö-t-ö'},
    'ear': {'category': 'body_parts', 'file': 'ear.mp3', 'phonemes': 't-a-n-a-ng-a'},
    'nose': {'category': 'body_parts', 'file': 'nose.mp3', 'phonemes': 'n-ö-ng-ū-m'},
    'hand': {'category': 'body_parts', 'file': 'hand.mp3', 'phonemes': 'k-ā-ö-t'},
    'head': {'category': 'body_parts', 'file': 'head.mp3', 'phonemes': 'ch-ö-m'},
    // Numbers — rhythmic phonological patterns
    'one': {'category': 'numbers', 'file': '1.mp3', 'phonemes': 'h-e-ng'},
    'two': {'category': 'numbers', 'file': '2.mp3', 'phonemes': 'n-ē-k'},
    'three': {'category': 'numbers', 'file': '3.mp3', 'phonemes': 'l-ū-y'},
    // Nature — long vowels and diphthongs
    'sun': {'category': 'nature', 'file': 'sun.mp3', 'phonemes': 't-a-h-a-ē-ng'},
    'rain': {'category': 'nature', 'file': 'rain.mp3', 'phonemes': 'k-ū-m-y-ū'},
    'fire': {'category': 'nature', 'file': 'fire.mp3', 'phonemes': 'y-ū-h'},
    'tree': {'category': 'nature', 'file': 'tree.mp3', 'phonemes': 'd-ā-ng'},
  };

  /// Analyze the phonological structure of a Nicobarese word
  PhonologyResult analyzePhonology(String nicobarese) {
    final syllables = _splitSyllables(nicobarese);
    final phonemes = _extractPhonemes(nicobarese);
    final hasLongVowel = phonemeInventory['long_vowels']!.any((v) => nicobarese.contains(v));
    final hasNasal = phonemeInventory['nasals']!.any((n) => nicobarese.contains(n));
    
    return PhonologyResult(
      word: nicobarese,
      syllableCount: syllables.length,
      syllables: syllables,
      phonemes: phonemes,
      hasLongVowel: hasLongVowel,
      hasNasal: hasNasal,
      difficulty: _calculatePhonologicalDifficulty(nicobarese),
    );
  }

  List<String> _splitSyllables(String word) {
    // Simple syllable splitting: split on hyphens or by vowel-consonant patterns
    if (word.contains('-')) return word.split('-');
    if (word.contains(' ')) return word.split(' ');
    
    // Basic CV splitting
    List<String> syllables = [];
    String current = '';
    bool lastWasVowel = false;
    
    for (int i = 0; i < word.length; i++) {
      final char = word[i].toLowerCase();
      final isVowel = 'aeioōūēīāöü'.contains(char);
      
      if (isVowel && lastWasVowel && current.length > 1) {
        syllables.add(current);
        current = String.fromCharCode(word.codeUnitAt(i));
      } else if (!isVowel && lastWasVowel && current.length > 2) {
        syllables.add(current);
        current = String.fromCharCode(word.codeUnitAt(i));
      } else {
        current += String.fromCharCode(word.codeUnitAt(i));
      }
      lastWasVowel = isVowel;
    }
    if (current.isNotEmpty) syllables.add(current);
    return syllables.isEmpty ? [word] : syllables;
  }

  List<String> _extractPhonemes(String word) {
    List<String> phonemes = [];
    String lower = word.toLowerCase();
    int i = 0;
    while (i < lower.length) {
      // Check digraphs first
      if (i + 1 < lower.length) {
        String digraph = lower.substring(i, i + 2);
        if (['ch', 'ng', 'sh'].contains(digraph)) {
          phonemes.add(digraph);
          i += 2;
          continue;
        }
      }
      if (lower[i] != '-' && lower[i] != ' ') {
        phonemes.add(lower[i]);
      }
      i++;
    }
    return phonemes;
  }

  int _calculatePhonologicalDifficulty(String word) {
    int score = 1; // Base
    if (word.length > 6) score++;
    if (word.contains('ng')) score++;
    if (word.contains('ö') || word.contains('ü')) score++; // Unfamiliar vowels
    if (word.contains('-')) score++; // Compound
    return score.clamp(1, 5);
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. MORPHOLOGY — Word Formation
  // ═══════════════════════════════════════════════════════════════

  /// Common Nicobarese morphological patterns
  static const Map<String, String> prefixes = {
    'tö-': 'locative/directional marker',
    'kā-': 'possession/body part marker',
    'ön-': 'state/desire marker (hungry, thirsty)',
    'mā-': 'negative/diminutive marker',
  };

  static const Map<String, String> suffixes = {
    '-ēng': 'celestial/large entity marker (sun, moon)',
    '-ūm': 'body extremity marker',
    '-ūh': 'elemental force marker',
    '-öt': 'state/condition marker',
  };

  /// Analyze morphological structure of a Nicobarese word
  MorphologyResult analyzeMorphology(String nicobarese) {
    String root = nicobarese;
    List<String> detectedPrefixes = [];
    List<String> detectedSuffixes = [];
    
    for (final prefix in prefixes.keys) {
      if (nicobarese.toLowerCase().startsWith(prefix.replaceAll('-', ''))) {
        detectedPrefixes.add(prefix);
        root = root.substring(prefix.length - 1);
      }
    }
    
    for (final suffix in suffixes.keys) {
      final cleanSuffix = suffix.replaceAll('-', '');
      if (nicobarese.toLowerCase().endsWith(cleanSuffix)) {
        detectedSuffixes.add(suffix);
        root = root.substring(0, root.length - cleanSuffix.length);
      }
    }

    final isCompound = nicobarese.contains('-') || nicobarese.contains(' ');
    final parts = isCompound ? nicobarese.split(RegExp(r'[-\s]')) : [nicobarese];

    return MorphologyResult(
      word: nicobarese,
      root: root,
      prefixes: detectedPrefixes,
      suffixes: detectedSuffixes,
      isCompound: isCompound,
      compoundParts: parts,
      prefixMeanings: detectedPrefixes.map((p) => prefixes[p] ?? '').toList(),
      suffixMeanings: detectedSuffixes.map((s) => suffixes[s] ?? '').toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. SYNTAX — Sentence Structure
  // ═══════════════════════════════════════════════════════════════

  /// Nicobarese follows SOV (Subject-Object-Verb) word order
  /// This is different from English SVO
  static const String wordOrder = 'SOV';
  
  static const Map<String, String> syntaxRules = {
    'word_order': 'Subject → Object → Verb (SOV)',
    'question_marker': 'Rising intonation or question particle at end',
    'negation': 'Negation marker typically precedes the verb',
    'possession': 'Possessor precedes possessed noun',
    'adjective': 'Adjectives typically follow the noun',
  };

  /// Convert English SVO to Nicobarese SOV structure
  SyntaxResult analyzeSyntax(String englishSentence) {
    final words = englishSentence.trim().split(' ');
    final isQuestion = englishSentence.contains('?') || 
                       englishSentence.toLowerCase().startsWith('what') ||
                       englishSentence.toLowerCase().startsWith('how');
    
    return SyntaxResult(
      original: englishSentence,
      wordOrder: wordOrder,
      isQuestion: isQuestion,
      structureNotes: isQuestion 
        ? 'Nicobarese questions use rising intonation or particle markers'
        : 'Follow SOV: Place the verb at the end of the sentence',
      wordCount: words.length,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. SEMANTICS — Meaning Relationships
  // ═══════════════════════════════════════════════════════════════

  /// Semantic categories with audio-based learning paths
  static const Map<String, List<String>> semanticFields = {
    'kinship': ['Father', 'Mother', 'Brother', 'Sister', 'Grandfather', 'Grandmother'],
    'body': ['Eye', 'Ear', 'Nose', 'Mouth', 'Hand', 'Foot', 'Head', 'Hair', 'Stomach'],
    'nature': ['Sun', 'Moon', 'Rain', 'Cloud', 'Sea', 'River', 'Fire', 'Tree', 'Flower', 'Mountain'],
    'animals': ['Dog', 'Pig', 'Chicken', 'Fish', 'Goat', 'Crab', 'Lizard', 'Monkey'],
    'emotions': ['Happy', 'Sad', 'Angry', 'Scared'],
    'colors': ['Blue', 'Green', 'Red', 'White', 'Black'],
    'objects': ['Bag', 'Bed', 'Book', 'Chair', 'Cup', 'Door', 'Table', 'Window'],
    'greetings': ['Hello', 'Goodbye', 'Thank you', 'Sorry', 'Please'],
    'numbers': ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'],
  };

  /// Find semantically related words
  Future<List<Map<String, dynamic>>> getSemanticRelations(String english) async {
    await loadCorpus();
    
    // Find which semantic field this word belongs to
    String? field;
    for (final entry in semanticFields.entries) {
      if (entry.value.any((w) => w.toLowerCase() == english.toLowerCase())) {
        field = entry.key;
        break;
      }
    }
    
    if (field == null) return [];
    
    // Return all words in the same semantic field
    final relatedWords = semanticFields[field]!;
    return _dictionary.where((w) {
      final eng = w['english']?.toString().toLowerCase() ?? '';
      return relatedWords.any((r) => r.toLowerCase() == eng) && eng != english.toLowerCase();
    }).toList();
  }

  /// Get the semantic field name for a word
  String? getSemanticField(String english) {
    for (final entry in semanticFields.entries) {
      if (entry.value.any((w) => w.toLowerCase() == english.toLowerCase())) {
        return entry.key;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. PRAGMATICS — Contextual & Cultural Usage
  // ═══════════════════════════════════════════════════════════════

  /// Cultural context for language usage
  static const Map<String, PragmaticNote> culturalNotes = {
    'greetings': PragmaticNote(
      context: 'Greetings',
      note: 'Nicobarese greetings vary by time of day and social relationship. '
            'Elders are addressed with more formal forms.',
      formality: 'formal',
      audioExamples: ['phrases/good_morning.mp3', 'phrases/how_are_you.mp3'],
    ),
    'kinship': PragmaticNote(
      context: 'Family Terms',
      note: 'The Tuhet (kinship) system is central to Nicobarese culture. '
            'Kinship terms encode age, gender, and social hierarchy.',
      formality: 'respectful',
      audioExamples: ['family/father.mp3', 'family/mother.mp3'],
    ),
    'classroom': PragmaticNote(
      context: 'Classroom Commands',
      note: 'Used in school settings. These are direct imperative forms.',
      formality: 'directive',
      audioExamples: ['phrases/sit_down.mp3', 'phrases/stand_up.mp3', 'phrases/open_your_book.mp3'],
    ),
    'politeness': PragmaticNote(
      context: 'Politeness Markers',
      note: 'Magic words like "please", "thank you", and "sorry" are essential in formal interactions.',
      formality: 'polite',
      audioExamples: ['magic/thank_you.mp3', 'magic/sorry.mp3', 'magic/please.mp3'],
    ),
  };

  /// Get pragmatic context for a word or phrase
  PragmaticNote? getPragmaticContext(String english) {
    final lower = english.toLowerCase();
    
    if (['father', 'mother', 'brother', 'sister', 'grandfather', 'grandmother', 'friend'].contains(lower)) {
      return culturalNotes['kinship'];
    }
    if (['good morning', 'how are you', 'what is your name', 'good afternoon'].contains(lower)) {
      return culturalNotes['greetings'];
    }
    if (['sit down', 'stand up', 'open your book', 'close your book', 'keep silent'].contains(lower)) {
      return culturalNotes['classroom'];
    }
    if (['hello', 'goodbye', 'thank you', 'sorry', 'please', 'pardon', 'may i'].contains(lower)) {
      return culturalNotes['politeness'];
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPREHENSIVE ANALYSIS — All 5 components combined
  // ═══════════════════════════════════════════════════════════════

  /// Full linguistic analysis of a word
  LinguisticAnalysis analyzeWord(String english, String nicobarese) {
    return LinguisticAnalysis(
      english: english,
      nicobarese: nicobarese,
      phonology: analyzePhonology(nicobarese),
      morphology: analyzeMorphology(nicobarese),
      syntax: analyzeSyntax(english),
      semanticField: getSemanticField(english),
      pragmatics: getPragmaticContext(english),
      audioPath: audioPhonemeMap[english.toLowerCase()]?['category'] != null
          ? 'audio/${audioPhonemeMap[english.toLowerCase()]!['category']}/${audioPhonemeMap[english.toLowerCase()]!['file']}'
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

class PhonologyResult {
  final String word;
  final int syllableCount;
  final List<String> syllables;
  final List<String> phonemes;
  final bool hasLongVowel;
  final bool hasNasal;
  final int difficulty; // 1-5

  PhonologyResult({
    required this.word,
    required this.syllableCount,
    required this.syllables,
    required this.phonemes,
    required this.hasLongVowel,
    required this.hasNasal,
    required this.difficulty,
  });

  @override
  String toString() => 'Phonology($word): $syllableCount syllables [${ syllables.join("-") }], difficulty: $difficulty/5';
}

class MorphologyResult {
  final String word;
  final String root;
  final List<String> prefixes;
  final List<String> suffixes;
  final bool isCompound;
  final List<String> compoundParts;
  final List<String> prefixMeanings;
  final List<String> suffixMeanings;

  MorphologyResult({
    required this.word,
    required this.root,
    required this.prefixes,
    required this.suffixes,
    required this.isCompound,
    required this.compoundParts,
    required this.prefixMeanings,
    required this.suffixMeanings,
  });

  @override
  String toString() => 'Morphology($word): root=$root, compound=$isCompound, prefixes=$prefixes, suffixes=$suffixes';
}

class SyntaxResult {
  final String original;
  final String wordOrder;
  final bool isQuestion;
  final String structureNotes;
  final int wordCount;

  SyntaxResult({
    required this.original,
    required this.wordOrder,
    required this.isQuestion,
    required this.structureNotes,
    required this.wordCount,
  });
}

class PragmaticNote {
  final String context;
  final String note;
  final String formality;
  final List<String> audioExamples;

  const PragmaticNote({
    required this.context,
    required this.note,
    required this.formality,
    required this.audioExamples,
  });
}

class LinguisticAnalysis {
  final String english;
  final String nicobarese;
  final PhonologyResult phonology;
  final MorphologyResult morphology;
  final SyntaxResult syntax;
  final String? semanticField;
  final PragmaticNote? pragmatics;
  final String? audioPath;

  LinguisticAnalysis({
    required this.english,
    required this.nicobarese,
    required this.phonology,
    required this.morphology,
    required this.syntax,
    this.semanticField,
    this.pragmatics,
    this.audioPath,
  });
}
