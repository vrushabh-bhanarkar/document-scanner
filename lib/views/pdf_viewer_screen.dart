import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_service.dart';
import '../services/file_management_service.dart';
import 'pdf_editor_screen.dart';
import '../services/notification_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/interstitial_ad_helper.dart';

class PDFViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String title;
  final int pageCount;

  const PDFViewerScreen({
    Key? key,
    required this.pdfFile,
    required this.title,
    required this.pageCount,
  }) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _loadFileSize();
  }

  Future<void> _loadFileSize() async {
    try {
      final size = await widget.pdfFile.length();
      setState(() {
        _fileSize = _formatFileSize(size);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _fileSize = 'Unknown';
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final padding = screenWidth * 0.045;
    final borderRadius = screenWidth * 0.045;
    final iconSize = screenWidth * 0.07;
    final buttonFontSize = screenWidth * 0.045;
    final infoFontSize = screenWidth * 0.04;
    final infoTitleFontSize = screenWidth * 0.045;
    final infoSubtitleFontSize = screenWidth * 0.035;
    final actionButtonHeight = screenHeight * 0.07;
    final actionButtonFont = screenWidth * 0.04;
    final actionButtonIcon = screenWidth * 0.06;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: infoTitleFontSize,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(Icons.share, size: iconSize),
            onPressed: _sharePDF,
            tooltip: 'Share PDF',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        color: const Color(0xFF1E293B), size: iconSize * 0.7),
                    SizedBox(width: padding * 0.5),
                    Text('Edit PDF', style: TextStyle(fontSize: infoFontSize)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save,
                        color: const Color(0xFF1E293B), size: iconSize * 0.7),
                    SizedBox(width: padding * 0.5),
                    Text('Save to Documents',
                        style: TextStyle(fontSize: infoFontSize)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print,
                        color: const Color(0xFF1E293B), size: iconSize * 0.7),
                    SizedBox(width: padding * 0.5),
                    Text('Print PDF', style: TextStyle(fontSize: infoFontSize)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download,
                        color: const Color(0xFF1E293B), size: iconSize * 0.7),
                    SizedBox(width: padding * 0.5),
                    Text('Download', style: TextStyle(fontSize: infoFontSize)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // PDF Info Header
              Container(
                margin: EdgeInsets.all(padding * 1.2),
                padding: EdgeInsets.all(padding * 1.2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius * 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: padding * 1.1),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: infoTitleFontSize,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: padding * 0.2),
                          Text(
                            '${widget.pageCount} pages • ${_fileSize ?? 'Loading...'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: infoSubtitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.7, vertical: padding * 0.4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: iconSize * 0.6,
                          ),
                          SizedBox(width: padding * 0.3),
                          Text(
                            'Ready',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: infoSubtitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // PDF Viewer
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 80), // Add bottom margin for ad
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: _buildPDFViewer(),
                  ),
                ),
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading || _isSaving)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSaving ? 'Saving PDF...' : 'Loading PDF...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildPDFViewer() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // PDF Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'PDF Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.pageCount} pages',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PDF Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SfPdfViewer.file(
                  widget.pdfFile,
                  canShowPaginationDialog: true,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  pageSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PdfEditorScreen(pdfFile: widget.pdfFile, isFromCreatePdf: true),
          ),
        );
        break;
      case 'save':
        _savePDF();
        break;
      case 'print':
        _printPDF();
        break;
      case 'download':
        _downloadPDF();
        break;
    }
  }

  Future<void> _savePDF() async {
    setState(() => _isSaving = true);

    try {
      final fileService = FileManagementService();
      final savedDocument = await fileService.savePDFDocument(
        name: widget.title,
        pdfPath: widget.pdfFile.path,
        imagePaths: [], // We don't have image paths in viewer
      );

      if (savedDocument != null) {
        _showSuccessSnackBar('PDF saved to Documents!');
        await NotificationService().showNotification(
          title: 'File Saved',
          body: 'Your PDF has been saved successfully!',
        );
        InterstitialAdHelper.showInterstitialAd(
          onAdClosed: () async {
            await _showPostSaveOptions(context, widget.pdfFile);
          },
        );
      } else {
        _showErrorSnackBar('Failed to save PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Error saving PDF: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _sharePDF() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.pdfFile.path)],
        text: 'PDF created with Document Scanner',
        subject: widget.title,
      );
    } catch (e) {
      _showErrorSnackBar('Error sharing PDF: $e');
    }
  }

  Future<void> _printPDF() async {
    setState(() => _isSaving = true);

    try {
      final pdfService = PDFService();
      final success = await pdfService.printPDF(widget.pdfFile);

      if (success) {
        _showSuccessSnackBar('Print request sent successfully!');
      } else {
        _showErrorSnackBar('Failed to send print request');
      }
    } catch (e) {
      _showErrorSnackBar('Error printing PDF: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _downloadPDF() async {
    setState(() => _isSaving = true);

    try {
      final fileService = FileManagementService();
      final savedDocument = await fileService.savePDFDocument(
        name: widget.title,
        pdfPath: widget.pdfFile.path,
        imagePaths: [],
      );

      if (savedDocument != null) {
        _showSuccessSnackBar('PDF downloaded to Documents!');
        await NotificationService().showNotification(
          title: 'File Saved',
          body: 'Your PDF has been saved successfully!',
        );
        await _showPostSaveOptions(context, widget.pdfFile);
      } else {
        _showErrorSnackBar('Failed to download PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Error downloading PDF: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showPostSaveOptions(BuildContext context, File file) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Save to Downloads'),
              onTap: () async {
                Navigator.pop(ctx);
                final fileService = FileManagementService();
                final result = await fileService.saveToDownloads(file);
                _showSuccessSnackBar(result
                    ? 'Saved to Downloads!'
                    : 'Failed to save to Downloads');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Recent Downloads'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/recent_downloads');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Saved'),
        content: const Text('Your file has been saved successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
