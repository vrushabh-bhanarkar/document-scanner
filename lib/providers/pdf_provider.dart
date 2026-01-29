import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class PDFProvider extends ChangeNotifier {
  List<File> _pdfFiles = [];
  File? _currentPDF;
  final _uuid = const Uuid();

  List<File> get pdfFiles => _pdfFiles;
  File? get currentPDF => _currentPDF;

  // Helper method to safely call notifyListeners
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // We're in the build phase, defer the notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      // Safe to call immediately
      notifyListeners();
    }
  }

  // Load existing PDFs from storage
  Future<void> loadPDFs() async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final files = await pdfDir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.pdf'))
        .cast<File>()
        .toList();

    _pdfFiles = files;
    _safeNotifyListeners();
  }

  // Create PDF from images
  Future<File> createPDFFromImages(List<File> images) async {
    final document = PdfDocument();

    for (var image in images) {
      final page = document.pages.add();
      final imageBytes = await image.readAsBytes();
      final pdfImage = PdfBitmap(imageBytes);

      // Calculate aspect ratio to fit image properly
      final pageSize = page.getClientSize();
      final imageWidth = pdfImage.width.toDouble();
      final imageHeight = pdfImage.height.toDouble();
      final ratio = imageWidth / imageHeight;

      double width = pageSize.width;
      double height = width / ratio;

      if (height > pageSize.height) {
        height = pageSize.height;
        width = height * ratio;
      }

      // Center the image on the page
      final x = (pageSize.width - width) / 2;
      final y = (pageSize.height - height) / 2;

      page.graphics.drawImage(pdfImage, Rect.fromLTWH(x, y, width, height));
    }

    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final fileName = 'document_${_uuid.v4()}.pdf';
    final filePath = path.join(pdfDir.path, fileName);

    final file = File(filePath);
    final bytes = await document.save();
    await file.writeAsBytes(bytes);
    document.dispose();

    _pdfFiles.add(file);
    _currentPDF = file;
    _safeNotifyListeners();

    return file;
  }

  // Split PDF into individual pages
  Future<List<File>> splitPDF(File pdfFile, List<int> pageNumbers) async {
    final inputBytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: inputBytes);
    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final List<File> splitFiles = [];

    for (var pageNumber in pageNumbers) {
      if (pageNumber > 0 && pageNumber <= document.pages.count) {
        final newDocument = PdfDocument();
        final newPage = newDocument.pages.add();
        final page = document.pages[pageNumber - 1];
        newPage.graphics.drawPdfTemplate(
          PdfTemplate(page.size.width, page.size.height),
          Offset.zero,
        );

        final fileName = 'split_page_${pageNumber}_${_uuid.v4()}.pdf';
        final filePath = path.join(pdfDir.path, fileName);
        final file = File(filePath);

        final bytes = await newDocument.save();
        await file.writeAsBytes(bytes);
        newDocument.dispose();

        splitFiles.add(file);
        _pdfFiles.add(file);
      }
    }

    document.dispose();
    _safeNotifyListeners();
    return splitFiles;
  }

  // Add signature to PDF
  Future<File> addSignatureToPDF(
      File pdfFile, File signatureImage, int pageNumber) async {
    final inputBytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: inputBytes);
    final signatureBytes = await signatureImage.readAsBytes();
    final signatureBitmap = PdfBitmap(signatureBytes);

    if (pageNumber > 0 && pageNumber <= document.pages.count) {
      final page = document.pages[pageNumber - 1];
      final pageSize = page.getClientSize();

      // Add signature at bottom right corner
      final signatureWidth = pageSize.width * 0.25;
      final signatureHeight =
          signatureWidth * (signatureBitmap.height / signatureBitmap.width);

      page.graphics.drawImage(
        signatureBitmap,
        Rect.fromLTWH(
          pageSize.width - signatureWidth - 20,
          pageSize.height - signatureHeight - 20,
          signatureWidth,
          signatureHeight,
        ),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final fileName = 'signed_${_uuid.v4()}.pdf';
    final filePath = path.join(pdfDir.path, fileName);
    final file = File(filePath);

    final bytes = await document.save();
    await file.writeAsBytes(bytes);
    document.dispose();

    _pdfFiles.add(file);
    _currentPDF = file;
    _safeNotifyListeners();

    return file;
  }

  // Merge multiple PDFs
  Future<File> mergePDFs(List<File> pdfFiles) async {
    final document = PdfDocument();

    for (var pdfFile in pdfFiles) {
      final inputBytes = await pdfFile.readAsBytes();
      final pdf = PdfDocument(inputBytes: inputBytes);

      for (int i = 0; i < pdf.pages.count; i++) {
        final newPage = document.pages.add();
        final page = pdf.pages[i];
        newPage.graphics.drawPdfTemplate(
          PdfTemplate(page.size.width, page.size.height),
          Offset.zero,
        );
      }

      pdf.dispose();
    }

    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final fileName = 'merged_${_uuid.v4()}.pdf';
    final filePath = path.join(pdfDir.path, fileName);
    final file = File(filePath);

    final bytes = await document.save();
    await file.writeAsBytes(bytes);
    document.dispose();

    _pdfFiles.add(file);
    _currentPDF = file;
    _safeNotifyListeners();

    return file;
  }

  // Extract text from PDF using OCR
  Future<String> extractTextFromPDF(File pdfFile) async {
    // This would require additional OCR processing
    // For now, returning a placeholder
    return "Text extraction feature will be implemented with OCR";
  }

  // Add text annotation to PDF
  Future<File> addTextToPDF(
      File pdfFile, String text, int pageNumber, Offset position) async {
    final inputBytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: inputBytes);

    if (pageNumber > 0 && pageNumber <= document.pages.count) {
      final page = document.pages[pageNumber - 1];
      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

      page.graphics.drawString(
        text,
        font,
        bounds: Rect.fromLTWH(position.dx, position.dy, 200, 50),
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(path.join(directory.path, 'pdfs'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    final fileName = 'annotated_${_uuid.v4()}.pdf';
    final filePath = path.join(pdfDir.path, fileName);
    final file = File(filePath);

    final bytes = await document.save();
    await file.writeAsBytes(bytes);
    document.dispose();

    _pdfFiles.add(file);
    _currentPDF = file;
    _safeNotifyListeners();

    return file;
  }

  // Delete PDF
  Future<void> deletePDF(File pdfFile) async {
    if (await pdfFile.exists()) {
      await pdfFile.delete();
      _pdfFiles.remove(pdfFile);
      if (_currentPDF == pdfFile) {
        _currentPDF = _pdfFiles.isNotEmpty ? _pdfFiles.first : null;
      }
      _safeNotifyListeners();
    }
  }

  // Get PDF page count
  Future<int> getPDFPageCount(File pdfFile) async {
    final inputBytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: inputBytes);
    final pageCount = document.pages.count;
    document.dispose();
    return pageCount;
  }
}
