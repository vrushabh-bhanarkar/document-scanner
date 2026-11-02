import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/offline_scanner.dart';
import '../services/cloud_sync_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final OfflineScannerService _offlineScanner = OfflineScannerService();
  final CloudSyncService _cloudSync = CloudSyncService();
  final ImagePicker _picker = ImagePicker();

  File? _capturedImage;
  String _extractedText = '';
  File? _generatedPdf;
  bool _isProcessing = false;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _offlineScanner.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final pro = await _cloudSync.checkIsPro();
    if (mounted) setState(() => _isPro = pro);
  }

  // 100% Offline: Take picture & extract text using ML Kit
  Future<void> _captureAndProcess(
      [ImageSource source = ImageSource.camera]) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return;

      if (!mounted) return;
      setState(() {
        _isProcessing = true;
        _capturedImage = File(photo.path);
      });

      final text = await _offlineScanner.extractTextOffline(_capturedImage!);
      final pdf = await _offlineScanner.generatePdfLocally(
        imageFiles: [_capturedImage!],
        fileName: 'Scan_${DateTime.now().millisecondsSinceEpoch}',
        isProUser: _isPro,
      );

      if (mounted) {
        setState(() {
          _extractedText = text.isEmpty ? 'No text detected in image.' : text;
          _generatedPdf = pdf;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 100% Offline: Direct share via system share sheet
  void _sharePdfLocally() {
    if (_generatedPdf != null) {
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(_generatedPdf!.path)],
          text: 'Exported from SleekScan',
        ),
      );
    }
  }

  // Pro Feature: Sync with Cloud / Web
  Future<void> _syncToCloud() async {
    if (_generatedPdf == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing document to cloud...')),
      );

      await _cloudSync.syncDocumentToCloud(
        pdfFile: _generatedPdf!,
        title:
            'Document_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().hour}${DateTime.now().minute}',
        extractedText: _extractedText,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully synced! Available on your Web Portal.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SleekScan (Offline Core)'),
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _isPro ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _isPro ? 'PRO PLAN' : 'FREE (OFFLINE)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isPro ? Colors.green.shade800 : Colors.black87,
                ),
              ),
            ),
          )
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing on-device (Offline OCR & PDF)...',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_capturedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_capturedImage!,
                          height: 260, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Extracted OCR text box (Offline ML Kit)
                  if (_extractedText.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recognized Text (Offline OCR)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _extractedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Copied to clipboard!')),
                            );
                          },
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _extractedText,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Scan Camera'),
                          onPressed: () =>
                              _captureAndProcess(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick Image'),
                          onPressed: () =>
                              _captureAndProcess(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                  if (_generatedPdf != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Export PDF (Offline Share)'),
                      onPressed: _sharePdfLocally,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Sync to Web Portal (Pro)'),
                      onPressed: _syncToCloud,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
