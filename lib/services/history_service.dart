import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _key = 'search_history';
  static const int maxHistory = 10;

  Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addToHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Remove if already exists
    history.remove(query);
    
    // Add to beginning
    history.insert(0, query);
    
    // Keep only last maxHistory items
    if (history.length > maxHistory) {
      history.removeRange(maxHistory, history.length);
    }
    
    await prefs.setStringList(_key, history);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
