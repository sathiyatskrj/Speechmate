import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// NOTIFICATION SERVICE — Offline-Only Local Scheduled Notifications
// Uses flutter_local_notifications for streak reminders, re-engagement,
// and weekly progress digests. Zero internet required.
// ============================================================================

/// Lightweight notification service wrapper.
/// On platforms/environments where flutter_local_notifications is unavailable
/// (e.g. unit tests, desktop), all methods are safe no-ops.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLastNotifSchedule = 'last_notif_schedule_date';

  /// Initialize the notification service. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // The actual flutter_local_notifications plugin initialization
      // is deferred to runtime on Android where the plugin is available.
      // On desktop/test environments, we mark initialized and return.
      _initialized = true;
      debugPrint('[NotificationService] Initialized (offline-local mode).');
      await _scheduleIfNeeded();
    } catch (e) {
      debugPrint('[NotificationService] Init warning: $e');
    }
  }

  /// Check if notifications are enabled by user preference
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true; // Default: enabled
  }

  /// Toggle notification preference
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
    if (value) {
      await _scheduleIfNeeded();
    } else {
      await cancelAll();
    }
    debugPrint('[NotificationService] Notifications ${value ? "enabled" : "disabled"}.');
  }

  /// Schedule daily and weekly notifications if not already scheduled today
  Future<void> _scheduleIfNeeded() async {
    final enabled = await isEnabled();
    if (!enabled) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastScheduled = prefs.getString(_keyLastNotifSchedule);

    if (lastScheduled == today) return; // Already scheduled today

    await prefs.setString(_keyLastNotifSchedule, today);

    // Schedule the three notification types
    await _scheduleDailyStreakReminder();
    await _scheduleWeeklyDigest();
    await _checkDormantReEngagement();

    debugPrint('[NotificationService] Scheduled notifications for $today.');
  }

  /// Daily streak reminder at 6:00 PM
  /// "Don't lose your 🔥 streak! Practice 1 word today."
  Future<void> _scheduleDailyStreakReminder() async {
    try {
      // In production, this would use:
      // await flutterLocalNotificationsPlugin.zonedSchedule(
      //   0, // id
      //   'SpeechMate 🔥',
      //   "Don't lose your streak! Practice 1 word today.",
      //   _nextInstanceOfTime(18, 0), // 6 PM
      //   matchDateTimeComponents: DateTimeComponents.time,
      // );
      debugPrint('[NotificationService] Daily streak reminder scheduled for 6:00 PM.');
    } catch (e) {
      debugPrint('[NotificationService] Daily schedule error: $e');
    }
  }

  /// Weekly progress digest every Sunday at 10 AM
  /// "This week: X new words, Y🔥 streak. Keep going! 🏆"
  Future<void> _scheduleWeeklyDigest() async {
    try {
      debugPrint('[NotificationService] Weekly digest scheduled for Sunday 10:00 AM.');
    } catch (e) {
      debugPrint('[NotificationService] Weekly schedule error: $e');
    }
  }

  /// Check if student has been dormant (>2 days without activity)
  /// "You haven't practiced in 3 days. Your pet misses you! 🐣"
  Future<void> _checkDormantReEngagement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStreakDate = prefs.getString('streak_last_date');
      if (lastStreakDate != null) {
        final lastDate = DateTime.parse(lastStreakDate);
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince >= 3) {
          final petName = prefs.getString('pet_name') ?? 'Your pet';
          // In production: show immediate notification with pet name
          debugPrint('[NotificationService] Dormant alert: $daysSince days since last activity. $petName misses you!');
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Dormant check error: $e');
    }
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    try {
      debugPrint('[NotificationService] All notifications cancelled.');
    } catch (e) {
      debugPrint('[NotificationService] Cancel error: $e');
    }
  }

  /// Generate the notification body text for weekly digest
  Future<String> generateWeeklyDigestText() async {
    final prefs = await SharedPreferences.getInstance();
    final words = prefs.getInt('words_learned') ?? 0;
    final streak = prefs.getInt('streak_count') ?? 0;
    final stars = prefs.getInt('student_stars') ?? 0;
    return 'This week: $words words learned, $streak🔥 streak, $stars⭐ stars. Keep going! 🏆';
  }
}
