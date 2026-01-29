import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/services/pdf_service.dart';

void main() {
  group('PDFService Tests', () {
    test('PageSize enum should have correct values', () {
      expect(PageSize.values.length, 6);
      expect(PageSize.a4, isA<PageSize>());
      expect(PageSize.letter, isA<PageSize>());
      expect(PageSize.legal, isA<PageSize>());
      expect(PageSize.a3, isA<PageSize>());
      expect(PageSize.a5, isA<PageSize>());
      expect(PageSize.custom, isA<PageSize>());
    });

    test('PDFDocument should have required properties', () {
      final document = PDFDocument(
        id: 'test-id',
        filePath: '/test/path.pdf',
        title: 'Test Document',
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        pageCount: 1,
        imagePages: ['/test/image1.jpg'],
      );

      expect(document.id, 'test-id');
      expect(document.filePath, '/test/path.pdf');
      expect(document.title, 'Test Document');
      expect(document.pageCount, 1);
      expect(document.imagePages.length, 1);
    });
  });
}
