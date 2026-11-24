import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/core/app_config.dart';

void main() {
  group('AppConfig Unit Tests', () {
    test('backendApiUrl and supabaseUrl default to project endpoints', () {
      expect(AppConfig.backendApiUrl, 'https://sleekscan-backend.fly.dev');
      expect(AppConfig.supabaseUrl, 'https://qsoijsmwxbccvzxcziks.supabase.co');
    });

    test('AppName and Version are defined properly', () {
      expect(AppConfig.appName, 'PDF ScanPro');
      expect(AppConfig.appVersion, isNotEmpty);
      expect(AppConfig.maxPdfPages, 500);
      expect(AppConfig.pdfCompressionQuality, 85);
    });

    test('Feature flags are enabled by default', () {
      expect(AppConfig.enableIDCardMode, isTrue);
      expect(AppConfig.enableSmartNaming, isTrue);
      expect(AppConfig.enableOfflineOCR, isTrue);
      expect(AppConfig.enableBatchScanning, isTrue);
    });

    test('Supported OCR languages includes essential codes', () {
      expect(AppConfig.supportedOCRLanguages, contains('en'));
      expect(AppConfig.supportedOCRLanguages, contains('es'));
      expect(AppConfig.supportedOCRLanguages, contains('fr'));
      expect(AppConfig.supportedOCRLanguages, contains('de'));
    });
  });
}
