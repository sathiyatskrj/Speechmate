import 'dart:io';
import 'package:flutter/foundation.dart';

/// M4-04: Local crash reporter for field debugging (no cloud dependency).
/// Writes crash logs to app's local storage for later retrieval.
class CrashReporter {
  static File? _logFile;

  static Future<void> init(String appDocPath) async {
    _logFile = File('$appDocPath/crash_log.txt');
    if (!_logFile!.existsSync()) {
      await _logFile!.create(recursive: true);
    }
  }

  static Future<void> log(String error, {StackTrace? stack}) async {
    if (_logFile == null) return;
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $error\n${stack ?? ''}\n---\n';
    try {
      await _logFile!.writeAsString(entry, mode: FileMode.append);
    } catch (e) {
      debugPrint('[CrashReporter] Write failed: $e');
    }
  }

  static Future<String> readLog() async {
    if (_logFile == null || !_logFile!.existsSync()) return 'No crash logs.';
    return await _logFile!.readAsString();
  }

  static Future<void> clearLog() async {
    if (_logFile != null && _logFile!.existsSync()) {
      await _logFile!.writeAsString('');
    }
  }
}
