import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// 100% OFFLINE Core Engine
/// Handles on-device text recognition (ML Kit), multi-page PDF generation (pdf package),
/// watermark application for free users, and local file storage/sharing without network access.
class OfflineScannerService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text on-device using Google ML Kit (100% Offline)
  Future<String> extractTextOffline(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('[OfflineScannerService] ML Kit OCR error: $e');
      return '';
    }
  }

  /// Extract text from multiple document pages and concatenate with headers
  Future<String> extractTextFromMultiple(List<File> imageFiles) async {
    final buffer = StringBuffer();
    for (int i = 0; i < imageFiles.length; i++) {
      final text = await extractTextOffline(imageFiles[i]);
      if (text.isNotEmpty) {
        if (imageFiles.length > 1) {
          buffer.writeln('--- Page ${i + 1} ---');
        }
        buffer.writeln(text);
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  /// Generate multi-page PDF locally on device storage.
  /// - Free users: embeds clean text watermark "Scanned with SleekScan Free" at bottom-right of each page.
  /// - Pro users: clean, watermark-free, high-resolution PDF.
  /// - Optional signature overlay: stamped onto designated page.
  Future<File> generatePdfLocally({
    required List<File> imageFiles,
    required String fileName,
    required bool isProUser,
    Uint8List? signatureOverlayBytes,
    int signaturePageIndex = 0,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? signatureImage;
    if (signatureOverlayBytes != null && signatureOverlayBytes.isNotEmpty) {
      signatureImage = pw.MemoryImage(signatureOverlayBytes);
    }

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final imageBytes = await file.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      final shouldStampSignature = (signatureImage != null) &&
          (i == signaturePageIndex || signaturePageIndex == -1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                // Optional E-Signature stamp overlay
                if (shouldStampSignature)
                  pw.Positioned(
                    bottom: 40,
                    right: 30,
                    child: pw.Container(
                      width: 140,
                      height: 60,
                      child: pw.Image(signatureImage!, fit: pw.BoxFit.contain),
                    ),
                  ),
                // Watermark for Free users: bottom-right
                if (!isProUser)
                  pw.Positioned(
                    bottom: 12,
                    right: 12,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xCCFFFFFF),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(
                          color: PdfColor.fromInt(0x33000000),
                          width: 0.5,
                        ),
                      ),
                      child: pw.Text(
                        'Scanned with SleekScan Free',
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF555555),
                          fontSize: 9,
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

    final outputDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${outputDir.path}/scans');
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }

    final safeName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final pdfFile = File('${scansDir.path}/$safeName.pdf');
    await pdfFile.writeAsBytes(await pdf.save());

    debugPrint(
      '[OfflineScannerService] Generated local PDF at: ${pdfFile.path} (${await pdfFile.length()} bytes, Pro=$isProUser)',
    );
    return pdfFile;
  }

  /// Retrieve all locally saved PDFs from the scans folder (100% Offline)
  Future<List<FileSystemEntity>> getSavedLocalFiles() async {
    final outputDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${outputDir.path}/scans');
    if (await scansDir.exists()) {
      final files = scansDir
          .listSync()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList();
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });
      return files;
    }
    return [];
  }

  /// Share PDF via Android / iOS native share sheet (100% Offline)
  Future<void> sharePdfLocally(File pdfFile, {String? text}) async {
    if (!await pdfFile.exists()) {
      throw Exception('PDF file does not exist at ${pdfFile.path}');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdfFile.path)],
        text: text ?? 'Exported from SleekScan (Offline Core)',
      ),
    );
  }

  /// Delete a locally saved PDF file
  Future<bool> deleteLocalScan(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[OfflineScannerService] Error deleting file: $e');
      return false;
    }
  }

  /// Release resources
  void dispose() {
    _textRecognizer.close();
  }
}
