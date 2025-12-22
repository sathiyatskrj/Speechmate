import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _searchCountKey = 'search_count';
  static const String _lastStreakKey = 'last_streak_date';
  static const String _streakCountKey = 'streak_count';

  Future<int> getSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_searchCountKey) ?? 0;
  }

  Future<void> incrementSearchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSearchCount();
    await prefs.setInt(_searchCountKey, current + 1);
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastStreakKey);
    
    if (lastDate == today) {
      return;
    }
    
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    
    if (lastDate == yesterday) {
      final current = await getStreak();
      await prefs.setInt(_streakCountKey, current + 1);
    } else {
      await prefs.setInt(_streakCountKey, 1);
    }
    
    await prefs.setString(_lastStreakKey, today);
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchCountKey);
    await prefs.remove(_lastStreakKey);
    await prefs.remove(_streakCountKey);
  }
}
