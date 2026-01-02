import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SmartQuizService {
  static const String _missedKey = 'smart_quiz_missed';

  Future<void> markMissed(Map<String, dynamic> word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> missed = prefs.getStringList(_missedKey) ?? [];
    
    String jsonWord = jsonEncode(word);
    if (!missed.contains(jsonWord)) {
      missed.add(jsonWord);
      await prefs.setStringList(_missedKey, missed);
    }
  }

  Future<void> markCorrect(Map<String, dynamic> word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> missed = prefs.getStringList(_missedKey) ?? [];
    
    String jsonWord = jsonEncode(word);
    if (missed.contains(jsonWord)) {
      missed.remove(jsonWord); // Remove from "missed" list if clarified
      await prefs.setStringList(_missedKey, missed);
    }
  }

  Future<List<Map<String, dynamic>>> getMissedWords() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> missed = prefs.getStringList(_missedKey) ?? [];
    return missed.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}
