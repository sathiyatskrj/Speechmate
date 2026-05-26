import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speechmate/services/dictionary_service.dart';

// ============================================================================
// WIDGET SERVICE — Android Home Screen Widget Data Bridge
// Updates SharedPreferences with Word of Day data for the native Android widget
// ============================================================================

class WidgetService {
  static const String _keyWidgetEnglish = 'widget_word_english';
  static const String _keyWidgetNicobarese = 'widget_word_nicobarese';
  static const String _keyWidgetDate = 'widget_word_date';
  static const String _keyWidgetCategory = 'widget_word_category';

  /// Update the home screen widget with today's word.
  /// Call this from main.dart on app launch and once daily.
  static Future<void> updateWordOfDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastDate = prefs.getString(_keyWidgetDate);

      // Only update if day has changed
      if (lastDate == today) return;

      // Get daily word from dictionary service
      final dictService = DictionaryService();
      final dailyWord = await dictService.getDailyWord();

      if (dailyWord != null) {
        await prefs.setString(_keyWidgetEnglish, dailyWord['english'] ?? '');
        await prefs.setString(_keyWidgetNicobarese, dailyWord['nicobarese'] ?? '');
        await prefs.setString(_keyWidgetCategory, dailyWord['category'] ?? 'general');
        await prefs.setString(_keyWidgetDate, today);

        // Trigger native widget update via MethodChannel
        // In production: HomeWidget.updateWidget(name: 'WordOfDayWidget');
        debugPrint('[WidgetService] Updated Word of Day: ${dailyWord['english']} → ${dailyWord['nicobarese']}');
      }
    } catch (e) {
      debugPrint('[WidgetService] Update error: $e');
    }
  }

  /// Get the current widget word data (for display in-app)
  static Future<Map<String, String>> getCurrentWidgetWord() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'english': prefs.getString(_keyWidgetEnglish) ?? 'Hello',
      'nicobarese': prefs.getString(_keyWidgetNicobarese) ?? 'Ä',
      'category': prefs.getString(_keyWidgetCategory) ?? 'general',
      'date': prefs.getString(_keyWidgetDate) ?? '',
    };
  }
}
