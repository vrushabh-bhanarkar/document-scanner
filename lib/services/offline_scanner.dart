import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 100% OFFLINE: Requires zero network calls or server infrastructure.
class OfflineScannerService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text on-device using Google ML Kit (Offline)
  Future<String> extractTextOffline(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Generate multi-page PDF locally on device storage
  /// Adds a watermark for free users; generates a clean document for Pro users.
  Future<File> generatePdfLocally({
    required List<File> imageFiles,
    required String fileName,
    required bool isProUser,
  }) async {
    final pdf = pw.Document();

    for (var file in imageFiles) {
      final imageBytes = await file.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
                if (!isProUser)
                  pw.Positioned(
                    bottom: 10,
                    right: 10,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: PdfColors.grey200,
                      child: pw.Text(
                        'Scanned with SleekScan Free',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
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
    return pdfFile;
  }

  /// Retrieve all locally saved PDFs (Zero internet needed)
  Future<List<FileSystemEntity>> getSavedLocalFiles() async {
    final outputDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory('${outputDir.path}/scans');
    if (await scansDir.exists()) {
      return scansDir.listSync().where((f) => f.path.endsWith('.pdf')).toList();
    }
    return [];
  }

  void dispose() {
    _textRecognizer.close();
  }
}
