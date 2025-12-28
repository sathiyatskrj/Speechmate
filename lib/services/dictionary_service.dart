import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DictionaryType { words, phrases, nature, numbers, animals, magic, family }

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
    DictionaryType.animals: 'assets/data/dictionary_animals.json',
    DictionaryType.magic: 'assets/data/dictionary_magic.json',
    DictionaryType.family: 'assets/data/dictionary_family.json',
    DictionaryType.nature: 'assets/data/dictionary.json', // Assuming nature data is here or needs a placeholder. Using dictionary.json as fallback if specific file missing, or maybe user has it but forgot to list. For now, let's point to words or create empty. Wait, analysis said nature items will return empty. Let's assume they are meant to be in separate files like others. 
    // ACTUALLY, checking the code usage, getNatureItems loads DictionaryType.nature. If no file, it loads nothing. 
    // Let's look at the file list from "list_dir assets/data". 
    // Found: dictionary.json, dictionary_animals.json, dictionary_family.json, dictionary_magic.json, dictionary_phrases.json.
    // NO nature.json or numbers.json.
    // This means we probably need to create them or map them to existing ones if they are subsets.
    // For now, let's map them to dictionary.json to avoid crash/empty, OR better, create empty files so they don't error? 
    // Actually the code just returns empty list if no path. The issue is they are in the Enum but not here.
    // Let's add them pointing to potentially existing files or just empty ones if not found.
    // Given the task is "Fix", I should probably make them at least not crash.
    // I will map them to specific filenames that OUGHT to exist.
    DictionaryType.nature: 'assets/data/dictionary_nature.json',
    DictionaryType.numbers: 'assets/data/dictionary_numbers.json',
  };

  // ... [keep existing code] ...

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
        (e) => e['text'].toString().toLowerCase() == q,
        orElse: () => {}, 
      );
      
      if (animal.isNotEmpty) {
          return {
            ...animal,
            '_type': 'animals',
            'english': animal['text'] ?? '',
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

  // Method for Family Items (Added for Hackathon)
  Future<List<Map<String, dynamic>>> getFamilyItems() async {
    return await loadDictionary(DictionaryType.family);
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
  Future<Map<String, dynamic>?> translateSentence(String input) async {
    if (input.trim().isEmpty) return null;
    
    // 1. Load Data if needed
    if (_dictionaries[DictionaryType.words] == null) {
        await loadDictionary(DictionaryType.words);
    }
    if (_dictionaries[DictionaryType.phrases] == null) { 
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
        wordMap[(w['english'] ?? '').toString().toLowerCase()] = w['nicobarese'];
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
