
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class MemoryUtils {
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      developer.Service.getInfo().then((info) {
        print('Memory Usage in $context:');
        print('  Heap Used: ${info.serverWebSocket}');
      });
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
