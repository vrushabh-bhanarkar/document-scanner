import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/advanced_scanner_service.dart';
import '../services/offline_scanner.dart';
import '../services/cloud_sync_service.dart';
import 'signature_screen.dart';
import 'paywall_screen.dart';

/// Primary Document Scanner Screen for SleekScan
/// Implements 100% offline core scanning, local watermark engine, e-signature drawer,
/// native share sheet export, and Pro cloud sync to Supabase.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final AdvancedScannerService _advancedScanner = AdvancedScannerService();
  final OfflineScannerService _offlineScanner = OfflineScannerService();
  final CloudSyncService _cloudSync = CloudSyncService();

  List<File> _scannedPages = [];
  String _extractedOcrText = '';
  File? _generatedPdf;
  Uint8List? _activeSignatureBytes;

  bool _isProcessing = false;
  String _processingMessage = '';
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _checkEntitlementStatus();
  }

  @override
  void dispose() {
    _advancedScanner.dispose();
    _offlineScanner.dispose();
    super.dispose();
  }

  Future<void> _checkEntitlementStatus() async {
    final pro = await _cloudSync.checkIsPro();
    if (mounted) {
      setState(() => _isPro = pro);
    }
  }

  /// Button 1: "Smart Scan (Offline)" -> Opens native ML Kit document scanner
  Future<void> _handleSmartScan() async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Opening ML Kit Document Scanner (100% Offline)...';
    });

    try {
      final List<File> files = await _advancedScanner.scanDocuments();

      if (files.isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (!mounted) return;
      setState(() {
        _processingMessage = 'Running on-device OCR & generating PDF...';
      });

      // 100% Offline OCR on all scanned pages
      final ocrText = await _offlineScanner.extractTextFromMultiple(files);

      // 100% Offline Multi-Page PDF generation
      final pdf = await _offlineScanner.generatePdfLocally(
        imageFiles: files,
        fileName: 'SleekScan_${DateTime.now().millisecondsSinceEpoch}',
        isProUser: _isPro,
        signatureOverlayBytes: _activeSignatureBytes,
      );

      if (mounted) {
        setState(() {
          _scannedPages = files;
          _extractedOcrText = ocrText;
          _generatedPdf = pdf;
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully scanned ${files.length} page(s) offline!',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanner error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Button 2: "Sign Document" -> Opens signature canvas & stamps signature
  Future<void> _handleSignDocument() async {
    final File? targetImage =
        _scannedPages.isNotEmpty ? _scannedPages.first : null;

    final result = await Navigator.of(context).push<SignatureResult>(
      MaterialPageRoute(
        builder: (context) => SignatureScreen(documentImage: targetImage),
      ),
    );

    if (result == null) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Applying signature & regenerating PDF...';
    });

    try {
      _activeSignatureBytes = result.signatureBytes;

      // If document was stamped directly
      if (result.stampedDocumentFile != null && _scannedPages.isNotEmpty) {
        _scannedPages[0] = result.stampedDocumentFile!;
      }

      if (_scannedPages.isNotEmpty) {
        final updatedPdf = await _offlineScanner.generatePdfLocally(
          imageFiles: _scannedPages,
          fileName: 'SleekScan_Signed_${DateTime.now().millisecondsSinceEpoch}',
          isProUser: _isPro,
          signatureOverlayBytes: result.stampedDocumentFile == null
              ? result.signatureBytes
              : null,
        );

        if (mounted) {
          setState(() {
            _generatedPdf = updatedPdf;
            _isProcessing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('E-Signature stamped onto document successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Signature saved! Perform a scan to apply it to your document.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stamping signature: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Button 3: "Export PDF (Offline)" -> Native share sheet via share_plus
  Future<void> _handleExportPdfOffline() async {
    if (_generatedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scanned document to export yet.')),
      );
      return;
    }

    try {
      await _offlineScanner.sharePdfLocally(
        _generatedPdf!,
        text: _isPro
            ? 'Exported with SleekScan Pro'
            : 'Scanned with SleekScan Free (Offline Core)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Button 4: "Sync to Web (Pro)" -> Checks Pro status, shows paywall if free, syncs if Pro
  Future<void> _handleSyncToWeb() async {
    if (_generatedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan a document before syncing to cloud.'),
        ),
      );
      return;
    }

    // 1. Check Pro status
    await _checkEntitlementStatus();

    if (!_isPro) {
      // Free user: Show paywall
      final purchased = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => const PaywallScreen()),
      );

      if (purchased == true) {
        await _checkEntitlementStatus();
      } else {
        return; // User did not upgrade
      }
    }

    // If upgraded or already Pro:
    if (!_isPro) return;

    setState(() {
      _isProcessing = true;
      _processingMessage = 'Syncing PDF & OCR text to Supabase Cloud...';
    });

    try {
      final docTitle =
          'Scan_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().hour}${DateTime.now().minute}';

      await _cloudSync.syncDocumentToCloud(
        pdfFile: _generatedPdf!,
        title: docTitle,
        extractedText: _extractedOcrText,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.green),
                SizedBox(width: 8),
                Text('Cloud Sync Complete'),
              ],
            ),
            content: const Text(
              'Your document and extracted OCR text have been synced to Supabase Cloud.\n\nYou can now view, search, and export it from the SleekScan Web Portal!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _clearSession() {
    setState(() {
      _scannedPages.clear();
      _extractedOcrText = '';
      _generatedPdf = null;
      _activeSignatureBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'SleekScan Core',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          // Pro Status Pill
          GestureDetector(
            onTap: () async {
              if (!_isPro) {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (context) => const PaywallScreen()),
                );
                if (result == true) _checkEntitlementStatus();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isPro
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPro
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPro ? Icons.verified : Icons.offline_bolt,
                    size: 14,
                    color: _isPro
                        ? const Color(0xFF15803D)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isPro ? 'PRO ACTIVE' : 'FREE (OFFLINE)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isPro
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_scannedPages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              tooltip: 'Reset Scan',
              onPressed: _clearSession,
            ),
        ],
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2563EB)),
                  const SizedBox(height: 20),
                  Text(
                    _processingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Offline Guarantee Callout
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 20, color: Color(0xFF2563EB)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '100% Offline Core: Camera scanning, edge-crop, local OCR & PDF export run directly on your device.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scanned Pages Preview
                  if (_scannedPages.isNotEmpty) ...[
                    SizedBox(
                      height: 260,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _scannedPages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _scannedPages[index],
                                  height: 260,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Page ${index + 1} of ${_scannedPages.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Empty scan placeholder
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No Document Scanned Yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Smart Scan (Offline)" to capture documents with ML Kit edge detection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Extracted OCR text box (Offline ML Kit)
                  if (_extractedOcrText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.text_snippet_outlined,
                                      size: 18, color: Color(0xFF2563EB)),
                                  SizedBox(width: 6),
                                  Text(
                                    'On-Device OCR Text',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy OCR Text',
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _extractedOcrText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('OCR text copied to clipboard!'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 8),
                          Text(
                            _extractedOcrText,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // REQUIRED 4 ACTION BUTTONS
                  // Button 1: "Smart Scan (Offline)"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text(
                      'Smart Scan (Offline)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _handleSmartScan,
                  ),
                  const SizedBox(height: 12),

                  // Button 2: "Sign Document"
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text(
                      'Sign Document',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: _handleSignDocument,
                  ),
                  const SizedBox(height: 12),

                  // Button 3: "Export PDF (Offline)"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      _isPro
                          ? 'Export PDF (Offline - Watermark Free)'
                          : 'Export PDF (Offline)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed:
                        _generatedPdf != null ? _handleExportPdfOffline : null,
                  ),
                  const SizedBox(height: 12),

                  // Button 4: "Sync to Web (Pro)"
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED), // Violet Pro
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sync to Web (Pro)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.lock_open, size: 16),
                      ],
                    ),
                    onPressed: _generatedPdf != null ? _handleSyncToWeb : null,
                  ),

                  if (!_isPro && _generatedPdf != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Free plan includes "Scanned with SleekScan Free" watermark. Upgrade to Pro for watermark-free PDFs and cloud sync.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
