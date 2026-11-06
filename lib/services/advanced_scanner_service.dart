import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// 100% OFFLINE: ML Kit Native Document Scanner Service
/// Uses on-device machine learning models for:
/// - Automatic document edge detection & perspective correction
/// - Shadow removal and intelligent contrast adjustment
/// - Color enhancement filters (Color, Grayscale, B&W)
class AdvancedScannerService {
  DocumentScanner? _scanner;

  /// Starts the native ML Kit Document Scanner flow on-device.
  /// Uses [ScannerMode.full] for full automatic boundary detection,
  /// perspective correction, shadow clearing, and color filters.
  Future<List<File>> scanDocuments({
    int pageLimit = 100,
    bool isGalleryImport = true,
  }) async {
    final options = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full,
      pageLimit: pageLimit,
      isGalleryImport: isGalleryImport,
    );

    _scanner = DocumentScanner(options: options);

    try {
      final DocumentScanningResult result = await _scanner!.scanDocument();
      final List<File> scannedFiles = [];

      for (final imageUri in result.images) {
        final file = File(imageUri);
        if (await file.exists()) {
          scannedFiles.add(file);
        }
      }

      debugPrint(
        '[AdvancedScannerService] Scanned ${scannedFiles.length} pages offline successfully.',
      );
      return scannedFiles;
    } catch (e) {
      debugPrint('[AdvancedScannerService] Document scanning error: $e');
      rethrow;
    } finally {
      await dispose();
    }
  }

  /// Scans documents returning the full [DocumentScanningResult]
  /// allowing access to both scanned image files and optional system PDF result.
  Future<DocumentScanningResult> scanDocumentsRaw({
    DocumentFormat documentFormat = DocumentFormat.jpeg,
    ScannerMode mode = ScannerMode.full,
    int pageLimit = 100,
    bool isGalleryImport = true,
  }) async {
    final options = DocumentScannerOptions(
      documentFormat: documentFormat,
      mode: mode,
      pageLimit: pageLimit,
      isGalleryImport: isGalleryImport,
    );

    _scanner = DocumentScanner(options: options);

    try {
      return await _scanner!.scanDocument();
    } finally {
      await dispose();
    }
  }

  /// Releases ML Kit scanner resources
  Future<void> dispose() async {
    if (_scanner != null) {
      try {
        await _scanner!.close();
      } catch (e) {
        debugPrint('[AdvancedScannerService] Error closing scanner: $e');
      }
      _scanner = null;
    }
  }
}
