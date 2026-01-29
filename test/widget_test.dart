// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docscanner/main.dart';
import 'package:docscanner/providers/subscription_provider.dart';

void main() {
  testWidgets('Document Scanner app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final sub = SubscriptionProvider();
    await tester.pumpWidget(DocumentScannerApp(subscriptionProvider: sub));

    // Verify that our app loads with the splash screen
    expect(find.text('Document Scanner'), findsOneWidget);
  });
}
