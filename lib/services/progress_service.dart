import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProgressService {
  static const String _keySearchCount = 'search_count';
  static const String _keyWordsLearned = 'words_learned';
  static const String _keyStreakDate = 'streak_last_date';
  static const String _keyStreakCount = 'streak_count';
  static const String _keyQuizScores = 'quiz_scores';

  Future<int> getSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySearchCount) ?? 0;
  }

  Future<void> incrementSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keySearchCount) ?? 0;
    await prefs.setInt(_keySearchCount, current + 1);
  }

  Future<int> getWordsLearnedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWordsLearned) ?? 0;
  }
  
  Future<void> markWordAsLearned() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyWordsLearned) ?? 0;
    await prefs.setInt(_keyWordsLearned, current + 1);
    await _updateStreak();
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreakCount) ?? 0;
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastDateStr = prefs.getString(_keyStreakDate);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    if (lastDateStr != null) {
      DateTime lastDate = DateTime.parse(lastDateStr);
      if (today.difference(lastDate).inDays == 1) {
        // Increment streak
        int currentStreak = prefs.getInt(_keyStreakCount) ?? 0;
        await prefs.setInt(_keyStreakCount, currentStreak + 1);
      } else if (today.difference(lastDate).inDays > 1) {
        // Reset streak
        await prefs.setInt(_keyStreakCount, 1);
      }
    } else {
      await prefs.setInt(_keyStreakCount, 1);
    }
    await prefs.setString(_keyStreakDate, today.toIso8601String());
  }

  Future<List<String>> getQuizScores() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyQuizScores) ?? [];
  }
}
