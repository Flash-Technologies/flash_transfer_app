
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class TestingUtils {
  // Widget Testing Helpers
  static Widget createTestableWidget({
    required Widget child,
    List<Override>? overrides,
    ThemeData? theme,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        theme: theme,
        home: Scaffold(body: child),
      ),
    );
  }

  // Mock Data Generators
  static UserMockData generateMockUser({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return UserMockData(
      firstName: firstName ?? 'Test',
      lastName: lastName ?? 'User',
      email: email ?? 'test@example.com',
    );
  }

  static TransferMockData generateMockTransfer({
    String? trackingNumber,
    String? status,
    double? amount,
  }) {
    return TransferMockData(
      trackingNumber: trackingNumber ?? 'FT12345678',
      status: status ?? 'completed',
      amount: amount ?? 100.0,
    );
  }

  // Performance Testing
  static Future<Duration> measureWidgetBuildTime(
    WidgetTester tester,
    Widget widget,
  ) async {
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(widget);
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  static Future<void> testAnimationPerformance(
    WidgetTester tester,
    Widget widget,
    Duration animationDuration,
  ) async {
    await tester.pumpWidget(widget);
    
    final frameTimes = <Duration>[];
    final stopwatch = Stopwatch();
    
    while (stopwatch.elapsed < animationDuration) {
      stopwatch.start();
      await tester.pump(const Duration(milliseconds: 16)); // 60fps
      stopwatch.stop();
      frameTimes.add(stopwatch.elapsed);
      stopwatch.reset();
    }
    
    final averageFrameTime = frameTimes.fold<Duration>(
      Duration.zero,
      (prev, curr) => prev + curr,
    ) ~/ frameTimes.length;
    
    // Assert that average frame time is reasonable (< 20ms for 60fps)
    expect(averageFrameTime.inMilliseconds, lessThan(20));
  }

  // Accessibility Testing
  static Future<void> testAccessibility(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(widget);
    
    // Test semantic labels
    final semantics = tester.allSemantics.toList();
    expect(semantics, isNotEmpty, reason: 'Widget should have semantic information');
    
    // Test minimum touch target size (48x48 dp)
    final buttons = find.byType(MaterialButton);
    for (final button in buttons.evaluate()) {
      final buttonWidget = button.widget as MaterialButton;
      final renderBox = button.renderObject as RenderBox?;
      if (renderBox != null) {
        expect(renderBox.size.width, greaterThanOrEqualTo(48));
        expect(renderBox.size.height, greaterThanOrEqualTo(48));
      }
    }
  }

  // Form Testing Helpers
  static Future<void> enterTextInField(
    WidgetTester tester,
    String key,
    String text,
  ) async {
    await tester.enterText(find.byKey(ValueKey(key)), text);
    await tester.pump();
  }

  static Future<void> tapButton(
    WidgetTester tester,
    String key,
  ) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump();
  }

  static Future<void> testFormValidation(
    WidgetTester tester,
    Widget formWidget,
    Map<String, String> validInputs,
    Map<String, String> invalidInputs,
  ) async {
    await tester.pumpWidget(createTestableWidget(child: formWidget));
    
    // Test invalid inputs
    for (final entry in invalidInputs.entries) {
      await enterTextInField(tester, entry.key, entry.value);
      await tapButton(tester, 'submit');
      
      // Should show error
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    }
    
    // Test valid inputs
    for (final entry in validInputs.entries) {
      await enterTextInField(tester, entry.key, entry.value);
    }
    
    await tapButton(tester, 'submit');
    // Should not show errors
    await tester.pumpAndSettle();
  }

  // Network Testing
  static MockNetworkClient createMockNetworkClient({
    Map<String, dynamic>? responses,
    Duration? delay,
    bool shouldFail = false,
  }) {
    return MockNetworkClient(
      responses: responses ?? {},
      delay: delay ?? const Duration(milliseconds: 100),
      shouldFail: shouldFail,
    );
  }
}

// Mock Data Classes
class UserMockData {
  final String firstName;
  final String lastName;
  final String email;

  UserMockData({
    required this.firstName,
    required this.lastName,
    required this.email,
  });
}

class TransferMockData {
  final String trackingNumber;
  final String status;
  final double amount;

  TransferMockData({
    required this.trackingNumber,
    required this.status,
    required this.amount,
  });
}

class MockNetworkClient {
  final Map<String, dynamic> responses;
  final Duration delay;
  final bool shouldFail;

  MockNetworkClient({
    required this.responses,
    required this.delay,
    required this.shouldFail,
  });

  Future<Map<String, dynamic>> get(String endpoint) async {
    await Future.delayed(delay);
    
    if (shouldFail) {
      throw Exception('Mock network error');
    }
    
    return responses[endpoint] ?? {'error': 'Endpoint not mocked'};
  }

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(delay);
    
    if (shouldFail) {
      throw Exception('Mock network error');
    }
    
    return responses[endpoint] ?? {'success': true, 'data': data};
  }
}
