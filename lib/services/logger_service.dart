import 'package:flutter/foundation.dart';

/// Centralized logging service for the application
/// Replaces all print() statements with proper logging
class LoggerService {
  static const String _tag = 'Speechmate';
  
  /// Log debug messages (development only)
  static void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      debugPrint('[$_tag][DEBUG] $message${data != null ? ': $data' : ''}');
    }
  }
  
  /// Log informational messages
  static void info(String message, [dynamic data]) {
    if (kDebugMode) {
      debugPrint('[$_tag][INFO] $message${data != null ? ': $data' : ''}');
    }
  }
  
  /// Log warning messages
  static void warning(String message, [dynamic data]) {
    debugPrint('[$_tag][WARNING] $message${data != null ? ': $data' : ''}');
  }
  
  /// Log error messages
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint('[$_tag][ERROR] $message${error != null ? ': $error' : ''}');
    if (stackTrace != null && kDebugMode) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
