import 'package:flutter/material.dart';

/// SafeState mixin — prevents setState crashes after dispose.
/// Replaces manual `if (!mounted) return;` checks across 137+ call sites.
///
/// Usage: `class _MyState extends State<MyWidget> with SafeStateMixin`
/// Then call `safeSetState(() { ... })` instead of `setState(() { ... })`
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Safe version of setState that checks `mounted` before calling.
  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /// Runs an async operation and calls safeSetState with the result.
  /// Automatically handles loading state.
  Future<void> safeAsync({
    required Future<void> Function() operation,
    VoidCallback? onStart,
    VoidCallback? onComplete,
    void Function(Object error)? onError,
  }) async {
    if (onStart != null) safeSetState(onStart);
    try {
      await operation();
      if (onComplete != null) safeSetState(onComplete);
    } catch (e) {
      if (onError != null) {
        safeSetState(() => onError(e));
      } else {
        debugPrint('[SafeState] Unhandled async error: $e');
      }
    }
  }
}
