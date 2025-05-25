
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerformanceUtils {
  static bool _isMonitoring = false;
  static final List<Duration> _frameTimes = [];
  static VoidCallback? _onLowPerformance;

  static void startMonitoring({VoidCallback? onLowPerformance}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _onLowPerformance = onLowPerformance;
    _frameTimes.clear();

    SchedulerBinding.instance.addTimingsCallback(_onFrameTime);
  }

  static void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTime);
  }

  static void _onFrameTime(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameTime = timing.totalSpan;
      _frameTimes.add(frameTime);
      
      // Keep only last 60 frames (1 second at 60fps)
      if (_frameTimes.length > 60) {
        _frameTimes.removeAt(0);
      }
      
      // Check for low performance (frame time > 20ms = < 50fps)
      if (frameTime.inMilliseconds > 20) {
        _onLowPerformance?.call();
      }
    }
  }

  static double getCurrentFPS() {
    if (_frameTimes.isEmpty) return 60.0;
    
    final averageFrameTime = _frameTimes.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    ) ~/ _frameTimes.length;
    
    return 1000.0 / averageFrameTime.inMilliseconds;
  }

  static Map<String, dynamic> getPerformanceStats() {
    if (_frameTimes.isEmpty) {
      return {
        'fps': 60.0,
        'averageFrameTime': 16.67,
        'minFrameTime': 16.67,
        'maxFrameTime': 16.67,
        'frameCount': 0,
      };
    }

    final frameTimesMs = _frameTimes.map((t) => t.inMicroseconds / 1000.0).toList();
    final averageFrameTime = frameTimesMs.reduce((a, b) => a + b) / frameTimesMs.length;
    final minFrameTime = frameTimesMs.reduce((a, b) => a < b ? a : b);
    final maxFrameTime = frameTimesMs.reduce((a, b) => a > b ? a : b);

    return {
      'fps': 1000.0 / averageFrameTime,
      'averageFrameTime': averageFrameTime,
      'minFrameTime': minFrameTime,
      'maxFrameTime': maxFrameTime,
      'frameCount': _frameTimes.length,
    };
  }

  static void logPerformanceStats() {
    if (kDebugMode) {
      final stats = getPerformanceStats();
      print('Performance Stats:');
      print('  FPS: ${stats['fps']?.toStringAsFixed(1)}');
      print('  Avg Frame Time: ${stats['averageFrameTime']?.toStringAsFixed(2)}ms');
      print('  Min Frame Time: ${stats['minFrameTime']?.toStringAsFixed(2)}ms');
      print('  Max Frame Time: ${stats['maxFrameTime']?.toStringAsFixed(2)}ms');
      print('  Frame Count: ${stats['frameCount']}');
    }
  }

  static void measureAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      await operation();
      return;
    }

    final stopwatch = Stopwatch()..start();
    try {
      await operation();
    } finally {
      stopwatch.stop();
      print('$operationName took ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  static T measureSyncOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    if (!kDebugMode) {
      return operation();
    }

    final stopwatch = Stopwatch()..start();
    try {
      return operation();
    } finally {
      stopwatch.stop();
      print('$operationName took ${stopwatch.elapsedMilliseconds}ms');
    }
  }
}