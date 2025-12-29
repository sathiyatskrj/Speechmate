import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _keySearchCount = 'search_count';
  static const String _keyStreak = 'current_streak';
  static const String _keyWordsLearned = 'words_learned';
  static const String _keyQuizScores = 'quiz_scores';
  static const String _keyTeacherLevel = 'teacher_level';

  // --- Getters ---

  Future<int> getSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySearchCount) ?? 0;
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  Future<int> getWordsLearnedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWordsLearned) ?? 0;
  }

  Future<List<String>> getQuizScores() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyQuizScores) ?? [];
  }

  Future<int> getTeacherLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTeacherLevel) ?? 1;
  }

  // --- Actions ---

  Future<void> incrementSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keySearchCount) ?? 0;
    await prefs.setInt(_keySearchCount, current + 1);
  }

  Future<void> incrementWordsLearned() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyWordsLearned) ?? 0;
    await prefs.setInt(_keyWordsLearned, current + 1);
  }

  Future<void> addQuizScore(String score) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> scores = prefs.getStringList(_keyQuizScores) ?? [];
    scores.add(score);
    await prefs.setStringList(_keyQuizScores, scores);
  }

  Future<void> unlockTeacherLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_keyTeacherLevel) ?? 1;
    if (level > current) {
      await prefs.setInt(_keyTeacherLevel, level);
    }
  }

  Future<void> unlockNextLevel(int completedLevel) async {
    await unlockTeacherLevel(completedLevel + 1);
  }
}
