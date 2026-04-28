import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Offline feedback service — stores feedback locally using SharedPreferences.
/// Will be upgraded to Firebase Firestore post-proposal/demo.
class FeedbackService {
  static const String _feedbackKey = 'user_feedback_v1';

  Future<void> submitFeedback({
    required double rating,
    required String category,
    required String feedbackText,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_feedbackKey) ?? [];
      
      final feedback = {
        'rating': rating,
        'category': category,
        'feedbackText': feedbackText,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.toString(),
      };
      
      existing.add(jsonEncode(feedback));
      await prefs.setStringList(_feedbackKey, existing);
      debugPrint('[FeedbackService] Feedback saved locally (${existing.length} total)');
    } catch (e) {
      debugPrint("Error saving feedback: $e");
      throw Exception("Failed to save feedback");
    }
  }

  /// Get all locally stored feedback entries
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_feedbackKey) ?? [];
    return raw.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (e) { debugPrint("Silent error caught: $e");
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
  }
}
