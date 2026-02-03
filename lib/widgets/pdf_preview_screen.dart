import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import '../services/file_management_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final File pdfFile;
  final String title;
  final String? subtitle;
  final bool showDownload;
  final bool showShare;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfFile,
    required this.title,
    this.subtitle,
    this.showDownload = true,
    this.showShare = true,
    this.onDownload,
    this.onShare,
  }) : super(key: key);

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  final FileManagementService _fileService = FileManagementService();
  bool _isDownloading = false;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: const Color(0xFF1E293B), size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.showShare)
            IconButton(
              icon: Icon(Icons.share,
                  color: const Color(0xFF667EEA), size: 22.sp),
              onPressed: widget.onShare ?? _handleShare,
              tooltip: 'Share PDF',
            ),
          if (widget.showDownload)
            _isDownloading
                ? Padding(
                    padding: EdgeInsets.all(16.w),
                    child: SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.download,
                        color: const Color(0xFF10B981), size: 22.sp),
                    onPressed: widget.onDownload ?? _handleDownload,
                    tooltip: 'Download PDF',
                  ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // Page counter
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: const Color(0xFF667EEA),
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _totalPages > 0
                            ? 'Page $_currentPage of $_totalPages'
                            : 'Loading...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF667EEA),
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
              margin: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: SizedBox.expand(
                  child: SfPdfViewer.file(
                    widget.pdfFile,
                    controller: _pdfController,
                    onDocumentLoaded: (details) {
                      setState(() {
                        _totalPages = details.document.pages.count;
                      });
                    },
                    onPageChanged: (details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (widget.showDownload)
                    Expanded(
                      child: _buildActionButton(
                        label: 'Download',
                        icon: Icons.download_rounded,
                        onPressed: widget.onDownload ?? _handleDownload,
                        color: const Color(0xFF10B981),
                        isLoading: _isDownloading,
                      ),
                    ),
                  if (widget.showDownload && widget.showShare)
                    SizedBox(width: 12.w),
                  if (widget.showShare)
                    Expanded(
                      child: _buildActionButton(
                        label: 'Share',
                        icon: Icons.share_rounded,
                        onPressed: widget.onShare ?? _handleShare,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _handleDownload() async {
    try {
      setState(() => _isDownloading = true);

      final result = await _fileService.saveToDownloads(widget.pdfFile);

      setState(() => _isDownloading = false);

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'PDF downloaded successfully!',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                const Expanded(child: Text('Failed to download PDF')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _handleShare() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.pdfFile.path)],
        subject: widget.title,
        text: 'Sharing ${widget.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }
}
