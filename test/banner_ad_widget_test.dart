import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/widgets/ad_config.dart';
import 'package:docscanner/widgets/banner_ad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BannerAdWidget Tests', () {
    tearDown(() {
      AdConfig.enableAds = true;
    });

    testWidgets('renders SizedBox.shrink when AdConfig.enableAds is false',
        (WidgetTester tester) async {
      AdConfig.enableAds = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(),
          ),
        ),
      );

      final sizedBoxFinder = find.byType(SizedBox);
      expect(sizedBoxFinder, findsWidgets);

      // Verify that no fixed height container is rendered
      final box = tester.firstWidget<SizedBox>(find.descendant(
        of: find.byType(BannerAdWidget),
        matching: find.byType(SizedBox),
      ));
      expect(box.width, 0.0);
      expect(box.height, 0.0);
    });

    testWidgets('renders fixed-height container when ads are enabled',
        (WidgetTester tester) async {
      AdConfig.enableAds = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BannerAdWidget(fixedHeight: 60.0),
          ),
        ),
      );

      expect(find.byType(BannerAdWidget), findsOneWidget);

      final box = tester.firstWidget<SizedBox>(find.descendant(
        of: find.byType(BannerAdWidget),
        matching: find.byType(SizedBox),
      ));
      expect(box.height, 50.0);
    });
  });

  group('AdConfig Tests', () {
    test('Ad unit IDs are configured and non-empty', () {
      expect(AdConfig.interstitialAdUnitId, isNotEmpty);
      expect(AdConfig.bannerAdUnitId, isNotEmpty);
      expect(AdConfig.nativeAdUnitId, isNotEmpty);
    });
  });
}
