import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DictionaryType { words, phrases, nature, numbers, animals, magic }

class ProgressService {
  static const String _searchCountKey = 'search_count';
  static const String _quizScoresKey = 'quiz_scores';
  static const String _streakKey = 'current_streak';
  static const String _lastActiveKey = 'last_active_date';
  static const String _wordsLearnedKey = 'words_learned';
  static const String _teacherLevelKey = 'teacher_level';

  Future<int> getTeacherLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_teacherLevelKey) ?? 1;
  }

  Future<void> unlockNextLevel(int completedLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt(_teacherLevelKey) ?? 1;
    if (completedLevel >= currentLevel) {
      await prefs.setInt(_teacherLevelKey, currentLevel + 1);
    }
  }

  Future<void> incrementSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_searchCountKey) ?? 0;
    await prefs.setInt(_searchCountKey, count + 1);
  }

  Future<int> getSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_searchCountKey) ?? 0;
  }

  Future<void> saveQuizScore(int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> scores = prefs.getStringList(_quizScoresKey) ?? [];
    scores.add('$score/$total');
    await prefs.setStringList(_quizScoresKey, scores);
  }

  Future<List<String>> getQuizScores() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_quizScoresKey) ?? [];
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastActiveStr = prefs.getString(_lastActiveKey);
    if (lastActiveStr == null) {
      await prefs.setInt(_streakKey, 1);
      await prefs.setString(_lastActiveKey, today.toIso8601String());
      return;
    }

    final lastActive = DateTime.parse(lastActiveStr);
    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final diff = today.difference(lastActiveDay).inDays;

    if (diff == 0) {
      return;
    } else if (diff == 1) {
      int streak = prefs.getInt(_streakKey) ?? 0;
      await prefs.setInt(_streakKey, streak + 1);
      await prefs.setString(_lastActiveKey, today.toIso8601String());
    } else {
      await prefs.setInt(_streakKey, 1);
      await prefs.setString(_lastActiveKey, today.toIso8601String());
    }
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  Future<void> markWordLearned(String word) async {
    final prefs = await SharedPreferences.getInstance();
    Set<String> learned = (prefs.getStringList(_wordsLearnedKey) ?? []).toSet();
    learned.add(word);
    await prefs.setStringList(_wordsLearnedKey, learned.toList());
  }

  Future<int> getWordsLearnedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_wordsLearnedKey) ?? []).length;
  }
}

class FavoritesService {
  static const String _key = 'favorites';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_key) ?? [];
    if (!favorites.contains(word)) {
      favorites.add(word);
      await prefs.setStringList(_key, favorites);
    }
  }

  Future<void> removeFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_key) ?? [];
    favorites.remove(word);
    await prefs.setStringList(_key, favorites);
  }

  Future<bool> isFavorite(String word) async {
    final favorites = await getFavorites();
    return favorites.contains(word);
  }
}

class HistoryService {
  static const String _key = 'history';
  static const int _maxHistory = 10;

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addToHistory(String word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    history.remove(word);
    history.insert(0, word);

    if (history.length > _maxHistory) {
      history = history.sublist(0, _maxHistory);
    }

    await prefs.setStringList(_key, history);
  }
}

class DictionaryService {
  final Map<DictionaryType, List<Map<String, dynamic>>> _cache = {};

  final Map<DictionaryType, String> _paths = {
    DictionaryType.words: 'assets/data/dictionary.json',
    DictionaryType.phrases: 'assets/data/dictionary_phrases.json',
    DictionaryType.animals: 'assets/data/dictionary_animals.json', // Added
    DictionaryType.magic: 'assets/data/dictionary_magic.json', // Added
  };

  Future<List<Map<String, dynamic>>> loadDictionary(DictionaryType type) async {
    if (_cache.containsKey(type)) {
      return _cache[type]!;
    }
    
    if (!_paths.containsKey(type)) return [];

    final String path = _paths[type]!;
    try {
      final List<Map<String, dynamic>> data = await _loadJson(path);
      _cache[type] = data;
      return data;
    } catch (e) {
      print("Warning: Could not load $type from $path: $e");
      return [];
    }
  }

  Future<void> loadMultiple(List<DictionaryType> types) async {
    await Future.wait(types.map((type) => loadDictionary(type)));
  }

  Future<void> loadAll() async {
    await loadMultiple(DictionaryType.values);
  }

  Future<List<Map<String, dynamic>>> _loadJson(String path) async {
    try {
      final String response = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(response);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  bool isLoaded(DictionaryType type) {
    return _cache.containsKey(type);
  }

  List<Map<String, dynamic>> getDictionary(DictionaryType type) {
    return _cache[type] ?? [];
  }

  void unload(DictionaryType type) {
    _cache.remove(type);
  }

  void unloadAll() {
    _cache.clear();
  }

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

  Future<Map<String, dynamic>?> searchPhrase(String query) async {
    final phrases = await loadDictionary(DictionaryType.phrases);
    final q = query.trim().toLowerCase();

    try {
      return phrases.firstWhere((e) => e['text'].toString().toLowerCase() == q);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNatureItems() async {
    return await loadDictionary(DictionaryType.nature);
  }

  Future<List<Map<String, dynamic>>> getNumberItems() async {
    return await loadDictionary(DictionaryType.numbers);
  }
  
  // Added getter for Animals
  Future<List<Map<String, dynamic>>> getAnimalsItems() async {
    return await loadDictionary(DictionaryType.animals);
  }

  // Added getter for Magic Words
  Future<List<Map<String, dynamic>>> getMagicWordsItems() async {
    return await loadDictionary(DictionaryType.magic);
  }

  Future<Map<String, dynamic>?> searchEverywhere(String query) async {
    final q = query.trim().toLowerCase();

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
      final animal = animals.firstWhere((e) => e['text'].toString().toLowerCase() == q);
      return {
        ...animal,
        '_type': 'animals',
        'english': animal['text'],
        'nicobarese': animal['nicobarese'],
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
    
    // Ensure we don't go out of bounds
    if (startIndex >= words.length) return [];
    
    int endIndex = startIndex + wordsPerLevel;
    if (endIndex > words.length) endIndex = words.length;

    return words.sublist(startIndex, endIndex);
  }
}
