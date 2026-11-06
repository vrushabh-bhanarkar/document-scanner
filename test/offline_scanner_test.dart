import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/services/offline_scanner.dart';
import 'package:docscanner/services/advanced_scanner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Services Initialization Tests', () {
    test('OfflineScannerService instantiates correctly', () {
      final service = OfflineScannerService();
      expect(service, isNotNull);
      service.dispose();
    });

    test('AdvancedScannerService instantiates correctly', () async {
      final service = AdvancedScannerService();
      expect(service, isNotNull);
      await service.dispose();
    });
  });
}
