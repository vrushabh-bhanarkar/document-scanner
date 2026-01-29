import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../services/file_management_service.dart';
import '../widgets/pdf_preview_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/native_ad_widget.dart';

class SplitPdfScreen extends StatefulWidget {
  final File pdfFile;

  const SplitPdfScreen({Key? key, required this.pdfFile}) : super(key: key);

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  final PDFService _pdfService = PDFService();
  final FileManagementService _fileService = FileManagementService();
  int totalPages = 0;
  bool isLoading = true;
  bool isSplitting = false;
  SplitMode selectedMode = SplitMode.range;

  // Range split
  int rangeStart = 1;
  int rangeEnd = 1;

  // Split by pages
  List<int> selectedPages = [];

  // Split into parts
  int numberOfParts = 2;

  @override
  void initState() {
    super.initState();
    _loadPdfInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Split PDF',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isLoading)
            TextButton(
              onPressed: isSplitting ? null : _splitPdf,
              child: Text(
                'Split',
                style: TextStyle(
                  color: isSplitting ? Colors.grey : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card
                  Container(
                    margin: EdgeInsets.all(16.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.content_cut,
                            color: Colors.white, size: 32.sp),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Split PDF Document',
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '$totalPages pages • ${widget.pdfFile.path.split('/').last}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Split Mode Selection
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            'Split Options',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        _buildSplitModeOption(
                          SplitMode.range,
                          'Page Range',
                          'Extract specific page range',
                          Icons.view_agenda,
                        ),
                        _buildSplitModeOption(
                          SplitMode.individual,
                          'Individual Pages',
                          'Select specific pages to extract',
                          Icons.pages,
                        ),
                        _buildSplitModeOption(
                          SplitMode.parts,
                          'Equal Parts',
                          'Split into equal parts',
                          Icons.pie_chart,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Split Configuration
                  if (selectedMode == SplitMode.range)
                    _buildRangeConfiguration(),
                  if (selectedMode == SplitMode.individual)
                    _buildIndividualConfiguration(),
                  if (selectedMode == SplitMode.parts)
                    _buildPartsConfiguration(),

                  SizedBox(height: 16.h),

                  // Native Ad
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: NativeAdWidget(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSplitModeOption(
      SplitMode mode, String title, String subtitle, IconData icon) {
    final isSelected = selectedMode == mode;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: InkWell(
        onTap: () => setState(() => selectedMode = mode),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? Colors.red : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.red.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.red : Colors.grey.shade600,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.red : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Colors.red,
                  size: 20.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeConfiguration() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Page Range',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From Page', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: rangeStart,
                          isExpanded: true,
                          items: List.generate(
                            totalPages,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text('Page ${index + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              rangeStart = value!;
                              if (rangeEnd < rangeStart) rangeEnd = rangeStart;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To Page', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: rangeEnd,
                          isExpanded: true,
                          items: List.generate(
                            totalPages - rangeStart + 1,
                            (index) => DropdownMenuItem(
                              value: rangeStart + index,
                              child: Text('Page ${rangeStart + index}'),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => rangeEnd = value!);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Will extract pages $rangeStart to $rangeEnd (${rangeEnd - rangeStart + 1} pages)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualConfiguration() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Individual Pages',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: List.generate(totalPages, (index) {
              final pageNumber = index + 1;
              final isSelected = selectedPages.contains(pageNumber);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedPages.remove(pageNumber);
                    } else {
                      selectedPages.add(pageNumber);
                    }
                    selectedPages.sort();
                  });
                },
                child: Container(
                  width: 60.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$pageNumber',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (selectedPages.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Selected pages: ${selectedPages.join(", ")} (${selectedPages.length} pages)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartsConfiguration() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Split into Equal Parts',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Number of parts:',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
          ),
          SizedBox(height: 8.h),
          Slider(
            value: numberOfParts.toDouble(),
            min: 2,
            max: totalPages.toDouble(),
            divisions: totalPages - 2,
            label: '$numberOfParts parts',
            onChanged: (value) {
              setState(() => numberOfParts = value.round());
            },
          ),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Will create $numberOfParts separate PDFs with approximately ${(totalPages / numberOfParts).ceil()} pages each',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _loadPdfInfo() async {
    try {
      final pageCount = await _pdfService.getPdfPageCount(widget.pdfFile);
      setState(() {
        totalPages = pageCount;
        rangeEnd = pageCount;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Failed to load PDF information');
    }
  }

  void _splitPdf() async {
    if (_isValidConfiguration()) {
      setState(() => isSplitting = true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text('Splitting PDF...', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
        ),
      );

      try {
        List<File> splitFiles = [];

        switch (selectedMode) {
          case SplitMode.range:
            final file = await _pdfService.splitPdfByRange(
              widget.pdfFile,
              rangeStart,
              rangeEnd,
            );
            if (file != null) splitFiles.add(file);
            break;
          case SplitMode.individual:
            splitFiles = await _pdfService.splitPdfByPages(
              widget.pdfFile,
              selectedPages,
            );
            break;
          case SplitMode.parts:
            splitFiles = await _pdfService.splitPdfIntoParts(
              widget.pdfFile,
              numberOfParts,
            );
            break;
        }

        Navigator.pop(context); // Close loading dialog

        if (splitFiles.isNotEmpty && mounted) {
          // Navigate to a results screen showing all split files
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplitPdfResultsScreen(
                splitFiles: splitFiles,
                fileService: _fileService,
              ),
            ),
          ).then((_) {
            // After results screen closes, go back
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          _showErrorDialog('Failed to split PDF');
        }
      } catch (e) {
        Navigator.pop(context);
        _showErrorDialog('Error: $e');
      } finally {
        setState(() => isSplitting = false);
      }
    }
  }

  bool _isValidConfiguration() {
    switch (selectedMode) {
      case SplitMode.range:
        return rangeStart <= rangeEnd;
      case SplitMode.individual:
        return selectedPages.isNotEmpty;
      case SplitMode.parts:
        return numberOfParts >= 2 && numberOfParts <= totalPages;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error, color: Colors.red, size: 48.sp),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

enum SplitMode { range, individual, parts }

// Results screen showing all split PDF files
class SplitPdfResultsScreen extends StatefulWidget {
  final List<File> splitFiles;
  final FileManagementService fileService;

  const SplitPdfResultsScreen({
    Key? key,
    required this.splitFiles,
    required this.fileService,
  }) : super(key: key);

  @override
  State<SplitPdfResultsScreen> createState() => _SplitPdfResultsScreenState();
}

class _SplitPdfResultsScreenState extends State<SplitPdfResultsScreen> {
  int _currentIndex = 0;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Results',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              '${widget.splitFiles.length} files created',
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
          IconButton(
            icon:
                Icon(Icons.share, color: const Color(0xFF667EEA), size: 22.sp),
            onPressed: _shareCurrentFile,
            tooltip: 'Share Current PDF',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // File selector
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select file to preview:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  height: 50.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.splitFiles.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        child: Container(
                          margin: EdgeInsets.only(right: 8.w),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFEF4444)
                                  : Colors.grey.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFEF4444),
                                size: 18.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'File ${index + 1}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Preview using PdfPreviewScreen widget content
          Expanded(
            child: PdfPreviewScreen(
              pdfFile: widget.splitFiles[_currentIndex],
              title: 'Split PDF ${_currentIndex + 1}',
              subtitle:
                  'File ${_currentIndex + 1} of ${widget.splitFiles.length}',
              showDownload: false,
              showShare: false,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Individual download button for current file
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : _downloadCurrentFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.download, size: 18),
                          SizedBox(width: 8.w),
                          Text(
                            'Download File ${_currentIndex + 1}',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Download all and share all buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isDownloading ? null : _downloadAllFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isDownloading
                              ? SizedBox(
                                  height: 18.h,
                                  width: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.download_rounded,
                                        size: 18),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'All (${widget.splitFiles.length})',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _shareAllFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_rounded, size: 18),
                              SizedBox(width: 6.w),
                              Text(
                                'Share All',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadCurrentFile() async {
    setState(() => _isDownloading = true);

    try {
      await widget.fileService.initialize();
      final currentFile = widget.splitFiles[_currentIndex];
      final success = await widget.fileService.saveToDownloads(currentFile);

      setState(() => _isDownloading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                        'File ${_currentIndex + 1} downloaded successfully!'),
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to download file ${_currentIndex + 1}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _downloadAllFiles() async {
    setState(() => _isDownloading = true);

    try {
      await widget.fileService.initialize();
      int successCount = 0;

      for (final file in widget.splitFiles) {
        final success = await widget.fileService.saveToDownloads(file);
        if (success) successCount++;
      }

      setState(() => _isDownloading = false);

      if (mounted) {
        final message = successCount == widget.splitFiles.length
            ? 'All ${widget.splitFiles.length} files downloaded successfully!'
            : 'Downloaded $successCount of ${widget.splitFiles.length} files';

        final color = successCount == widget.splitFiles.length
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  successCount == widget.splitFiles.length
                      ? Icons.check_circle
                      : Icons.warning,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: color,
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
            content: Text('Error downloading files: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _shareCurrentFile() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.splitFiles[_currentIndex].path)],
        subject: 'Split PDF ${_currentIndex + 1}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing file: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _shareAllFiles() async {
    try {
      await Share.shareXFiles(
        widget.splitFiles.map((file) => XFile(file.path)).toList(),
        subject: 'Split PDF Files (${widget.splitFiles.length} files)',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing files: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
