import 'dart:convert';
import 'package:flutter/services.dart';

enum DictionaryType { words, phrases, nature, numbers }

class DictionaryService {
  // Cache for loaded dictionaries
  final Map<DictionaryType, List<Map<String, dynamic>>> _cache = {};

  // Mapping of dictionary types to file paths
  final Map<DictionaryType, String> _paths = {
    DictionaryType.words: 'assets/data/dictionary.json',
    DictionaryType.phrases: 'assets/data/dictionary_phrases.json',
  };

  /// Load a specific dictionary on-demand
  Future<List<Map<String, dynamic>>> loadDictionary(DictionaryType type) async {
    if (_cache.containsKey(type)) {
      return _cache[type]!;
    }

    final String path = _paths[type]!;
    final List<Map<String, dynamic>> data = await _loadJson(path);

    _cache[type] = data;
    return data;
  }

  /// Load multiple dictionaries at once
  Future<void> loadMultiple(List<DictionaryType> types) async {
    await Future.wait(types.map((type) => loadDictionary(type)));
  }

  /// Load all dictionaries
  Future<void> loadAll() async {
    await loadMultiple(DictionaryType.values);
  }

  /// Internal helper to load a JSON file
  Future<List<Map<String, dynamic>>> _loadJson(String path) async {
    final String response = await rootBundle.loadString(path);
    final List<dynamic> data = json.decode(response);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Check if a dictionary is loaded
  bool isLoaded(DictionaryType type) {
    return _cache.containsKey(type);
  }

  /// Get a loaded dictionary
  List<Map<String, dynamic>> getDictionary(DictionaryType type) {
    return _cache[type] ?? [];
  }

  /// Clear a specific dictionary from cache
  void unload(DictionaryType type) {
    _cache.remove(type);
  }

  /// Clear all dictionaries from cache
  void unloadAll() {
    _cache.clear();
  }

  /// 🔁 TWO-WAY search in WORDS dictionary (English <-> Nicobarese)
  Future<Map<String, dynamic>?> searchWord(String query) async {
    final words = await loadDictionary(DictionaryType.words);
    final q = query.trim().toLowerCase();

    try {
      return words.firstWhere((e) {
        final english = e['english']?.toString().toLowerCase() ?? '';
        final nicobarese = e['nicobarese']?.toString().toLowerCase() ?? '';
        return english == q || nicobarese == q;
      });
    } catch (_) {
      return null;
    }
  }

  /// Search in PHRASES dictionary (unchanged)
  Future<Map<String, dynamic>?> searchPhrase(String query) async {
    final phrases = await loadDictionary(DictionaryType.phrases);
    final q = query.trim().toLowerCase();

    try {
      return phrases.firstWhere((e) => e['text'].toString().toLowerCase() == q);
    } catch (_) {
      return null;
    }
  }

  /// Get all nature items
  Future<List<Map<String, dynamic>>> getNatureItems() async {
    return await loadDictionary(DictionaryType.nature);
  }

  /// Get all number items
  Future<List<Map<String, dynamic>>> getNumberItems() async {
    return await loadDictionary(DictionaryType.numbers);
  }

  /// Universal search (words first, then phrases)
  Future<Map<String, dynamic>?> searchEverywhere(String query) async {
    final q = query.trim().toLowerCase();

    // 1️⃣ Try WORDS first
    final wordResult = await searchWord(query);
    if (wordResult != null) {
      final isNicobarese =
          wordResult['nicobarese'].toString().toLowerCase() == q;

      return {
        ...wordResult,
        '_type': 'words',
        '_searchedNicobarese': isNicobarese,
      };
    }

    // 2️⃣ Try PHRASES
    final phraseResult = await searchPhrase(query);
    if (phraseResult != null) {
      return {
        ...phraseResult,
        '_type': 'phrases',
        '_searchedNicobarese': false, // phrases are one-way
      };
    }

    return null;
  }
}
