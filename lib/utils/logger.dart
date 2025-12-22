import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging
/// In production, prints are disabled automatically by Flutter
class AppLogger {
  static void log(String message, {String tag = 'ServiceLink'}) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void error(String message, {String tag = 'ServiceLink', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint('[$tag ERROR] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void info(String message, {String tag = 'ServiceLink'}) {
    if (kDebugMode) {
      debugPrint('[$tag INFO] $message');
    }
  }

  static void warning(String message, {String tag = 'ServiceLink'}) {
    if (kDebugMode) {
      debugPrint('[$tag WARNING] $message');
    }
  }
}
