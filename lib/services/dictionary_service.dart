import 'dart:math';
import 'package:speechmate/services/database_manager.dart';

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
    } else if (type == DictionaryType.words || type == DictionaryType.nature || type == DictionaryType.numbers) {
      // For general words
      return await _db.getWordsByCategory('words'); 
    } else {
      // animals, magic, family
      return await _db.getWordsByCategory(category);
    }
  }

  Future<void> unload(DictionaryType type) async {
    // No-op for SQLite, memory is handled by the DB engine
  }

  Future<Map<String, dynamic>?> searchWord(String query) async {
    return await _db.searchExact(query, 'words', ['english', 'nicobarese']);
  }

  Future<Map<String, dynamic>?> searchPhrase(String query) async {
    return await _db.searchExact(query, 'phrases', ['text', 'english']);
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
    final q = query.trim().toLowerCase();

    final wordResult = await searchWord(query);
    if (wordResult != null) {
      final isNicobarese = wordResult['nicobarese']?.toString().toLowerCase() == q;
      return {
        ...wordResult,
        '_type': 'words',
        '_searchedNicobarese': isNicobarese,
      };
    }

    final phraseResult = await searchPhrase(query);
    if (phraseResult != null) {
      return {
        ...phraseResult,
        '_type': 'phrases',
        '_searchedNicobarese': false,
      };
    }
    
    // Also search in Animals
    final animals = await getAnimalsItems();
    try {
      final animal = animals.firstWhere(
        (e) => (e['text'] ?? e['english']).toString().toLowerCase() == q,
      );
      return {
        ...animal,
        '_type': 'animals',
        'english': animal['text'] ?? animal['english'] ?? '',
        'nicobarese': animal['nicobarese'] ?? '',
        '_searchedNicobarese': false,
      };
    } catch (_) {}

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

  Future<String?> lookupExact(String word) async {
    final result = await searchWord(word);
    if (result != null) {
      return result['nicobarese'];
    }
    return null;
  }

  Future<Map<String, dynamic>?> translateSentence(String input) async {
    if (input.trim().isEmpty) return null;

    final String query = input.trim().toLowerCase();
    
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
