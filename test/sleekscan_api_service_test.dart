import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/core/app_config.dart';
import 'package:docscanner/services/sleekscan_api_service.dart';

void main() {
  group('SleekScanApiService Unit Tests', () {
    test('baseUrl matches AppConfig.backendApiUrl/api/v1', () {
      expect(
        SleekScanApiService.baseUrl,
        '${AppConfig.backendApiUrl}/api/v1',
      );
    });

    test('baseUrl points to valid HTTPS endpoint in production', () {
      final uri = Uri.parse(SleekScanApiService.baseUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, 'sleekscan-backend.fly.dev');
      expect(uri.path, '/api/v1');
    });
  });
}
