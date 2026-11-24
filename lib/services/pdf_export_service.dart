import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

/// Compression presets for PDF generation
enum PdfCompressionPreset {
  /// High Quality: Full resolution, 95% JPEG quality
  highQuality,

  /// Standard (WhatsApp/Email): Balanced size, max 1600px, 75% quality
  standard,

  /// Compact (<500 KB): Aggressive optimization, max 1000px, 45% quality
  compact,
}

/// Production 100% Offline PDF Engine & Security Service
/// - Multi-page generation with compression presets
/// - AES-128 password encryption toggle
/// - Watermark "Scanned with SleekScan Free" for free users; unbranded for Pro
/// - On-device ML Kit OCR extraction
/// - Native instant file sharing via share_plus
class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// 1. Extract text on-device using Google ML Kit (100% Offline)
  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('[PdfExportService] On-device OCR error: $e');
      return '';
    }
  }

  /// Extract text across multiple pages with section dividers
  Future<String> extractTextFromPages(List<File> imageFiles) async {
    final buffer = StringBuffer();
    for (int i = 0; i < imageFiles.length; i++) {
      final text = await extractText(imageFiles[i]);
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

  /// Helper: Copy extracted text directly to device clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 2. Compress image according to preset
  Future<Uint8List> _processImageForPreset({
    required File imageFile,
    required PdfCompressionPreset preset,
  }) async {
    final rawBytes = await imageFile.readAsBytes();

    if (preset == PdfCompressionPreset.highQuality) {
      // Return original or gently re-encode
      return rawBytes;
    }

    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      int maxDimension;
      int quality;

      switch (preset) {
        case PdfCompressionPreset.highQuality:
          maxDimension = 2400;
          quality = 95;
          break;
        case PdfCompressionPreset.standard:
          maxDimension = 1600;
          quality = 75;
          break;
        case PdfCompressionPreset.compact:
          maxDimension = 1000;
          quality = 45;
          break;
      }

      img.Image resized = decoded;
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        if (decoded.width >= decoded.height) {
          resized = img.copyResize(decoded, width: maxDimension);
        } else {
          resized = img.copyResize(decoded, height: maxDimension);
        }
      }

      final compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('[PdfExportService] Image compression fallback: $e');
      return rawBytes;
    }
  }

  /// 3. Multi-page PDF Generation
  /// - Gated watermarking: "Scanned with SleekScan Free" for free users
  /// - Optional AES-128 password encryption
  /// - Optional e-signature stamping
  Future<File> generatePdf({
    required List<File> imageFiles,
    required String fileName,
    required bool isProUser,
    PdfCompressionPreset preset = PdfCompressionPreset.standard,
    String? password,
    Uint8List? signatureBytes,
    int signaturePageIndex = 0,
  }) async {
    if (imageFiles.isEmpty) {
      throw ArgumentError('At least one image file is required to generate a PDF.');
    }

    final pdf = pw.Document();

    pw.MemoryImage? signatureImage;
    if (signatureBytes != null && signatureBytes.isNotEmpty) {
      signatureImage = pw.MemoryImage(signatureBytes);
    }

    // Process each page
    for (int i = 0; i < imageFiles.length; i++) {
      final processedBytes = await _processImageForPreset(
        imageFile: imageFiles[i],
        preset: preset,
      );
      final pageImage = pw.MemoryImage(processedBytes);

      final stampSignature = (signatureImage != null) &&
          (i == signaturePageIndex || signaturePageIndex == -1);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context context) {
            return pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                // Scanned Document Page Image
                pw.Center(
                  child: pw.Image(pageImage, fit: pw.BoxFit.contain),
                ),

                // Digital E-Signature Stamp Overlay
                if (stampSignature)
                  pw.Positioned(
                    bottom: 45,
                    right: 35,
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
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#0F172A'),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#4F46E5'),
                          width: 0.8,
                        ),
                      ),
                      child: pw.Text(
                        'Scanned with SleekScan Free',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8.5,
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

    final rawPdfBytes = await pdf.save();

    // 4. AES-128 Password Encryption
    Uint8List finalPdfBytes = rawPdfBytes;
    if (password != null && password.trim().isNotEmpty) {
      try {
        final sf.PdfDocument sfDoc = sf.PdfDocument(inputBytes: rawPdfBytes);
        final sf.PdfSecurity security = sfDoc.security;
        security.algorithm = sf.PdfEncryptionAlgorithm.aesx128Bit;
        security.userPassword = password.trim();
        security.ownerPassword = password.trim();
        security.permissions.addAll([
          sf.PdfPermissionsFlags.print,
          sf.PdfPermissionsFlags.editContent,
          sf.PdfPermissionsFlags.copyContent,
          sf.PdfPermissionsFlags.editAnnotations,
        ]);
        final encrypted = await sfDoc.save();
        sfDoc.dispose();
        finalPdfBytes = Uint8List.fromList(encrypted);
        debugPrint('[PdfExportService] Applied AES-128 password encryption.');
      } catch (encErr) {
        debugPrint('[PdfExportService] Encryption error: $encErr');
      }
    }

    // Save to local documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final sanitizedName = fileName
        .replaceAll(RegExp(r'[^\w\.-]'), '_')
        .replaceAll('.pdf', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File('${outputDir.path}/${sanitizedName}_$timestamp.pdf');

    await outputFile.writeAsBytes(finalPdfBytes, flush: true);
    debugPrint(
      '[PdfExportService] Saved PDF (${outputFile.path}) - Size: ${finalPdfBytes.length} bytes',
    );
    return outputFile;
  }

  /// 4. Instant Sharing using share_plus (100% Offline dispatch)
  Future<void> sharePdf({
    required File pdfFile,
    String? subject,
    String? text,
  }) async {
    if (!await pdfFile.exists()) {
      throw FileSystemException('PDF file does not exist', pdfFile.path);
    }

    final xFile = XFile(pdfFile.path, mimeType: 'application/pdf');
    await Share.shareXFiles(
      [xFile],
      subject: subject ?? 'SleekScan Document',
      text: text ?? 'Scanned with SleekScan',
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
