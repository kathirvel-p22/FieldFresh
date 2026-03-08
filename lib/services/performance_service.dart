import 'package:flutter/foundation.dart';

class PerformanceService {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<int>> _metrics = {};

  // Start tracking an operation
  static void startTrace(String traceName) {
    _startTimes[traceName] = DateTime.now();
  }

  // Stop tracking and log duration
  static void stopTrace(String traceName) {
    if (_startTimes.containsKey(traceName)) {
      final duration = DateTime.now().difference(_startTimes[traceName]!);
      final milliseconds = duration.inMilliseconds;
      
      if (!_metrics.containsKey(traceName)) {
        _metrics[traceName] = [];
      }
      _metrics[traceName]!.add(milliseconds);
      
      if (kDebugMode) {
        print('⏱️ $traceName: ${milliseconds}ms');
      }
      
      _startTimes.remove(traceName);
    }
  }

  // Get average duration for a trace
  static double getAverageDuration(String traceName) {
    if (!_metrics.containsKey(traceName) || _metrics[traceName]!.isEmpty) {
      return 0;
    }
    final sum = _metrics[traceName]!.reduce((a, b) => a + b);
    return sum / _metrics[traceName]!.length;
  }

  // Get all metrics
  static Map<String, double> getAllMetrics() {
    final result = <String, double>{};
    for (final entry in _metrics.entries) {
      if (entry.value.isNotEmpty) {
        final sum = entry.value.reduce((a, b) => a + b);
        result[entry.key] = sum / entry.value.length;
      }
    }
    return result;
  }

  // Clear metrics
  static void clearMetrics() {
    _metrics.clear();
    _startTimes.clear();
  }

  // Log slow operations
  static void logSlowOperation(String operation, int durationMs) {
    if (durationMs > 1000) {
      if (kDebugMode) {
        print('🐌 Slow operation detected: $operation took ${durationMs}ms');
      }
    }
  }

  // Measure async operation
  static Future<T> measureAsync<T>(
    String traceName,
    Future<T> Function() operation,
  ) async {
    startTrace(traceName);
    try {
      final result = await operation();
      stopTrace(traceName);
      return result;
    } catch (e) {
      stopTrace(traceName);
      rethrow;
    }
  }

  // Measure sync operation
  static T measureSync<T>(
    String traceName,
    T Function() operation,
  ) {
    startTrace(traceName);
    try {
      final result = operation();
      stopTrace(traceName);
      return result;
    } catch (e) {
      stopTrace(traceName);
      rethrow;
    }
  }
}
