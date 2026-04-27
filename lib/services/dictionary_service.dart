import 'dart:math';
import 'package:speechmate/services/database_manager.dart';
import 'package:speechmate/core/app_strings.dart';
import 'package:translator/translator.dart';

enum DictionaryType { words, phrases, nature, numbers, animals, magic, family, dialects }

class DictionaryService {
  static final DictionaryService _instance = DictionaryService._internal();
  factory DictionaryService() => _instance;
  DictionaryService._internal();

  final DatabaseManager _db = DatabaseManager.instance;

  Future<List<Map<String, dynamic>>> loadDictionary(DictionaryType type) async {
    final String category = type.name;
    
    if (type == DictionaryType.phrases) {
      return await _db.queryAll('phrases');
    } else if (type == DictionaryType.dialects) {
      return await _db.queryAll('dialects');
    } else {
      // All word-type categories: words, nature, numbers, animals, magic, family
      // Each has its own category_id in the words table, seeded from its own JSON file
      return await _db.getWordsByCategory(category);
    }
  }

  Future<void> unload(DictionaryType type) async {
    // No-op for SQLite, memory is handled by the DB engine
  }

  final _onlineTranslator = GoogleTranslator();

  Future<String> _ensureEnglish(String query) async {
    final lang = AppStrings.currentLanguage;
    if (lang != 'en' && lang != 'nc' && lang != 'gn') {
      try {
        final translation = await _onlineTranslator.translate(query, from: lang, to: 'en');
        return translation.text.toLowerCase();
      } catch (e) {
        return query.toLowerCase();
      }
    }
    return query.toLowerCase();
  }

  Future<Map<String, dynamic>?> searchWord(String query) async {
    final enQuery = await _ensureEnglish(query);
    return await _db.searchExact(enQuery, 'words', ['english', 'nicobarese']);
  }

  Future<Map<String, dynamic>?> searchPhrase(String query) async {
    final enQuery = await _ensureEnglish(query);
    return await _db.searchExact(enQuery, 'phrases', ['text', 'english']);
  }

  Future<List<Map<String, dynamic>>> getAnimalsItems() async {
    return loadDictionary(DictionaryType.animals);
  }
  
  Future<List<Map<String, dynamic>>> getMagicItems() async {
     return loadDictionary(DictionaryType.magic);
  }
  
  Future<List<Map<String, dynamic>>> getFamilyItems() async {
      return loadDictionary(DictionaryType.family);
  }

  Future<Map<String, dynamic>?> searchEverywhere(String query) async {
    if (query.trim().isEmpty) return null;
    final q = await _ensureEnglish(query.trim());

    // 1. Search ALL words in the database (covers words, numbers, nature, colors, feelings, things, body_parts, animals, magic, family)
    final db = await _db.database;
    final wordResults = await db.query(
      'words',
      where: 'LOWER(english) = ? OR LOWER(nicobarese) = ?',
      whereArgs: [q, q],
      limit: 1,
    );
    if (wordResults.isNotEmpty) {
      final w = wordResults.first;
      final isNicobarese = w['nicobarese']?.toString().toLowerCase() == q;
      return {
        ...w,
        '_type': w['category_id'] ?? 'words',
        '_searchedNicobarese': isNicobarese,
      };
    }

    // 2. Fuzzy search words (LIKE match)
    final fuzzyResults = await db.query(
      'words',
      where: 'LOWER(english) LIKE ? OR LOWER(nicobarese) LIKE ?',
      whereArgs: ['%$q%', '%$q%'],
      limit: 1,
    );
    if (fuzzyResults.isNotEmpty) {
      final w = fuzzyResults.first;
      return {
        ...w,
        '_type': w['category_id'] ?? 'words',
        '_searchedNicobarese': false,
      };
    }

    // 3. Search phrases
    final phraseResult = await searchPhrase(query);
    if (phraseResult != null) {
      return {
        ...phraseResult,
        '_type': 'phrases',
        '_searchedNicobarese': false,
      };
    }

    // 4. Search Great Andamanese dictionary
    final gaResults = await _db.searchGADictionary(query);
    if (gaResults.isNotEmpty) {
      final ga = gaResults.first;
      return {
        'english': ga['english'] ?? '',
        'nicobarese': ga['great_andamanese'] ?? '',
        '_type': 'great_andamanese',
        '_searchedNicobarese': false,
      };
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getRandomWords(int count) async {
    final words = await loadDictionary(DictionaryType.words);
    if (words.isEmpty) return [];

    final List<Map<String, dynamic>> shuffled = List.from(words)..shuffle(Random());
    return shuffled.take(count).toList();
  }

  Future<Map<String, dynamic>?> getDailyWord() async {
    final words = await loadDictionary(DictionaryType.words);
    if (words.isEmpty) return null;
    
    var now = DateTime.now();
    var seed = now.year * 10000 + now.month * 100 + now.day;
    var index = seed % words.length;
    
    return words[index];
  }

  Future<List<Map<String, dynamic>>> getWordsForLevel(int level) async {
    final words = await loadDictionary(DictionaryType.words);
    if (words.isEmpty) return [];

    int wordsPerLevel = 10;
    int startIndex = (level - 1) * wordsPerLevel;
    
    if (startIndex >= words.length) return [];
    
    int endIndex = startIndex + wordsPerLevel;
    if (endIndex > words.length) endIndex = words.length;

    return words.sublist(startIndex, endIndex);
  }

  Future<List<Map<String, dynamic>>> getDictionary(DictionaryType type) => loadDictionary(type);

  Future<List<Map<String, dynamic>>> getDialectItems() async {
    return loadDictionary(DictionaryType.dialects);
  }

  /// Direct English lookup — bypasses regional translation (for Neural Engine use)
  Future<String?> lookupExact(String word) async {
    final q = word.trim().toLowerCase();
    if (q.isEmpty) return null;
    final result = await _db.searchExact(q, 'words', ['english', 'nicobarese']);
    return result?['nicobarese']?.toString();
  }

  Future<Map<String, dynamic>?> translateSentence(String input) async {
    if (input.trim().isEmpty) return null;
    final String query = await _ensureEnglish(input.trim());
    
    final phraseMatch = await searchPhrase(query);
    if (phraseMatch != null) {
      return {
          'english': phraseMatch['text'] ?? phraseMatch['english'],
          'nicobarese': phraseMatch['nicobarese'],
          '_type': 'phrase',
          '_isExact': true
      };
    }

    final List<String> tokens = input.split(' ');
    List<String> translatedTokens = [];
    bool foundAtLeastOne = false;

    for (String token in tokens) {
        String cleanToken = token.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
        String punctuation = token.replaceAll(RegExp(r'[\w\s]'), '');
        
        final wordMatch = await searchWord(cleanToken);
        if (wordMatch != null) {
            translatedTokens.add((wordMatch['nicobarese'] ?? '') + punctuation);
            foundAtLeastOne = true;
        } else {
            translatedTokens.add(token); 
        }
    }

    if (foundAtLeastOne) {
        return {
            'english': input,
            'nicobarese': translatedTokens.join(' '),
            '_type': 'sentence',
            '_isGenerated': true
        };
    }

    return null;
  }
}
