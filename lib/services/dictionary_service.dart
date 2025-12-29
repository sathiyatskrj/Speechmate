import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DictionaryType { words, phrases, nature, numbers, animals, magic, family }

class DictionaryService {
  final Map<DictionaryType, List<Map<String, dynamic>>> _dictionaries = {};

  final Map<DictionaryType, String> _paths = {
    DictionaryType.words: 'assets/data/dictionary.json',
    DictionaryType.phrases: 'assets/data/dictionary_phrases.json',
    DictionaryType.animals: 'assets/data/dictionary_animals.json',
    DictionaryType.magic: 'assets/data/dictionary_magic.json',
    DictionaryType.family: 'assets/data/dictionary_family.json',
    DictionaryType.nature: 'assets/data/dictionary.json', // Reuse main dict
    DictionaryType.numbers: 'assets/data/dictionary.json', // Reuse main dict
  };

  Future<List<Map<String, dynamic>>> loadDictionary(DictionaryType type) async {
    if (_dictionaries.containsKey(type)) {
      return _dictionaries[type]!;
    }

    try {
      final path = _paths[type];
      if (path == null) return [];

      final String jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(jsonList);
      
      _dictionaries[type] = items;
      return items;
    } catch (e) {
      print("Error loading dictionary $type: $e");
      return [];
    }
  }

  Future<void> unload(DictionaryType type) async {
    _dictionaries.remove(type);
  }

  Future<Map<String, dynamic>?> searchWord(String query) async {
    final words = await loadDictionary(DictionaryType.words);
    final q = query.trim().toLowerCase();
    
    try {
      return words.firstWhere((w) {
         return (w['english']?.toString().toLowerCase() == q) ||
                (w['nicobarese']?.toString().toLowerCase() == q);
      });
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> searchPhrase(String query) async {
    final phrases = await loadDictionary(DictionaryType.phrases);
    final q = query.trim().toLowerCase();

    try {
      return phrases.firstWhere((p) {
         return (p['text']?.toString().toLowerCase() == q) || 
                (p['english']?.toString().toLowerCase() == q);
      });
    } catch (e) {
      return null; 
    }
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
      final isNicobarese =
          wordResult['nicobarese']?.toString().toLowerCase() == q;

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
    
    // Also search in Animals for completeness
    try {
      final animals = await getAnimalsItems();
      final animal = animals.firstWhere(
        (e) => (e['text'] ?? e['english']).toString().toLowerCase() == q,
        orElse: () => {}, 
      );
      
      if (animal.isNotEmpty) {
          return {
            ...animal,
            '_type': 'animals',
            'english': animal['text'] ?? animal['english'] ?? '',
            'nicobarese': animal['nicobarese'] ?? '',
            '_searchedNicobarese': false,
          };
      }
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
    
    // Ensure we don't go out of bounds
    if (startIndex >= words.length) return [];
    
    int endIndex = startIndex + wordsPerLevel;
    if (endIndex > words.length) endIndex = words.length;

    return words.sublist(startIndex, endIndex);
  }

  Future<List<Map<String, dynamic>>> getDictionary(DictionaryType type) => loadDictionary(type);

  Future<Map<String, dynamic>?> translateSentence(String input) async {
    if (input.trim().isEmpty) return null;
    
    // 1. Load Data if needed
    if (!_dictionaries.containsKey(DictionaryType.words)) {
        await loadDictionary(DictionaryType.words);
    }
    if (!_dictionaries.containsKey(DictionaryType.phrases)) { 
        await loadDictionary(DictionaryType.phrases);
    }

    final String query = input.trim().toLowerCase();
    
    // 2. CHECK EXACT PHRASE MATCH FIRST 
    final phrases = _dictionaries[DictionaryType.phrases] ?? [];
    for (var phrase in phrases) {
       final eng = (phrase['text'] ?? phrase['english'] ?? '').toString().toLowerCase();
       if (eng == query) {
           return {
               'english': phrase['text'] ?? phrase['english'],
               'nicobarese': phrase['nicobarese'],
               '_type': 'phrase',
               '_isExact': true
           };
       }
    }

    // 3. WORD-BY-WORD TRANSLATION
    final List<String> tokens = input.split(' ');
    List<String> translatedTokens = [];
    bool foundAtLeastOne = false;

    final words = _dictionaries[DictionaryType.words] ?? [];
    final Map<String, String> wordMap = {};
    for (var w in words) {
        wordMap[(w['english'] ?? '').toString().toLowerCase()] = w['nicobarese'] ?? '';
    }

    for (String token in tokens) {
        String cleanToken = token.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
        String punctuation = token.replaceAll(RegExp(r'[\w\s]'), '');
        
        if (wordMap.containsKey(cleanToken)) {
            translatedTokens.add(wordMap[cleanToken]! + punctuation);
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
