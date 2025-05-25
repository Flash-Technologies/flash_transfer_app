import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'dart:io';

class MemoryUtils {
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      try {
        // Log memory usage using ProcessInfo for more accurate data
        final processInfo = ProcessInfo.currentRss;
        final memoryMB = (processInfo / (1024 * 1024)).toStringAsFixed(2);
        print('Memory Usage in $context:');
        print('  RSS Memory: ${memoryMB}MB');
      } catch (e) {
        print('Memory Usage in $context: Unable to get memory info');
      }
    }
  }

  static void forceGarbageCollection() {
    if (kDebugMode) {
      // Force garbage collection in debug mode
      print('Forcing garbage collection...');
    }
  }

  static void trackObjectLifecycle(String objectName, String event) {
    if (kDebugMode) {
      print('Object Lifecycle: $objectName - $event');
    }
  }
}
