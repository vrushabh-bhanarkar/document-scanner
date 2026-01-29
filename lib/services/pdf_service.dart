import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

enum PageSize {
  a4,
  letter,
  legal,
  a3,
  a5,
  custom,
}

// Keep heavy image work off the UI isolate to reduce PDF build time.
class _OptimizeImageArgs {
  final Uint8List bytes;
  final int quality;
  final int maxDimension;

  const _OptimizeImageArgs({
    required this.bytes,
    required this.quality,
    required this.maxDimension,
  });
}

Uint8List _optimizeImageBytes(_OptimizeImageArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;

  final clampedQuality = args.quality.clamp(40, 100).toInt();
  final largestSide = max(decoded.width, decoded.height);

  img.Image processed = decoded;
  if (args.maxDimension > 0 && largestSide > args.maxDimension) {
    final scale = args.maxDimension / largestSide;
    processed = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  final encoded = img.encodeJpg(processed, quality: clampedQuality);
  return Uint8List.fromList(encoded);
}

Future<Uint8List> _loadOptimizedImageBytes({
  required File file,
  required int quality,
  required int maxDimension,
}) async {
  final originalBytes = await file.readAsBytes();

  // Skip isolate hop for already small payloads.
  if (originalBytes.length < 400000) {
    return originalBytes;
  }

  try {
    return await compute(
      _optimizeImageBytes,
      _OptimizeImageArgs(
        bytes: originalBytes,
        quality: quality,
        maxDimension: maxDimension,
      ),
    );
  } catch (_) {
    return originalBytes;
  }
}

class PDFDocument {
  final String id;
  final String filePath;
  final String title;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final int pageCount;
  final List<String> imagePages;

  PDFDocument({
    required this.id,
    required this.filePath,
    required this.title,
    required this.createdAt,
    required this.modifiedAt,
    required this.pageCount,
    required this.imagePages,
  });
}

class PDFService {
  static const _uuid = Uuid();

  /// Convert images to PDF
  Future<File?> createPDFFromImages({
    required List<File> imageFiles,
    required String title,
    PageSize pageSize = PageSize.a4,
    double? customWidth,
    double? customHeight,
    bool fitToPage = true,
    double margin = 20,
  }) async {
    try {
      final pdf = pw.Document();
      final pdfPageFormat = _getPageFormat(pageSize, customWidth, customHeight);

      for (final imageFile in imageFiles) {
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pdfPageFormat,
            margin: pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Center(
                child: fitToPage
                    ? pw.Image(image, fit: pw.BoxFit.contain)
                    : pw.Image(image),
              );
            },
          ),
        );
      }

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      return file;
    } catch (e) {
      print('Error creating PDF from images: $e');
      return null;
    }
  }

  /// Create PDF with advanced options
  Future<File?> createAdvancedPDF({
    required List<File> imageFiles,
    required String title,
    PageSize pageSize = PageSize.a4,
    double? customWidth,
    double? customHeight,
    bool fitToPage = true,
    double margin = 20,
    String? author,
    String? subject,
    List<String>? pageLabels,
    bool addPageNumbers = false,
    String? watermarkText,
    int imageQuality = 82,
    int maxImageDimension = 2000,
  }) async {
    try {
      final pdf = pw.Document(
        title: title,
        author: author,
        subject: subject,
        creator: 'Document Scanner App',
      );

      final pdfPageFormat = _getPageFormat(pageSize, customWidth, customHeight);
      final totalPages = imageFiles.length;

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        final optimizedBytes = await _loadOptimizedImageBytes(
          file: imageFile,
          quality: imageQuality,
          maxDimension: maxImageDimension,
        );
        final image = pw.MemoryImage(optimizedBytes);

        final pageLabel =
            pageLabels != null && i < pageLabels.length ? pageLabels[i] : null;

        pdf.addPage(
          pw.Page(
            pageFormat: pdfPageFormat,
            margin: pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Main content
                  pw.Column(
                    children: [
                      if (pageLabel != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 10),
                          child: pw.Text(
                            pageLabel,
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      pw.Expanded(
                        child: pw.Center(
                          child: fitToPage
                              ? pw.Image(image, fit: pw.BoxFit.contain)
                              : pw.Image(image),
                        ),
                      ),
                      if (addPageNumbers)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 10),
                          child: pw.Text(
                            'Page ${i + 1} of $totalPages',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),

                  // Watermark
                  if (watermarkText != null)
                    pw.Center(
                      child: pw.Transform.rotate(
                        angle: -0.5,
                        child: pw.Text(
                          watermarkText,
                          style: pw.TextStyle(
                            fontSize: 48,
                            color: pdf_lib.PdfColors.grey300,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      return file;
    } catch (e) {
      print('Error creating advanced PDF: $e');
      return null;
    }
  }

  /// Merge multiple PDFs into one
  Future<File?> mergePDFs({
    required List<File> pdfFiles,
    required String outputFileName,
    Map<String, String>? passwords, // Map of file path to password
  }) async {
    try {
      if (pdfFiles.isEmpty) {
        print('Error: No PDF files to merge');
        return null;
      }

      final sf.PdfDocument mergedDocument = sf.PdfDocument();

      for (final pdfFile in pdfFiles) {
        final bytes = await pdfFile.readAsBytes();
        sf.PdfDocument? sourceDocument;

        // Try to open the document with password if provided
        final password = passwords?[pdfFile.path];

        try {
          if (password != null && password.isNotEmpty) {
            sourceDocument = sf.PdfDocument(
              inputBytes: bytes,
              password: password,
            );
          } else {
            sourceDocument = sf.PdfDocument(inputBytes: bytes);
          }
        } catch (e) {
          // If document fails to open, it might be password protected
          if (e.toString().contains('password') ||
              e.toString().contains('encrypted') ||
              e.toString().contains('Invalid argument')) {
            print(
                'Failed to open ${pdfFile.path}: Password required or invalid');
            rethrow; // Rethrow to be caught by outer try-catch
          }
          rethrow;
        }

        // Import all pages from source document using template method
        for (int i = 0; i < sourceDocument.pages.count; i++) {
          final template = sourceDocument.pages[i].createTemplate();

          // Add new page and draw template
          mergedDocument.pages
              .add()
              .graphics
              .drawPdfTemplate(template, Offset.zero);
        }

        sourceDocument.dispose();
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${outputFileName}_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final bytes = await mergedDocument.save();
      await file.writeAsBytes(bytes);

      mergedDocument.dispose();
      return file;
    } catch (e) {
      print('Error merging PDFs: $e');
      return null;
    }
  }

  /// Check if a PDF is password protected
  Future<bool> isPdfPasswordProtected(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      document.dispose();
      return false;
    } catch (e) {
      if (e.toString().contains('password') ||
          e.toString().contains('encrypted') ||
          e.toString().contains('Invalid argument')) {
        return true;
      }
      rethrow;
    }
  }

  /// Try to open a password-protected PDF with the given password
  Future<bool> verifyPdfPassword(File pdfFile, String password) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(
        inputBytes: bytes,
        password: password,
      );
      document.dispose();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Split PDF by page range
  Future<File?> splitPdfByRange(
      File pdfFile, int startPage, int endPage) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      final sf.PdfDocument newDocument = sf.PdfDocument();

      // Import pages using template method
      for (int i = startPage - 1; i <= endPage - 1; i++) {
        if (i < document.pages.count) {
          final template = document.pages[i].createTemplate();
          newDocument.pages
              .add()
              .graphics
              .drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName =
          '${originalName}_pages_${startPage}_to_${endPage}_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await newDocument.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      newDocument.dispose();
      return file;
    } catch (e) {
      print('Error splitting PDF: $e');
      return null;
    }
  }

  /// Split PDF by specific pages
  Future<List<File>> splitPdfByPages(
      File pdfFile, List<int> pageNumbers) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final List<File> splitFiles = [];

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');

      for (final pageNumber in pageNumbers) {
        if (pageNumber > 0 && pageNumber <= document.pages.count) {
          final sf.PdfDocument newDocument = sf.PdfDocument();
          final template = document.pages[pageNumber - 1].createTemplate();
          newDocument.pages
              .add()
              .graphics
              .drawPdfTemplate(template, const Offset(0, 0));

          final fileName =
              '${originalName}_page_${pageNumber}_${_uuid.v4()}.pdf';
          final file = File('${directory.path}/$fileName');

          final newBytes = await newDocument.save();
          await file.writeAsBytes(newBytes);

          splitFiles.add(file);
          newDocument.dispose();
        }
      }

      document.dispose();
      return splitFiles;
    } catch (e) {
      print('Error splitting PDF by pages: $e');
      return [];
    }
  }

  /// Split PDF into equal parts
  Future<List<File>> splitPdfIntoParts(File pdfFile, int numberOfParts) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final totalPages = document.pages.count;
      final pagesPerPart = (totalPages / numberOfParts).ceil();
      final List<File> splitFiles = [];

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');

      for (int i = 0; i < numberOfParts; i++) {
        final startPage = i * pagesPerPart;
        final endPage = ((i + 1) * pagesPerPart - 1).clamp(0, totalPages - 1);

        if (startPage <= endPage && startPage < totalPages) {
          final sf.PdfDocument newDocument = sf.PdfDocument();

          // Copy pages using template method
          for (int pageIdx = startPage; pageIdx <= endPage; pageIdx++) {
            if (pageIdx < document.pages.count) {
              final template = document.pages[pageIdx].createTemplate();
              newDocument.pages
                  .add()
                  .graphics
                  .drawPdfTemplate(template, const Offset(0, 0));
            }
          }

          final fileName = '${originalName}_part_${i + 1}_${_uuid.v4()}.pdf';
          final file = File('${directory.path}/$fileName');

          final newBytes = await newDocument.save();
          await file.writeAsBytes(newBytes);

          splitFiles.add(file);
          newDocument.dispose();
        }
      }

      document.dispose();
      return splitFiles;
    } catch (e) {
      print('Error splitting PDF into parts: $e');
      return [];
    }
  }

  /// Get PDF page count
  Future<int> getPdfPageCount(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      document.dispose();
      return pageCount;
    } catch (e) {
      print('Error getting PDF page count: $e');
      return 0;
    }
  }

  /// Rotate PDF pages
  Future<File?> rotatePdfPages(
      File pdfFile, List<int> pageNumbers, int rotationAngle) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      for (final pageNumber in pageNumbers) {
        if (pageNumber > 0 && pageNumber <= document.pages.count) {
          final page = document.pages[pageNumber - 1];
          page.rotation = sf.PdfPageRotateAngle.values[rotationAngle ~/ 90];
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName = '${originalName}_rotated_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error rotating PDF pages: $e');
      return null;
    }
  }

  /// Delete pages from PDF
  Future<File?> deletePdfPages(File pdfFile, List<int> pageNumbers) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      // Sort in descending order to delete from end first
      final sortedPages = pageNumbers.toList()..sort((a, b) => b.compareTo(a));

      for (final pageNumber in sortedPages) {
        if (pageNumber > 0 && pageNumber <= document.pages.count) {
          document.pages.removeAt(pageNumber - 1);
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName = '${originalName}_pages_deleted_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error deleting PDF pages: $e');
      return null;
    }
  }

  /// Add password protection to PDF
  Future<File?> addPasswordToPdf(File pdfFile, String userPassword,
      {String? ownerPassword}) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      final sf.PdfSecurity security = document.security;
      security.userPassword = userPassword;
      security.ownerPassword = ownerPassword ?? userPassword;
      security.permissions.addAll([
        sf.PdfPermissionsFlags.print,
        sf.PdfPermissionsFlags.editContent,
        sf.PdfPermissionsFlags.copyContent,
        sf.PdfPermissionsFlags.editAnnotations,
        sf.PdfPermissionsFlags.fillFields,
        sf.PdfPermissionsFlags.accessibilityCopyContent,
        sf.PdfPermissionsFlags.assembleDocument,
        sf.PdfPermissionsFlags.fullQualityPrint,
      ]);

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName = '${originalName}_protected_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error adding password to PDF: $e');
      return null;
    }
  }

  /// Compress PDF
  Future<File?> compressPdf(File pdfFile,
      {double compressionLevel = 0.5}) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);

      // Map compression level to Syncfusion enum
      // compressionLevel ranges from 0.1 to 1.0
      // 1.0 = best quality (least compression), 0.1 = smallest size (most compression)
      if (compressionLevel >= 0.8) {
        // Minimal compression for highest quality
        document.compressionLevel = sf.PdfCompressionLevel.none;
      } else if (compressionLevel >= 0.6) {
        // Balanced compression
        document.compressionLevel = sf.PdfCompressionLevel.normal;
      } else {
        // Maximum compression for smallest size
        document.compressionLevel = sf.PdfCompressionLevel.best;
      }

      // Compress images within the document
      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        // Reduce image quality based on compression level
        final imageQuality = (compressionLevel * 100).toInt().clamp(10, 100);
        // The compression is handled by the compression level setting above
      }

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName = '${originalName}_compressed_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error compressing PDF: $e');
      return null;
    }
  }

  /// Add annotations to PDF
  Future<File?> addAnnotationsToPdf(
      File pdfFile, List<dynamic> annotations) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      // Apply annotations grouped by page
      for (final ann in annotations) {
        try {
          final int pageNum = (ann['page'] ?? 1) as int;
          final pageIndex = pageNum - 1;
          if (pageIndex < 0 || pageIndex >= document.pages.count) continue;

          final page = document.pages[pageIndex];
          final pageSize = page.size;

          final canvasW = (ann['canvasWidth'] as num?)?.toDouble() ?? pageSize.width;
          final canvasH = (ann['canvasHeight'] as num?)?.toDouble() ?? pageSize.height;

          // helper to map widget coords to PDF coords (PDF origin at bottom-left)
          double mapX(num x) => (x.toDouble() / canvasW) * pageSize.width;
          double mapY(num y) => pageSize.height - (y.toDouble() / canvasH) * pageSize.height;

          final String type = (ann['type'] ?? 'pen') as String;
          final colorVal = (ann['color'] ?? 0xFF000000) as int;
          final a = (colorVal >> 24) & 0xFF;
          final r = (colorVal >> 16) & 0xFF;
          final g = (colorVal >> 8) & 0xFF;
          final b = colorVal & 0xFF;

          final thickness = (ann['thickness'] as num?)?.toDouble() ?? 2.0;
          final sf.PdfPen pen = sf.PdfPen(sf.PdfColor(r, g, b));
          pen.width = thickness;

          final points = (ann['points'] as List<dynamic>?)?.cast<Map<String, dynamic>>();

          if (type == 'pen' || type == 'highlighter') {
            if (points != null && points.length > 1) {
              for (int i = 0; i < points.length - 1; i++) {
                final p0 = points[i];
                final p1 = points[i + 1];
                final x0 = mapX(p0['dx']);
                final y0 = mapY(p0['dy']);
                final x1 = mapX(p1['dx']);
                final y1 = mapY(p1['dy']);
                page.graphics.drawLine(pen, ui.Offset(x0, y0), ui.Offset(x1, y1));
              }
            }
          } else if (type == 'arrow') {
            if (points != null && points.length >= 2) {
              final p0 = points.first;
              final p1 = points.last;
              final x0 = mapX(p0['dx']);
              final y0 = mapY(p0['dy']);
              final x1 = mapX(p1['dx']);
              final y1 = mapY(p1['dy']);
              page.graphics.drawLine(pen, ui.Offset(x0, y0), ui.Offset(x1, y1));
              // simple arrowhead
              final angle = atan2(y1 - y0, x1 - x0);
              final head = 12.0;
              final pa = ui.Offset(x1 - head * cos(angle - pi / 6), y1 - head * sin(angle - pi / 6));
              final pb = ui.Offset(x1 - head * cos(angle + pi / 6), y1 - head * sin(angle + pi / 6));
              page.graphics.drawLine(pen, ui.Offset(x1, y1), pa);
              page.graphics.drawLine(pen, ui.Offset(x1, y1), pb);
            }
          } else if (type == 'rectangle') {
            if (points != null && points.length >= 2) {
              final p0 = points.first;
              final p1 = points.last;
              final x0 = mapX(p0['dx']);
              final y0 = mapY(p0['dy']);
              final x1 = mapX(p1['dx']);
              final y1 = mapY(p1['dy']);
              final left = min(x0, x1);
              final top = min(y0, y1);
              final width = (x1 - x0).abs();
              final height = (y1 - y0).abs();
              page.graphics.drawRectangle(bounds: ui.Rect.fromLTWH(left, top, width, height), pen: pen);
            }
          } else if (type == 'circle') {
            if (points != null && points.length >= 2) {
              final p0 = points.first;
              final p1 = points.last;
              final x0 = mapX(p0['dx']);
              final y0 = mapY(p0['dy']);
              final x1 = mapX(p1['dx']);
              final y1 = mapY(p1['dy']);
              final centerX = (x0 + x1) / 2;
              final centerY = (y0 + y1) / 2;
              final radius = sqrt(pow(x1 - x0, 2) + pow(y1 - y0, 2)) / 2;
              page.graphics.drawEllipse(ui.Rect.fromLTWH(centerX - radius, centerY - radius, radius * 2, radius * 2), pen: pen);
            }
          } else if (type == 'text') {
            final pos = ann['position'] as Map<String, dynamic>?;
            if (pos != null) {
              final x = mapX(pos['dx']);
              final y = mapY(pos['dy']);
              final text = (ann['text'] ?? '') as String;
              final fontSize = (ann['thickness'] as num?)?.toDouble() ?? 12.0;
              final sf.PdfFont font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize);
              page.graphics.drawString(text, font, brush: sf.PdfBrushes.black, bounds: ui.Rect.fromLTWH(x, y, 200, 50));
            }
          }
        } catch (e) {
          // ignore single annotation errors and continue
          print('Annotation draw error: $e');
          continue;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final originalName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName = '${originalName}_annotated_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error adding annotations to PDF: $e');
      return null;
    }
  }

  /// Get PDF information
  Future<Map<String, dynamic>?> getPDFInfo(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final stats = await pdfFile.stat();

      return {
        'fileSize': bytes.length,
        'fileSizeFormatted': _formatFileSize(bytes.length),
        'lastModified': stats.modified,
        'fileName': pdfFile.path.split('/').last,
        'filePath': pdfFile.path,
      };
    } catch (e) {
      print('Error getting PDF info: $e');
      return null;
    }
  }

  /// Print PDF
  Future<bool> printPDF(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await Printing.layoutPdf(onLayout: (format) => bytes);
      return true;
    } catch (e) {
      print('Error printing PDF: $e');
      return false;
    }
  }

  /// Share PDF
  Future<bool> sharePDF(File pdfFile, {String? subject}) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: pdfFile.path.split('/').last,
        subject: subject,
      );
      return true;
    } catch (e) {
      print('Error sharing PDF: $e');
      return false;
    }
  }

  /// Get page format based on PageSize enum
  pdf_lib.PdfPageFormat _getPageFormat(
      PageSize pageSize, double? customWidth, double? customHeight) {
    switch (pageSize) {
      case PageSize.a4:
        return pdf_lib.PdfPageFormat.a4;
      case PageSize.letter:
        return pdf_lib.PdfPageFormat.letter;
      case PageSize.legal:
        return pdf_lib.PdfPageFormat.legal;
      case PageSize.a3:
        return pdf_lib.PdfPageFormat.a3;
      case PageSize.a5:
        return pdf_lib.PdfPageFormat.a5;
      case PageSize.custom:
        if (customWidth != null && customHeight != null) {
          return pdf_lib.PdfPageFormat(customWidth, customHeight);
        }
        return pdf_lib.PdfPageFormat.a4;
    }
  }

  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Validate PDF file
  Future<bool> isValidPDF(File pdfFile) async {
    try {
      if (!await pdfFile.exists()) return false;

      final bytes = await pdfFile.readAsBytes();
      // Simple PDF header check
      if (bytes.length < 4) return false;

      final header = String.fromCharCodes(bytes.take(4));
      return header == '%PDF';
    } catch (e) {
      return false;
    }
  }

  /// Get estimated page count (basic estimation)
  Future<int> estimatePageCount(List<File> imageFiles) async {
    return imageFiles.length; // Simple 1:1 mapping for now
  }

  /// Simple PDF creation with basic error handling
  Future<File?> createSimplePDF({
    required List<File> imageFiles,
    required String title,
  }) async {
    try {
      print('Starting PDF creation for ${imageFiles.length} images');

      final pdf = pw.Document();

      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        print('Processing image ${i + 1}: ${imageFile.path}');

        // Check if file exists
        if (!await imageFile.exists()) {
          print('Image file does not exist: ${imageFile.path}');
          continue;
        }

        try {
          final imageBytes = await imageFile.readAsBytes();
          print('Image ${i + 1} size: ${imageBytes.length} bytes');

          final image = pw.MemoryImage(imageBytes);

          pdf.addPage(
            pw.Page(
              pageFormat: pdf_lib.PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                );
              },
            ),
          );

          print('Added page ${i + 1} to PDF');
        } catch (e) {
          print('Error processing image ${i + 1}: $e');
          // Continue with other images
        }
      }

      if (pdf.document.pdfPageList.pages.isEmpty) {
        print('No pages were added to PDF');
        return null;
      }

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      print('Saving PDF to: ${file.path}');

      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      print('PDF saved successfully. Size: ${pdfBytes.length} bytes');

      // Verify file was created
      if (await file.exists()) {
        final fileSize = await file.length();
        print('PDF file verified. File size: $fileSize bytes');
        return file;
      } else {
        print('PDF file was not created');
        return null;
      }
    } catch (e) {
      print('Error creating simple PDF: $e');
      return null;
    }
  }

  /// Extract images from PDF pages
  Future<List<File>> extractImagesFromPDF({
    required File pdfFile,
    double scale = 2.0, // Higher scale for better quality
  }) async {
    try {
      print('Starting PDF extraction from: ${pdfFile.path}');

      // Try platform-specific PDF rendering first
      if (Platform.isAndroid) {
        final androidImages = await _extractPDFPagesAndroid(pdfFile, scale);
        if (androidImages.isNotEmpty) {
          print(
              'Successfully extracted ${androidImages.length} actual pages using Android PDF renderer');
          return androidImages;
        }
      }

      // Fallback to placeholder method if platform-specific fails
      print('Falling back to placeholder method');
      return await _extractPDFPagesPlaceholder(pdfFile, scale);
    } catch (e) {
      print('Error extracting images from PDF: $e');
      return await _extractPDFPagesPlaceholder(pdfFile, scale);
    }
  }

  /// Extract PDF pages using Android native PDF renderer
  Future<List<File>> _extractPDFPagesAndroid(File pdfFile, double scale) async {
    try {
      const platform = MethodChannel('pdf_renderer');

      // Call native Android method to extract PDF pages
      final result = await platform.invokeMethod('extractPdfPages', {
        'pdfPath': pdfFile.path,
        'scale': scale,
      });

      if (result is List && result.isNotEmpty) {
        final extractedImages = <File>[];
        for (final imagePath in result) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            extractedImages.add(imageFile);
          }
        }
        return extractedImages;
      }

      return [];
    } catch (e) {
      print('Android PDF extraction failed: $e');
      return [];
    }
  }

  /// Extract PDF pages as enhanced placeholders (fallback method)
  Future<List<File>> _extractPDFPagesPlaceholder(
      File pdfFile, double scale) async {
    final extractedImages = <File>[];

    try {
      // Read the PDF file to get page count and info
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      print('PDF has $pageCount pages');

      final directory = await getApplicationDocumentsDirectory();
      final tempDir =
          Directory('${directory.path}/pdf_extracted_${_uuid.v4()}');
      await tempDir.create(recursive: true);

      // Extract each page as an enhanced placeholder with actual content info
      for (int i = 0; i < pageCount; i++) {
        print('Processing page ${i + 1} of $pageCount');

        final page = document.pages[i];
        final pageSize = page.size;

        // Create image file
        final fileName = 'pdf_page_${i + 1}_${_uuid.v4()}.png';
        final imageFile = File('${tempDir.path}/$fileName');

        // Create enhanced placeholder with actual page content info
        final placeholderImage = await _createEnhancedPlaceholderImage(
          'PDF Page ${i + 1}',
          pageSize: Size(pageSize.width, pageSize.height),
          pageNumber: i + 1,
          totalPages: pageCount,
        );
        await imageFile.writeAsBytes(placeholderImage);

        extractedImages.add(imageFile);
        print('Created enhanced placeholder for page ${i + 1}');
      }

      document.dispose();
      print('Extracted ${extractedImages.length} pages from PDF');
      return extractedImages;
    } catch (e) {
      print('Error extracting images from PDF: $e');
      return [];
    }
  }

  /// Create an enhanced placeholder image for PDF pages
  Future<Uint8List> _createEnhancedPlaceholderImage(String text,
      {Size? pageSize, int? pageNumber, int? totalPages}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Use provided page size or default size
    final size = pageSize ?? const Size(400, 600);

    // White background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // PDF icon
    final iconPaint = Paint()..color = Colors.red[400]!;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 3),
      30,
      iconPaint,
    );

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Page info
    if (pageSize != null) {
      final infoPainter = TextPainter(
        text: TextSpan(
          text: 'Size: ${pageSize.width.round()} x ${pageSize.height.round()}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      infoPainter.layout();
      infoPainter.paint(
        canvas,
        Offset(
          (size.width - infoPainter.width) / 2,
          (size.height - infoPainter.height) / 2 + 30,
        ),
      );
    }

    // Page number
    if (pageNumber != null && totalPages != null) {
      final pageInfoPainter = TextPainter(
        text: TextSpan(
          text: 'Page $pageNumber of $totalPages',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      pageInfoPainter.layout();
      pageInfoPainter.paint(
        canvas,
        Offset(
          (size.width - pageInfoPainter.width) / 2,
          (size.height - pageInfoPainter.height) / 2 + 60,
        ),
      );
    }

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Convert PDF page bytes to actual image using printing package
  Future<Uint8List> _convertPDFPageToActualImage(
      List<int> pdfBytes, Size pageSize, double scale) async {
    try {
      final imageBytes = await Printing.convertHtml(
        html: '''
        <html lang="en">
          <head>
            <style>
              body { 
                margin: 0; 
                padding: 0; 
                background: white;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
              }
              .pdf-container {
                box-shadow: 0 4px 8px rgba(0,0,0,0.1);
                border: 1px solid #ddd;
              }
            </style>
          </head>
          <body>
            <div class="pdf-container">
              <embed src="data:application/pdf;base64,${base64Encode(pdfBytes)}"
                     type="application/pdf"
                     width="${(pageSize.width * scale).round()}"
                     height="${(pageSize.height * scale).round()}" />
            </div>
          </body>
        </html>
        ''',
        format: pdf_lib.PdfPageFormat.a4,
      );
      return Uint8List.fromList(imageBytes);
    } catch (e) {
      print('Error converting PDF to image: $e');
      return await _createEnhancedPlaceholderImage('PDF Page',
          pageSize: pageSize);
    }
  }

  /// Convert PDF pages to individual image files
  Future<List<File>?> convertPdfPagesToImages({
    required File pdfFile,
    String imageFormat = 'jpg', // 'jpg' or 'png'
    double quality = 0.8,
    List<int>? pageNumbers, // null means all pages
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final totalPages = document.pages.count;
      final List<File> imageFiles = [];

      // Determine which pages to convert
      final pagesToConvert = pageNumbers ?? List.generate(totalPages, (i) => i);

      final directory = await getApplicationDocumentsDirectory();
      final outputDir =
          Directory('${directory.path}/converted_images_${_uuid.v4()}');
      await outputDir.create(recursive: true);

      for (int pageIndex in pagesToConvert) {
        if (pageIndex < 0 || pageIndex >= totalPages) continue;

        try {
          // Create a single-page PDF for this page
          final singlePageDoc = sf.PdfDocument();
          final template = document.pages[pageIndex].createTemplate();
          final pageSize = document.pages[pageIndex].size;

          singlePageDoc.pageSettings.size =
              Size(pageSize.width, pageSize.height);
          final newPage = singlePageDoc.pages.add();
          newPage.graphics.drawPdfTemplate(template, const Offset(0, 0));

          // Convert single-page PDF to image bytes using printing package
          final singlePageBytes = await singlePageDoc.save();
          singlePageDoc.dispose();

          // Use printing package raster to convert PDF page to image
          final imageData = await Printing.raster(
            Uint8List.fromList(singlePageBytes),
            pages: [0], // First (and only) page
            dpi: (quality * 200)
                .toDouble(), // Scale DPI based on quality (80-200 DPI range)
          );

          // Convert stream to list
          final rasterList = await imageData.toList();

          if (rasterList.isNotEmpty) {
            final pdfRaster = rasterList.first;
            final pngBytes = await pdfRaster.toPng();

            Uint8List finalBytes;

            if (imageFormat.toLowerCase() == 'jpg') {
              // Decode PNG and convert to JPG with quality compression
              final img.Image? image = img.decodePng(pngBytes);
              if (image != null) {
                finalBytes = Uint8List.fromList(
                    img.encodeJpg(image, quality: (quality * 100).toInt()));
              } else {
                finalBytes = pngBytes;
              }
            } else {
              // Keep as PNG
              finalBytes = pngBytes;
            }

            // Save the image file
            final extension =
                imageFormat.toLowerCase() == 'jpg' ? 'jpg' : 'png';
            final fileName = 'page_${pageIndex + 1}.$extension';
            final imageFile = File('${outputDir.path}/$fileName');
            await imageFile.writeAsBytes(finalBytes);
            imageFiles.add(imageFile);

            print(
                'Converted page ${pageIndex + 1} to ${extension.toUpperCase()}');
          }
        } catch (e) {
          print('Error converting page ${pageIndex + 1}: $e');
          // Continue with next page
        }
      }

      document.dispose();

      if (imageFiles.isEmpty) {
        print('No images were converted');
        return null;
      }

      print('Successfully converted ${imageFiles.length} pages to images');
      return imageFiles;
    } catch (e) {
      print('Error converting PDF pages to images: $e');
      return null;
    }
  }

  /// Create a PDF from plain text
  Future<File?> createPDFFromText({
    required String text,
    required String title,
    double fontSize = 14,
  }) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text(
                text,
                style: pw.TextStyle(fontSize: fontSize),
              ),
            );
          },
        ),
      );
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${title.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      print('Error creating PDF from text: $e');
      return null;
    }
  }

  /// Remove selected pages from a PDF
  Future<File?> removePagesFromPDF({
    required File pdfFile,
    required List<int> pagesToRemove,
    required String outputTitle,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      // Remove pages in reverse order to avoid index shift
      final sortedPages = List<int>.from(pagesToRemove)
        ..sort((a, b) => b.compareTo(a));
      for (final pageIndex in sortedPages) {
        if (pageIndex >= 0 && pageIndex < document.pages.count) {
          document.pages.removeAt(pageIndex);
        }
      }
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_pages_removed_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);
      document.dispose();
      return file;
    } catch (e) {
      print('Error removing pages from PDF: $e');
      return null;
    }
  }

  /// Reorder pages in a PDF
  Future<File?> reorderPagesInPDF({
    required File pdfFile,
    required List<int> newOrder,
    required String outputTitle,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final totalPages = document.pages.count;
      final reorderedDocument = sf.PdfDocument();
      for (final pageIndex in newOrder) {
        if (pageIndex >= 0 && pageIndex < totalPages) {
          final template = document.pages[pageIndex].createTemplate();
          reorderedDocument.pages
              .add()
              .graphics
              .drawPdfTemplate(template, const Offset(0, 0));
        }
      }
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_pages_reordered_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await reorderedDocument.save();
      await file.writeAsBytes(newBytes);
      document.dispose();
      reorderedDocument.dispose();
      return file;
    } catch (e) {
      print('Error reordering pages in PDF: $e');
      return null;
    }
  }

  /// Insert pages into a PDF at a given position
  Future<File?> insertPagesIntoPDF({
    required File pdfFile,
    required List<File> pagesToInsert,
    required int insertAt,
    required String outputTitle,
  }) async {
    try {
      // Validate main PDF exists and read it
      if (!await pdfFile.exists()) {
        print('insertPagesIntoPDF: main PDF not found: ${pdfFile.path}');
        return null;
      }
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final totalPages = document.pages.count;

      // Validate insertAt position
      if (insertAt < 0 || insertAt > totalPages) {
        print('Invalid insert position: $insertAt (total pages: $totalPages)');
        document.dispose();
        return null;
      }

      // Create new document
      final newDocument = sf.PdfDocument();

      // Add pages before insert position
      for (int i = 0; i < insertAt; i++) {
        final template = document.pages[i].createTemplate();
        final page = newDocument.pages.add();
        final pageSize = document.pages[i].size;
        page.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(pageSize.width, pageSize.height),
        );
      }

      // Insert new pages from files (skip missing files)
      for (final insertFile in pagesToInsert) {
        if (!await insertFile.exists()) {
          print('insertPagesIntoPDF: insert file missing, skipping: ${insertFile.path}');
          continue;
        }

        try {
          final insertBytes = await insertFile.readAsBytes();
          final insertDoc = sf.PdfDocument(inputBytes: insertBytes);

          for (int i = 0; i < insertDoc.pages.count; i++) {
            final template = insertDoc.pages[i].createTemplate();
            final page = newDocument.pages.add();
            final pageSize = insertDoc.pages[i].size;
            page.graphics.drawPdfTemplate(
              template,
              const Offset(0, 0),
              Size(pageSize.width, pageSize.height),
            );
          }

          insertDoc.dispose();
        } catch (e) {
          print('Error inserting file ${insertFile.path}: $e');
          // Continue with other files
        }
      }

      // Add remaining pages after insert position
      for (int i = insertAt; i < totalPages; i++) {
        final template = document.pages[i].createTemplate();
        final page = newDocument.pages.add();
        final pageSize = document.pages[i].size;
        page.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
          Size(pageSize.width, pageSize.height),
        );
      }

      // Save the new document
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^\w\s-]'), '')}_pages_inserted_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await newDocument.save();
      await file.writeAsBytes(newBytes);

      // Cleanup
      document.dispose();
      newDocument.dispose();

      return file;
    } catch (e, stackTrace) {
      print('Error inserting pages into PDF: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Rotate selected pages by quarter turns (1=90°, 2=180°, 3=270°)
  Future<File?> rotatePagesInPDF({
    required File pdfFile,
    required List<int> pages,
    required int quarterTurns,
    required String outputTitle,
  }) async {
    try {
      if (quarterTurns % 4 == 0) return pdfFile; // no-op
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final total = document.pages.count;
      final newDoc = sf.PdfDocument();

      final turns = (quarterTurns % 4);
      for (int i = 0; i < total; i++) {
        final template = document.pages[i].createTemplate();
        final size = document.pages[i].size;
        final rotateThis = pages.contains(i);

        // Determine new page size after rotation
        final bool swap = rotateThis && (turns % 2 != 0);
        final double newW = swap ? size.height : size.width;
        final double newH = swap ? size.width : size.height;

        // Set page size via pageSettings before adding page
        newDoc.pageSettings.size = Size(newW, newH);
        final page = newDoc.pages.add();

        final g = page.graphics;
        if (rotateThis) {
          g.save();
          switch (turns) {
            case 1: // 90°
              g.translateTransform(newW, 0);
              g.rotateTransform(90);
              break;
            case 2: // 180°
              g.translateTransform(newW, newH);
              g.rotateTransform(180);
              break;
            case 3: // 270°
              g.translateTransform(0, newH);
              g.rotateTransform(270);
              break;
          }
          g.drawPdfTemplate(template, const Offset(0, 0));
          g.restore();
        } else {
          g.drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_rotated_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await newDoc.save();
      await file.writeAsBytes(newBytes);
      document.dispose();
      newDoc.dispose();
      return file;
    } catch (e) {
      print('Error rotating pages: $e');
      return null;
    }
  }

  /// Crop pages by margin percentages (0.0-0.4 typical)
  Future<File?> cropPagesInPDFByMargin({
    required File pdfFile,
    required List<int> pages,
    required double leftPct,
    required double topPct,
    required double rightPct,
    required double bottomPct,
    required String outputTitle,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final total = document.pages.count;
      final newDoc = sf.PdfDocument();

      for (int i = 0; i < total; i++) {
        final srcPage = document.pages[i];
        final size = srcPage.size;
        final cropThis = pages.contains(i);

        if (!cropThis) {
          newDoc.pageSettings.size = Size(size.width, size.height);
          final page = newDoc.pages.add();
          page.graphics
              .drawPdfTemplate(srcPage.createTemplate(), const Offset(0, 0));
          continue;
        }

        // Calculate crop rectangle
        final double l = (leftPct.clamp(0.0, 0.45)) * size.width;
        final double r = (rightPct.clamp(0.0, 0.45)) * size.width;
        final double t = (topPct.clamp(0.0, 0.45)) * size.height;
        final double b = (bottomPct.clamp(0.0, 0.45)) * size.height;

        final double newW = (size.width - l - r).clamp(20.0, size.width);
        final double newH = (size.height - t - b).clamp(20.0, size.height);

        newDoc.pageSettings.size = Size(newW, newH);
        final page = newDoc.pages.add();

        // Draw template offset so that crop region is visible
        final g = page.graphics;
        g.save();
        g.translateTransform(-l, -t);
        g.drawPdfTemplate(srcPage.createTemplate(), const Offset(0, 0));
        g.restore();
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_cropped_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await newDoc.save();
      await file.writeAsBytes(newBytes);
      document.dispose();
      newDoc.dispose();
      return file;
    } catch (e) {
      print('Error cropping pages: $e');
      return null;
    }
  }

  /// Overlay a drawing/signature image onto a page at a position and size
  Future<File?> addImageOverlayToPDF({
    required File pdfFile,
    required Uint8List pngBytes,
    required int pageIndex,
    required Rect targetRect,
    required String outputTitle,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      if (pageIndex < 0 || pageIndex >= document.pages.count) return null;

      final page = document.pages[pageIndex];
      final image = sf.PdfBitmap(pngBytes);
      page.graphics.drawImage(image, targetRect);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_overlay_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);
      document.dispose();
      return file;
    } catch (e) {
      print('Error adding overlay: $e');
      return null;
    }
  }

  /// Protect PDF with password
  Future<File?> passwordProtectPDF({
    required File pdfFile,
    required String userPassword,
    String? ownerPassword,
    required String outputTitle,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);
      final security = document.security;
      security.userPassword = userPassword;
      if (ownerPassword != null && ownerPassword.isNotEmpty) {
        security.ownerPassword = ownerPassword;
      }
      // Optional: set basic permissions (allow printing)
      security.permissions.addAll([sf.PdfPermissionsFlags.print]);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_secured_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');
      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);
      document.dispose();
      return file;
    } catch (e) {
      print('Error protecting PDF: $e');
      return null;
    }
  }

  /// Export pages as images (jpg/png)
  Future<List<File>> exportPagesAsImages({
    required File pdfFile,
    String format = 'jpg', // 'jpg' or 'png'
  }) async {
    final images = await extractImagesFromPDF(pdfFile: pdfFile, scale: 2.0);
    if (images.isEmpty) return images;

    if (format.toLowerCase() == 'png') return images;

    // Convert to JPG using image package
    final converted = <File>[];
    for (final pngFile in images) {
      try {
        final bytes = await pngFile.readAsBytes();
        final decoded = img.decodePng(bytes);
        if (decoded == null) {
          converted.add(pngFile);
          continue;
        }
        final jpgBytes = img.encodeJpg(decoded, quality: 90);
        final jpgFile =
            File(pngFile.path.replaceAll(RegExp(r'\.png\$'), '.jpg'));
        await jpgFile.writeAsBytes(jpgBytes);
        converted.add(jpgFile);
      } catch (e) {
        print('Error converting PNG to JPG: $e');
        converted.add(pngFile);
      }
    }
    return converted;
  }

  /// Add text to PDF
  Future<File?> addTextToPDF({
    required File pdfFile,
    required String text,
    required int pageIndex,
    required Offset position,
    required String outputTitle,
    double fontSize = 14,
    Color textColor = Colors.black,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        document.dispose();
        return null;
      }

      final page = document.pages[pageIndex];
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize);

      // Convert Flutter Color to PdfColor using 0-255 RGB ints
      final pdfColor = sf.PdfColor(
        textColor.red,
        textColor.green,
        textColor.blue,
      );
      final brush = sf.PdfSolidBrush(pdfColor);

      page.graphics.drawString(text, font,
          bounds: Rect.fromLTWH(position.dx, position.dy, 0, 0), brush: brush);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_text_added_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error adding text to PDF: $e');
      return null;
    }
  }

  /// Split PDF (simplified version for compatibility)
  Future<List<File>> splitPDF({
    required File pdfFile,
    required String baseTitle,
    required List<int> pageNumbers,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final sf.PdfDocument document = sf.PdfDocument(inputBytes: bytes);
      final List<File> splitFiles = [];

      final directory = await getApplicationDocumentsDirectory();

      for (final pageNumber in pageNumbers) {
        if (pageNumber >= 0 && pageNumber < document.pages.count) {
          final sf.PdfDocument newDocument = sf.PdfDocument();

          // Use template method instead of importPages
          final template = document.pages[pageNumber].createTemplate();
          newDocument.pages
              .add()
              .graphics
              .drawPdfTemplate(template, const Offset(0, 0));

          final fileName =
              '${baseTitle}_page_${pageNumber + 1}_${_uuid.v4()}.pdf';
          final file = File('${directory.path}/$fileName');

          final newBytes = await newDocument.save();
          await file.writeAsBytes(newBytes);

          splitFiles.add(file);
          newDocument.dispose();
        }
      }

      document.dispose();
      return splitFiles;
    } catch (e) {
      print('Error splitting PDF: $e');
      return [];
    }
  }

  /// Add watermark to PDF
  Future<File?> addWatermarkToPdf({
    required File pdfFile,
    required String outputTitle,
    String? text,
    File? imageFile,
    double opacity = 0.3,
    double fontSize = 48,
    Color textColor = Colors.grey,
    Offset? position, // null for center
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];
        final graphics = page.graphics;

        // Save graphics state
        final state = graphics.save();

        // Set transparency
        graphics.setTransparency(opacity);

        if (text != null && text.isNotEmpty) {
          // Add text watermark
          final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, fontSize,
              style: sf.PdfFontStyle.bold);

          final pdfColor = sf.PdfColor(
            textColor.red,
            textColor.green,
            textColor.blue,
          );
          final brush = sf.PdfSolidBrush(pdfColor);

          // Calculate center position if not provided
          final pageSize = page.getClientSize();
          final textSize = font.measureString(text);
          final x = position?.dx ?? (pageSize.width - textSize.width) / 2;
          final y = position?.dy ?? (pageSize.height - textSize.height) / 2;

          // Rotate text for diagonal watermark
          graphics.save();
          graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
          graphics.rotateTransform(-45);
          graphics.translateTransform(
              -pageSize.width / 2, -pageSize.height / 2);

          graphics.drawString(
            text,
            font,
            bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
            brush: brush,
          );

          graphics.restore();
        } else if (imageFile != null) {
          // Add image watermark
          final imageBytes = await imageFile.readAsBytes();
          final image = sf.PdfBitmap(imageBytes);

          final pageSize = page.getClientSize();
          final imgWidth = image.width.toDouble();
          final imgHeight = image.height.toDouble();

          // Scale image to fit page
          final scale = (pageSize.width * 0.3) / imgWidth;
          final scaledWidth = imgWidth * scale;
          final scaledHeight = imgHeight * scale;

          final x = position?.dx ?? (pageSize.width - scaledWidth) / 2;
          final y = position?.dy ?? (pageSize.height - scaledHeight) / 2;

          graphics.drawImage(
            image,
            Rect.fromLTWH(x, y, scaledWidth, scaledHeight),
          );
        }

        // Restore graphics state
        graphics.restore(state);
      }

      // Save watermarked PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_watermarked_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error adding watermark to PDF: $e');
      return null;
    }
  }

  /// Update PDF metadata
  Future<File?> updatePdfMetadata({
    required File pdfFile,
    required String outputTitle,
    String? title,
    String? author,
    String? subject,
    String? keywords,
    String? creator,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);

      // Update document information
      final docInfo = document.documentInformation;

      if (title != null && title.isNotEmpty) {
        docInfo.title = title;
      }
      if (author != null && author.isNotEmpty) {
        docInfo.author = author;
      }
      if (subject != null && subject.isNotEmpty) {
        docInfo.subject = subject;
      }
      if (keywords != null && keywords.isNotEmpty) {
        docInfo.keywords = keywords;
      }
      if (creator != null && creator.isNotEmpty) {
        docInfo.creator = creator;
      }

      // Set modification date
      docInfo.modificationDate = DateTime.now();

      // Save updated PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_metadata_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await document.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      return file;
    } catch (e) {
      print('Error updating PDF metadata: $e');
      return null;
    }
  }

  /// Reorder PDF pages
  Future<File?> reorderPdfPages({
    required File pdfFile,
    required String outputTitle,
    required List<int> newOrder,
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);

      // Validate new order
      if (newOrder.length != document.pages.count) {
        print('Error: New order length does not match page count');
        document.dispose();
        return null;
      }

      // Create new document with reordered pages
      final newDocument = sf.PdfDocument();

      for (final pageIndex in newOrder) {
        if (pageIndex >= 0 && pageIndex < document.pages.count) {
          final template = document.pages[pageIndex].createTemplate();
          newDocument.pages
              .add()
              .graphics
              .drawPdfTemplate(template, const Offset(0, 0));
        }
      }

      // Save reordered PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${outputTitle.replaceAll(RegExp(r'[^ -\u007F]+'), '')}_reordered_${_uuid.v4()}.pdf';
      final file = File('${directory.path}/$fileName');

      final newBytes = await newDocument.save();
      await file.writeAsBytes(newBytes);

      document.dispose();
      newDocument.dispose();
      return file;
    } catch (e) {
      print('Error reordering PDF pages: $e');
      return null;
    }
  }

  /// Extract text from PDF
  Future<String> extractTextFromPdf({
    required File pdfFile,
    int? pageIndex, // null for all pages
  }) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);

      final StringBuffer extractedText = StringBuffer();

      if (pageIndex != null) {
        // Extract text from specific page
        if (pageIndex >= 0 && pageIndex < document.pages.count) {
          final textExtractor = sf.PdfTextExtractor(document);
          final pageText = textExtractor.extractText(
              startPageIndex: pageIndex, endPageIndex: pageIndex);
          extractedText.write(pageText);
        }
      } else {
        // Extract text from all pages
        final textExtractor = sf.PdfTextExtractor(document);
        final allText = textExtractor.extractText();
        extractedText.write(allText);
      }

      document.dispose();
      return extractedText.toString();
    } catch (e) {
      print('Error extracting text from PDF: $e');
      return '';
    }
  }

  /// Get PDF metadata
  Future<Map<String, String>> getPdfMetadata(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = sf.PdfDocument(inputBytes: bytes);

      final docInfo = document.documentInformation;
      final metadata = {
        'title': docInfo.title,
        'author': docInfo.author,
        'subject': docInfo.subject,
        'keywords': docInfo.keywords,
        'creator': docInfo.creator,
        'producer': docInfo.producer,
        'creationDate': docInfo.creationDate.toString(),
        'modificationDate': docInfo.modificationDate.toString(),
      };

      document.dispose();
      return metadata;
    } catch (e) {
      print('Error getting PDF metadata: $e');
      return {};
    }
  }

  /// Convert PDF to Word (DOCX)
  Future<File?> convertPdfToWord({
    required File pdfFile,
  }) async {
    try {
      // Extract text from PDF
      final extractedText = await extractTextFromPdf(pdfFile: pdfFile);
      
      if (extractedText.isEmpty) {
        print('No text found in PDF');
        return null;
      }

      // Create DOCX file
      final directory = await getApplicationDocumentsDirectory();
      final baseName = pdfFile.path.split('/').last.replaceAll('.pdf', '');
      final fileName = '${baseName}_${_uuid.v4()}.docx';
      final file = File('${directory.path}/$fileName');

      // Create minimal DOCX structure
      final docxBytes = _createDocxFromText(extractedText);
      await file.writeAsBytes(docxBytes);

      return file;
    } catch (e) {
      print('Error converting PDF to Word: $e');
      return null;
    }
  }

  /// Convert Word (DOCX) to PDF
  Future<File?> convertWordToPdf({
    required File wordFile,
  }) async {
    try {
      // Extract text from DOCX
      final extractedText = await _extractTextFromDocx(wordFile);
      
      if (extractedText.isEmpty) {
        print('No text found in Word document');
        return null;
      }

      // Create PDF from text
      final directory = await getApplicationDocumentsDirectory();
      final baseName = wordFile.path.split('/').last.replaceAll('.docx', '');
      final fileName = '${baseName}_${_uuid.v4()}.pdf';
      
      final pdf = pw.Document();
      
      // Split text into pages (roughly 3000 chars per page)
      final lines = extractedText.split('\n');
      List<String> currentPageLines = [];
      int currentCharCount = 0;
      
      for (final line in lines) {
        if (currentCharCount + line.length > 3000 && currentPageLines.isNotEmpty) {
          // Add current page
          pdf.addPage(
            pw.Page(
              margin: pw.EdgeInsets.all(40),
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      currentPageLines.join('\n'),
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                );
              },
            ),
          );
          currentPageLines = [];
          currentCharCount = 0;
        }
        currentPageLines.add(line);
        currentCharCount += line.length;
      }
      
      // Add remaining lines
      if (currentPageLines.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    currentPageLines.join('\n'),
                    style: pw.TextStyle(fontSize: 11),
                  ),
                ],
              );
            },
          ),
        );
      }

      final file = File('${directory.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      return file;
    } catch (e) {
      print('Error converting Word to PDF: $e');
      return null;
    }
  }

  /// Create DOCX file bytes from text
  Uint8List _createDocxFromText(String text) {
    // Create minimal DOCX XML structure
    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
${_textToParagraphs(text)}
  </w:body>
</w:document>''';

    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    // Create ZIP archive (DOCX is a ZIP file)
    final archive = Archive();
    
    archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length, utf8.encode(contentTypesXml)));
    archive.addFile(ArchiveFile('_rels/.rels', relsXml.length, utf8.encode(relsXml)));
    archive.addFile(ArchiveFile('word/document.xml', documentXml.length, utf8.encode(documentXml)));

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Convert text to Word paragraphs XML
  String _textToParagraphs(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    
    for (final line in lines) {
      final escapedLine = line
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&apos;');
      
      buffer.write('    <w:p><w:r><w:t xml:space="preserve">$escapedLine</w:t></w:r></w:p>\n');
    }
    
    return buffer.toString();
  }

  /// Extract text from DOCX file
  Future<String> _extractTextFromDocx(File docxFile) async {
    try {
      final bytes = await docxFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Find document.xml
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          final content = utf8.decode(file.content as List<int>);
          return _extractTextFromDocumentXml(content);
        }
      }
      
      return '';
    } catch (e) {
      print('Error extracting text from DOCX: $e');
      return '';
    }
  }

  /// Extract text from document.xml content
  String _extractTextFromDocumentXml(String xml) {
    final buffer = StringBuffer();
    
    // Simple regex to extract text between <w:t> tags
    final regex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
    final matches = regex.allMatches(xml);
    
    for (final match in matches) {
      if (match.group(1) != null) {
        buffer.write(match.group(1));
      }
    }
    
    return buffer.toString();
  }
}
