import 'package:flutter_test/flutter_test.dart';
import 'package:docscanner/models/document_model.dart';

void main() {
  group('DocumentModel Unit Tests', () {
    final now = DateTime(2026, 11, 21, 12, 0, 0);

    test('DocumentModel instantiates with required fields and defaults', () {
      final doc = DocumentModel(
        id: 'doc_123',
        name: 'Tax_Return_2026',
        imagePath: '/path/to/scan.jpg',
        createdAt: now,
        type: DocumentType.pdf,
      );

      expect(doc.id, 'doc_123');
      expect(doc.name, 'Tax_Return_2026');
      expect(doc.title, 'Tax_Return_2026');
      expect(doc.imagePath, '/path/to/scan.jpg');
      expect(doc.filePath, '/path/to/scan.jpg');
      expect(doc.createdAt, now);
      expect(doc.modifiedAt, now);
      expect(doc.type, DocumentType.pdf);
      expect(doc.metadata, isEmpty);
      expect(doc.pdfPath, isNull);
    });

    test('filePath prioritizes pdfPath when present', () {
      final doc = DocumentModel(
        id: 'doc_456',
        name: 'Invoice',
        imagePath: '/path/to/image.jpg',
        pdfPath: '/path/to/invoice.pdf',
        createdAt: now,
        type: DocumentType.pdf,
      );

      expect(doc.filePath, '/path/to/invoice.pdf');
    });

    test('copyWith updates specified fields correctly', () {
      final original = DocumentModel(
        id: 'doc_orig',
        name: 'Original Title',
        imagePath: '/orig.jpg',
        createdAt: now,
        type: DocumentType.image,
      );

      final updated = original.copyWith(
        name: 'Renamed Document',
        pdfPath: '/new.pdf',
        type: DocumentType.pdf,
        extractedText: 'Sample OCR text',
      );

      expect(updated.id, 'doc_orig');
      expect(updated.name, 'Renamed Document');
      expect(updated.title, 'Renamed Document');
      expect(updated.pdfPath, '/new.pdf');
      expect(updated.filePath, '/new.pdf');
      expect(updated.type, DocumentType.pdf);
      expect(updated.extractedText, 'Sample OCR text');
      expect(updated.createdAt, now);
    });

    test('toJson generates structured map with all attributes', () {
      final doc = DocumentModel(
        id: 'doc_json',
        name: 'Contract Agreement',
        imagePath: '/contract.png',
        pdfPath: '/contract.pdf',
        extractedText: 'Confidentiality and IP terms',
        pageImagePaths: ['/page1.png', '/page2.png'],
        createdAt: now,
        type: DocumentType.pdf,
        folderId: 'folder_legal',
        metadata: {'author': 'Legal Dept'},
      );

      final jsonMap = doc.toJson();

      expect(jsonMap['id'], 'doc_json');
      expect(jsonMap['name'], 'Contract Agreement');
      expect(jsonMap['imagePath'], '/contract.png');
      expect(jsonMap['pdfPath'], '/contract.pdf');
      expect(jsonMap['extractedText'], 'Confidentiality and IP terms');
      expect(jsonMap['pageImagePaths'], ['/page1.png', '/page2.png']);
      expect(jsonMap['createdAt'], now.toIso8601String());
      expect(jsonMap['type'], 'DocumentType.pdf');
      expect(jsonMap['folderId'], 'folder_legal');
      expect(jsonMap['metadata'], {'author': 'Legal Dept'});
    });

    test('DocumentType enum contains image, pdf, and text', () {
      expect(DocumentType.values.length, 3);
      expect(DocumentType.values, contains(DocumentType.image));
      expect(DocumentType.values, contains(DocumentType.pdf));
      expect(DocumentType.values, contains(DocumentType.text));
    });
  });
}
