import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/screens/paywall_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('purchases_flutter'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('purchases_flutter'),
      null,
    );
  });

  group('PaywallScreen Widget Tests', () {
    testWidgets('renders paywall screen with headline, feature comparison, and CTA',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaywallScreen(autoPresentRevenueCatPaywall: false),
        ),
      );

      // Pump to process async loading and setState
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify title & badges
      expect(find.text('⚡ UNLOCK PRO ACCESS'), findsOneWidget);
      expect(find.text('SleekScan Pro'), findsOneWidget);

      // Verify Feature Comparison Table headers
      expect(find.text('Feature'), findsOneWidget);
      expect(find.text('Free Plan'), findsOneWidget);
      expect(find.text('Pro Plan'), findsOneWidget);

      // Verify core feature differentiators
      expect(find.text('Cloud Sync (Supabase)'), findsOneWidget);
      expect(find.text('PDF Watermark'), findsOneWidget);
      expect(find.text('AES-128 Password Lock'), findsOneWidget);
      expect(find.text('Batch Scanning'), findsOneWidget);

      // Verify Restore option exists in AppBar
      expect(find.text('Restore'), findsOneWidget);

      // Verify CTA button exists
      expect(find.text('Start Pro Access'), findsOneWidget);
    });

    testWidgets('allows toggling between Annual and Monthly plans',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: PaywallScreen(autoPresentRevenueCatPaywall: false),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Both Annual and Monthly options should be visible
      expect(find.text('Annual Pro'), findsOneWidget);
      expect(find.text('Monthly Pro'), findsOneWidget);

      // Tap on Monthly Pro
      await tester.tap(find.text('Monthly Pro'));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap on Annual Pro
      await tester.tap(find.text('Annual Pro'));
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
