import 'package:flutter/foundation.dart';

/// Production-grade logging service with severity levels and module tagging.
/// Replaces scattered debugPrint calls and silent catch(_){} blocks.
///
/// Usage:
/// ```dart
/// final _log = Log('VoiceTranslator');
/// _log.info('Recording started');
/// _log.error('Whisper failed', error);
/// _log.warn('Fallback to hardcoded words');
/// ```
enum LogLevel { debug, info, warn, error, fatal }

class Log {
  final String module;
  static LogLevel minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.warn;
  
  // In-memory log buffer for crash reports (last 200 entries)
  static final List<_LogEntry> _buffer = [];
  static const int _maxBuffer = 200;

  const Log(this.module);

  void debug(String message) => _log(LogLevel.debug, message);
  void info(String message) => _log(LogLevel.info, message);
  void warn(String message, [Object? error]) => _log(LogLevel.warn, message, error);
  void error(String message, [Object? error, StackTrace? stack]) => _log(LogLevel.error, message, error, stack);
  void fatal(String message, [Object? error, StackTrace? stack]) => _log(LogLevel.fatal, message, error, stack);

  void _log(LogLevel level, String message, [Object? error, StackTrace? stack]) {
    if (level.index < minimumLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final prefix = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info  => '✅',
      LogLevel.warn  => '⚠️',
      LogLevel.error => '❌',
      LogLevel.fatal => '💀',
    };

    final entry = '$prefix [$timestamp] [$module] $message';
    debugPrint(entry);
    if (error != null) debugPrint('  → Error: $error');
    if (stack != null) debugPrint('  → Stack: ${stack.toString().split('\n').take(3).join('\n')}');

    // Buffer for crash reports
    _buffer.add(_LogEntry(level, module, message, error, DateTime.now()));
    if (_buffer.length > _maxBuffer) _buffer.removeAt(0);
  }

  /// Get recent logs for crash reporting
  static List<String> getRecentLogs({LogLevel? minLevel}) {
    final filtered = minLevel != null 
      ? _buffer.where((e) => e.level.index >= minLevel.index)
      : _buffer;
    return filtered.map((e) => '[${e.timestamp.toIso8601String()}] [${e.module}] ${e.message}').toList();
  }

  /// Clear log buffer
  static void clear() => _buffer.clear();
}

class _LogEntry {
  final LogLevel level;
  final String module;
  final String message;
  final Object? error;
  final DateTime timestamp;
  
  const _LogEntry(this.level, this.module, this.message, this.error, this.timestamp);
}
