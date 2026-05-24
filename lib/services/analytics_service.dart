import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Offline-first analytics service that stores all engagement metrics locally.
///
/// Designed to give investors verifiable usage data without any cloud dependency.
/// All data stays on-device, respecting SpeechMate's data sovereignty principles.
///
/// Usage:
/// ```dart
/// await AnalyticsService.instance.trackEvent('word_learned', properties: {'word': 'pōt'});
/// final report = await AnalyticsService.instance.exportAnalyticsJson();
/// ```
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._();
  AnalyticsService._();

  Database? _db;
  DateTime? _sessionStart;

  /// Initialize the analytics database. Call once at app startup.
  Future<void> init() async {
    if (_db != null) return;
    try {
      final dbPath = p.join(await getDatabasesPath(), 'speechmate_analytics.db');
      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              event_name TEXT NOT NULL,
              properties TEXT,
              timestamp TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_time TEXT NOT NULL,
              end_time TEXT,
              duration_seconds INTEGER
            )
          ''');
          await db.execute('CREATE INDEX idx_event_name ON events(event_name)');
          await db.execute('CREATE INDEX idx_event_ts ON events(timestamp)');
        },
      );
      _startSession();
      debugPrint('[AnalyticsService] Initialized analytics database');
    } catch (e) {
      debugPrint('[AnalyticsService] Init failed: $e');
    }
  }

  /// Track an event with optional properties.
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? properties}) async {
    if (_db == null) return;
    try {
      await _db!.insert('events', {
        'event_name': eventName,
        'properties': properties != null ? json.encode(properties) : null,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AnalyticsService] Track event failed: $e');
    }
  }

  /// Start a new session (called internally on init).
  void _startSession() {
    _sessionStart = DateTime.now();
    _db?.insert('sessions', {
      'start_time': _sessionStart!.toIso8601String(),
    });
  }

  /// End the current session. Call when app goes to background or closes.
  Future<void> endSession() async {
    if (_db == null || _sessionStart == null) return;
    try {
      final duration = DateTime.now().difference(_sessionStart!).inSeconds;
      await _db!.update(
        'sessions',
        {
          'end_time': DateTime.now().toIso8601String(),
          'duration_seconds': duration,
        },
        where: 'start_time = ?',
        whereArgs: [_sessionStart!.toIso8601String()],
      );
    } catch (e) {
      debugPrint('[AnalyticsService] End session failed: $e');
    }
  }

  /// Get total number of sessions.
  Future<int> getSessionCount() async {
    if (_db == null) return 0;
    try {
      final result = await _db!.rawQuery('SELECT COUNT(*) as count FROM sessions');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get average session duration in seconds.
  Future<double> getAverageSessionDuration() async {
    if (_db == null) return 0;
    try {
      final result = await _db!.rawQuery(
        'SELECT AVG(duration_seconds) as avg_dur FROM sessions WHERE duration_seconds IS NOT NULL'
      );
      final avg = result.first['avg_dur'];
      return (avg is num) ? avg.toDouble() : 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get the top 10 most-used features by event count.
  Future<List<Map<String, dynamic>>> getMostUsedFeatures() async {
    if (_db == null) return [];
    try {
      return await _db!.rawQuery('''
        SELECT event_name, COUNT(*) as count 
        FROM events 
        GROUP BY event_name 
        ORDER BY count DESC 
        LIMIT 10
      ''');
    } catch (e) {
      return [];
    }
  }

  /// Get total event count.
  Future<int> getTotalEvents() async {
    if (_db == null) return 0;
    try {
      final result = await _db!.rawQuery('SELECT COUNT(*) as count FROM events');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get events from the last N days.
  Future<List<Map<String, dynamic>>> getRecentEvents({int days = 7}) async {
    if (_db == null) return [];
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      return await _db!.query(
        'events',
        where: 'timestamp >= ?',
        whereArgs: [cutoff],
        orderBy: 'timestamp DESC',
        limit: 100,
      );
    } catch (e) {
      return [];
    }
  }

  /// Export a full analytics report as a JSON string for investor demos.
  Future<String> exportAnalyticsJson() async {
    final sessionCount = await getSessionCount();
    final avgDuration = await getAverageSessionDuration();
    final totalEvents = await getTotalEvents();
    final topFeatures = await getMostUsedFeatures();

    final report = {
      'app': 'SpeechMate',
      'version': '1.5.0',
      'report_generated': DateTime.now().toIso8601String(),
      'summary': {
        'total_sessions': sessionCount,
        'average_session_duration_seconds': avgDuration.round(),
        'total_events_tracked': totalEvents,
      },
      'top_features': topFeatures.map((f) => {
        'feature': f['event_name'],
        'usage_count': f['count'],
      }).toList(),
      'data_note': 'All analytics data is stored locally on-device. '
          'No data has been transmitted to any server.',
    };

    return const JsonEncoder.withIndent('  ').convert(report);
  }

  /// Clear all analytics data (for testing or privacy reset).
  Future<void> clearAll() async {
    if (_db == null) return;
    await _db!.delete('events');
    await _db!.delete('sessions');
  }
}
