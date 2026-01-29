import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';
import '../widgets/password_protected_dialog.dart';
import '../widgets/native_ad_widget.dart';

class PageReorderScreen extends StatefulWidget {
  final File? initialPdfFile;

  const PageReorderScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<PageReorderScreen> createState() => _PageReorderScreenState();
}

class _PageReorderScreenState extends State<PageReorderScreen> {
  final PDFService _pdfService = PDFService();
  File? selectedPdf;
  bool isLoading = false;
  int? totalPages;
  List<int> pageOrder = [];
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPdfFile != null) {
      selectedPdf = widget.initialPdfFile;
      _loadPdfInfo();
    }
  }

  void _loadPdfInfo() async {
    if (selectedPdf != null) {
      setState(() => isLoading = true);
      totalPages = await _pdfService.getPdfPageCount(selectedPdf!);
      if (totalPages != null) {
        pageOrder = List.generate(totalPages!, (index) => index + 1);
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Reorder Pages',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.amber.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (hasChanges)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _applyReorder,
              tooltip: 'Apply Changes',
            ),
          if (hasChanges)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetOrder,
              tooltip: 'Reset Order',
            ),
        ],
      ),
      body: selectedPdf == null
          ? _buildSelectPdfScreen()
          : _buildReorderInterface(),
    );
  }

  Widget _buildSelectPdfScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.reorder,
                size: 80.sp,
                color: Colors.amber.shade700,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Reorder PDF Pages',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Rearrange the order of pages in your PDF document',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: _selectPdfFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Select PDF File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 16.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderInterface() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // File Info and Controls
        Container(
          padding: EdgeInsets.all(16.w),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      selectedPdf!.path.split('/').last,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pages: ${totalPages ?? 0}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (hasChanges)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Changes made',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _reverseOrder,
                      icon: Icon(Icons.flip, size: 16.sp),
                      label: const Text('Reverse All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade700,
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _randomizeOrder,
                      icon: Icon(Icons.shuffle, size: 16.sp),
                      label: const Text('Shuffle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade100,
                        foregroundColor: Colors.purple.shade700,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Instructions
        Container(
          padding: EdgeInsets.all(16.w),
          color: Colors.amber.shade50,
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.amber.shade700, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Drag and drop pages to reorder them. Long press and drag to move pages.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Page List
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: pageOrder.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final pageNumber = pageOrder[index];
              return _buildPageItem(pageNumber, index);
            },
          ),
        ),

        // Apply Changes Button
        if (hasChanges)
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _applyReorder,
                icon: const Icon(Icons.save),
                label: const Text('Apply New Page Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),

        // Native Ad
        Container(
          padding: EdgeInsets.all(16.w),
          color: Colors.white,
          child: const NativeAdWidget(),
        ),
      ],
    );
  }

  Widget _buildPageItem(int pageNumber, int currentIndex) {
    return Container(
      key: ValueKey('page_$pageNumber'),
      margin: EdgeInsets.only(bottom: 8.h),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber.shade100,
          child: Text(
            '$pageNumber',
            style: TextStyle(
              color: Colors.amber.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Page $pageNumber',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Position: ${currentIndex + 1}',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed:
                  currentIndex > 0 ? () => _movePageUp(currentIndex) : null,
              icon: Icon(
                Icons.keyboard_arrow_up,
                color:
                    currentIndex > 0 ? Colors.amber.shade700 : Colors.grey[400],
              ),
            ),
            IconButton(
              onPressed: currentIndex < pageOrder.length - 1
                  ? () => _movePageDown(currentIndex)
                  : null,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: currentIndex < pageOrder.length - 1
                    ? Colors.amber.shade700
                    : Colors.grey[400],
              ),
            ),
            Icon(
              Icons.drag_handle,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _selectPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedPdf = File(result.files.single.path!);
        hasChanges = false;
      });
      _loadPdfInfo();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final page = pageOrder.removeAt(oldIndex);
      pageOrder.insert(newIndex, page);
      hasChanges = true;
    });
  }

  void _movePageUp(int index) {
    if (index > 0) {
      setState(() {
        final page = pageOrder.removeAt(index);
        pageOrder.insert(index - 1, page);
        hasChanges = true;
      });
    }
  }

  void _movePageDown(int index) {
    if (index < pageOrder.length - 1) {
      setState(() {
        final page = pageOrder.removeAt(index);
        pageOrder.insert(index + 1, page);
        hasChanges = true;
      });
    }
  }

  void _reverseOrder() {
    setState(() {
      pageOrder = pageOrder.reversed.toList();
      hasChanges = true;
    });
  }

  void _randomizeOrder() {
    setState(() {
      pageOrder.shuffle();
      hasChanges = true;
    });
  }

  void _resetOrder() {
    setState(() {
      if (totalPages != null) {
        pageOrder = List.generate(totalPages!, (index) => index + 1);
        hasChanges = false;
      }
    });
  }

  void _applyReorder() async {
    if (selectedPdf == null || !hasChanges) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade700, size: 24.sp),
            SizedBox(width: 12.w),
            const Text('Apply Page Reorder?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will create a new PDF with the reordered pages.'),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber.shade700, size: 18.sp),
                  SizedBox(width: 8.w),
                  const Expanded(
                    child: Text(
                      'Original PDF will remain unchanged',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      // Convert page order from 1-based to 0-based indexing
      final zeroBasedOrder = pageOrder.map((p) => p - 1).toList();

      // Reorder PDF pages using PDFService
      final result = await _pdfService.reorderPdfPages(
        pdfFile: selectedPdf!,
        outputTitle:
            'Reordered_${selectedPdf!.path.split('/').last.replaceAll('.pdf', '')}',
        newOrder: zeroBasedOrder,
      );

      setState(() => isLoading = false);

      if (result != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                const Expanded(child: Text('Pages reordered successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to preview screen with the reordered PDF
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: result,
              title: 'Reordered PDF',
              subtitle: '${totalPages ?? 0} pages reordered',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                const Expanded(child: Text('Failed to reorder pages')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        // Check if it's a password-protected PDF
        if (PasswordProtectedPdfDialog.isPasswordError(e)) {
          PasswordProtectedPdfDialog.show(context, toolName: 'reordered');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error: ${e.toString().replaceAll('Exception:', '').trim()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
