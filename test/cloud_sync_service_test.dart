import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/services/cloud_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CloudSyncService Tests', () {
    test('CloudSyncService factory returns singleton instance', () {
      final s1 = CloudSyncService();
      final s2 = CloudSyncService();
      expect(identical(s1, s2), isTrue);
    });

    test('checkIsPro returns false safely when uninitialized in test environment', () async {
      final service = CloudSyncService();
      final isPro = await service.checkIsPro();
      expect(isPro, isFalse);
    });

    test('syncDocumentToCloud throws Exception when user is not Pro', () async {
      final service = CloudSyncService();
      final tempFile = File('test_dummy.pdf');

      expect(
        () => service.syncDocumentToCloud(
          pdfFile: tempFile,
          title: 'Unpaid_Scan',
          extractedText: 'Sample text',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Cloud Sync is a Pro feature'),
        )),
      );
    });
  });
}
