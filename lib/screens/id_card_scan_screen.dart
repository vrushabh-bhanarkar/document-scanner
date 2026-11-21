import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import 'signature_screen.dart';

enum IdScanStep {
  captureFront,
  reviewFront,
  captureBack,
  reviewBack,
  previewStitched,
}

/// Two-Sided ID Card Mode
/// - Two-step capture flow (Front and Back)
/// - Auto-stitches both card sides onto a single A4 portrait page
/// - Clean margins and dashed separation lines
/// - 100% Offline execution with instant PDF export, OCR, and share
class IdCardScanScreen extends StatefulWidget {
  const IdCardScanScreen({super.key});

  @override
  State<IdCardScanScreen> createState() => _IdCardScanScreenState();
}

class _IdCardScanScreenState extends State<IdCardScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final PdfExportService _pdfService = PdfExportService();

  IdScanStep _currentStep = IdScanStep.captureFront;
  File? _frontImage;
  File? _backImage;
  File? _stitchedPdfFile;

  bool _isProcessing = false;
  String _ocrText = '';
  Uint8List? _stampedSignature;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (picked == null) return;

      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
          _currentStep = IdScanStep.reviewFront;
        } else {
          _backImage = File(picked.path);
          _currentStep = IdScanStep.reviewBack;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture card: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  /// Auto-stitches Front and Back card sides onto a single A4 portrait page
  Future<void> _stitchIdCards() async {
    if (_frontImage == null || _backImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final subProvider = context.read<SubscriptionProvider>();
      final isPro = subProvider.isPro;

      final frontBytes = await _frontImage!.readAsBytes();
      final backBytes = await _backImage!.readAsBytes();

      final frontImg = pw.MemoryImage(frontBytes);
      final backImg = pw.MemoryImage(backBytes);

      pw.MemoryImage? sigImg;
      if (_stampedSignature != null) {
        sigImg = pw.MemoryImage(_stampedSignature!);
      }

      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36), // ~0.5 inch clean margin
          build: (pw.Context ctx) {
            return pw.Stack(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Top Header
                    pw.Center(
                      child: pw.Text(
                        'IDENTIFICATION CARD RECORD',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0F172A'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 16),

                    // Front Card Section
                    pw.Text(
                      'FRONT SIDE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#4F46E5'),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 320,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#CBD5E1'),
                          width: 1,
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 7,
                        verticalRadius: 7,
                        child: pw.Center(
                          child: pw.Image(frontImg, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 28),

                    // Dashed Separation Line
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            height: 1,
                            color: PdfColor.fromHex('#94A3B8'),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                          child: pw.Text(
                            '- - - - - - CUT OR FOLD ALONG LINE - - - - - -',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColor.fromHex('#64748B'),
                            ),
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Container(
                            height: 1,
                            color: PdfColor.fromHex('#94A3B8'),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 28),

                    // Back Card Section
                    pw.Text(
                      'BACK SIDE',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#4F46E5'),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Container(
                      width: 320,
                      height: 200,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#CBD5E1'),
                          width: 1,
                        ),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 7,
                        verticalRadius: 7,
                        child: pw.Center(
                          child: pw.Image(backImg, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),

                    pw.Spacer(),

                    // Timestamp info footer
                    pw.Center(
                      child: pw.Text(
                        'Generated with SleekScan ID Engine • ${DateTime.now().toLocal().toString().split('.')[0]}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromHex('#94A3B8'),
                        ),
                      ),
                    ),
                  ],
                ),

                // Signature Stamp
                if (sigImg != null)
                  pw.Positioned(
                    bottom: 30,
                    right: 20,
                    child: pw.Container(
                      width: 120,
                      height: 50,
                      child: pw.Image(sigImg, fit: pw.BoxFit.contain),
                    ),
                  ),

                // Watermark for Free users
                if (!isPro)
                  pw.Positioned(
                    bottom: 0,
                    right: 0,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#0F172A'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'Scanned with SleekScan Free',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      final rawBytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final pdfPath =
          '${dir.path}/ID_Card_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(rawBytes, flush: true);

      // Extract OCR text from both sides
      final frontText = await _pdfService.extractText(_frontImage!);
      final backText = await _pdfService.extractText(_backImage!);
      _ocrText = [
        '=== ID CARD FRONT ===',
        frontText,
        '=== ID CARD BACK ===',
        backText,
      ].join('\n\n');

      setState(() {
        _stitchedPdfFile = file;
        _currentStep = IdScanStep.previewStitched;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stitch ID cards: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Future<void> _openSignatureCanvas() async {
    final result = await Navigator.of(context).push<SignatureResult>(
      MaterialPageRoute(
        builder: (_) => const SignatureScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _stampedSignature = result.signatureBytes;
      });
      // Re-stitch with signature
      await _stitchIdCards();
    }
  }

  Future<void> _saveToDocuments() async {
    if (_stitchedPdfFile == null || _frontImage == null) return;

    try {
      final docProvider = context.read<DocumentProvider>();
      await docProvider.createDocument(
        name: 'ID_Card_${DateTime.now().millisecondsSinceEpoch}',
        imagePath: _frontImage!.path,
        pdfPath: _stitchedPdfFile!.path,
        extractedText: _ocrText,
        pageImagePaths: [_frontImage!.path, _backImage!.path],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Card saved to your documents!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save error: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      appBar: AppBar(
        title: const Text('Two-Sided ID Card Mode'),
        backgroundColor: AppTheme.darkSlate,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep == IdScanStep.previewStitched) {
              setState(() => _currentStep = IdScanStep.reviewBack);
            } else if (_currentStep == IdScanStep.reviewBack) {
              setState(() => _currentStep = IdScanStep.reviewFront);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.indigo),
                  SizedBox(height: 16),
                  Text(
                    'Auto-stitching A4 ID Document...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case IdScanStep.captureFront:
        return _buildCaptureUI(isFront: true);
      case IdScanStep.reviewFront:
        return _buildReviewUI(isFront: true);
      case IdScanStep.captureBack:
        return _buildCaptureUI(isFront: false);
      case IdScanStep.reviewBack:
        return _buildReviewUI(isFront: false);
      case IdScanStep.previewStitched:
        return _buildStitchedPreviewUI();
    }
  }

  Widget _buildCaptureUI({required bool isFront}) {
    final title = isFront ? 'Step 1: Front of ID Card' : 'Step 2: Back of ID Card';
    final subtitle = isFront
        ? 'Align the front side of the ID card inside the frame'
        : 'Flip card and align the back side inside the frame';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress Steps
        Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.indigo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isFront ? AppTheme.borderDark : AppTheme.indigo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 30),

        // Simulated ID Card Viewport Guide
        AspectRatio(
          aspectRatio: 1.586, // Standard ID-1 card aspect ratio (85.6mm x 53.98mm)
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.indigoLight.withOpacity(0.8),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFront
                            ? Icons.credit_card
                            : Icons.flip_to_back,
                        size: 54,
                        color: AppTheme.indigoLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isFront ? 'FRONT SIDE' : 'BACK SIDE',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Capture triggers
        ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera, isFront),
          icon: const Icon(Icons.camera_alt),
          label: const Text('Take Photo with Camera'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery, isFront),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: AppTheme.borderDark),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.photo_library),
          label: const Text('Choose from Gallery'),
        ),
      ],
    );
  }

  Widget _buildReviewUI({required bool isFront}) {
    final imageFile = isFront ? _frontImage : _backImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isFront ? 'Review Front Side' : 'Review Back Side',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (imageFile != null)
          AspectRatio(
            aspectRatio: 1.586,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(imageFile, fit: pw.BoxFit.cover as dynamic),
            ),
          ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = isFront
                        ? IdScanStep.captureFront
                        : IdScanStep.captureBack;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isFront) {
                    setState(() {
                      _currentStep = IdScanStep.captureBack;
                    });
                  } else {
                    _stitchIdCards();
                  }
                },
                child: Text(isFront ? 'Scan Back Side' : 'Stitch A4 Card'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStitchedPreviewUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stitched A4 ID Card',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Auto-stitched with clean margins & dashed fold line',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppTheme.emerald),
              onPressed: () {
                if (_stitchedPdfFile != null) {
                  _pdfService.sharePdf(pdfFile: _stitchedPdfFile!);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Visual Preview Card (simulated A4 portrait page)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(
            surfaceColor: Colors.white,
            borderColor: AppTheme.subtleBorder,
          ),
          child: Column(
            children: [
              const Text(
                'IDENTIFICATION CARD RECORD',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Front Card Preview
              if (_frontImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_frontImage!, height: 120, fit: BoxFit.cover),
                ),

              const SizedBox(height: 16),
              // Dashed Separation Line
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '- - - CUT OR FOLD HERE - - -',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Back Card Preview
              if (_backImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_backImage!, height: 120, fit: BoxFit.cover),
                ),

              const SizedBox(height: 12),
              if (_stampedSignature != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Image.memory(_stampedSignature!, height: 35),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Toolbar
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openSignatureCanvas,
                icon: const Icon(Icons.draw, size: 18),
                label: Text(
                  _stampedSignature == null ? 'Sign Card' : 'Update Sign',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (_ocrText.isNotEmpty) {
                    PdfExportService.copyToClipboard(_ocrText);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID text copied to clipboard!'),
                        backgroundColor: AppTheme.emerald,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy OCR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Save & Export Button
        ElevatedButton.icon(
          onPressed: _saveToDocuments,
          icon: const Icon(Icons.save_alt),
          label: const Text('Save to My Documents'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.indigo,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}
