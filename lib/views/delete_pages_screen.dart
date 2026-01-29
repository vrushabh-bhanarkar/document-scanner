import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';
import '../widgets/native_ad_widget.dart';

class DeletePagesScreen extends StatefulWidget {
  final File? initialPdfFile;

  const DeletePagesScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<DeletePagesScreen> createState() => _DeletePagesScreenState();
}

class _DeletePagesScreenState extends State<DeletePagesScreen> {
  final PDFService _pdfService = PDFService();
  File? selectedPdf;
  int? totalPages;
  bool isLoading = false;
  List<int> pagesToDelete = [];

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
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Delete Pages',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.pink,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (selectedPdf != null && pagesToDelete.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: selectedPdf == null
          ? _buildSelectPdfScreen()
          : _buildDeleteInterface(),
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
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.delete_outline,
                size: 80.sp,
                color: Colors.pink,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Select PDF to Edit',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Choose a PDF file and select pages to delete',
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
              label: const Text('Browse Files'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
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

  Widget _buildDeleteInterface() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Warning: Permanent Action',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Deleted pages cannot be recovered. Make sure to save a backup of your original file.',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // File Info Card
          Container(
            width: double.infinity,
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
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pages: ${totalPages ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (pagesToDelete.isNotEmpty)
                      Text(
                        'Remaining: ${(totalPages ?? 0) - pagesToDelete.length}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Page Selection Card
          if (totalPages != null) ...[
            Container(
              width: double.infinity,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Pages to Delete',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${pagesToDelete.length} selected',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.pink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearSelection,
                          child: const Text('Clear All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectRange,
                          child: const Text('Select Range'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade100,
                            foregroundColor: Colors.pink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8.w,
                      mainAxisSpacing: 8.h,
                      childAspectRatio: 1,
                    ),
                    itemCount: totalPages!,
                    itemBuilder: (context, index) {
                      final pageNumber = index + 1;
                      final isSelected = pagesToDelete.contains(pageNumber);

                      return GestureDetector(
                        onTap: () => _togglePageSelection(pageNumber),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.red : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color:
                                  isSelected ? Colors.red : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$pageNumber',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                              if (isSelected) ...[
                                SizedBox(height: 2.h),
                                Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Action Button
          if (pagesToDelete.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showDeleteConfirmation,
                icon: const Icon(Icons.delete),
                label: Text('Delete ${pagesToDelete.length} Page(s)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: 16.h),

          // Native Ad
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NativeAdWidget(),
          ),
        ],
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
        pagesToDelete.clear();
      });
      _loadPdfInfo();
    }
  }

  void _togglePageSelection(int pageNumber) {
    setState(() {
      if (pagesToDelete.contains(pageNumber)) {
        pagesToDelete.remove(pageNumber);
      } else {
        pagesToDelete.add(pageNumber);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      pagesToDelete.clear();
    });
  }

  void _selectRange() {
    showDialog(
      context: context,
      builder: (context) => _RangeSelectionDialog(
        totalPages: totalPages!,
        onRangeSelected: (start, end) {
          setState(() {
            for (int i = start; i <= end; i++) {
              if (!pagesToDelete.contains(i)) {
                pagesToDelete.add(i);
              }
            }
          });
        },
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24.sp),
            SizedBox(width: 12.w),
            const Text('Confirm Delete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'You are about to delete ${pagesToDelete.length} page(s) from the PDF:'),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Pages: ${pagesToDelete.join(', ')}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'This action cannot be undone. Make sure you have a backup of the original file.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deletePages() async {
    if (selectedPdf == null || pagesToDelete.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final result = await _pdfService.deletePdfPages(
        selectedPdf!,
        pagesToDelete,
      );

      if (result != null) {
        setState(() => isLoading = false);

        // Navigate to preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: result,
              title: 'Edited PDF',
              subtitle: 'Deleted ${pagesToDelete.length} page(s)',
            ),
          ),
        ).then((_) {
          // Go back after preview
          Navigator.pop(context);
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete pages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _RangeSelectionDialog extends StatefulWidget {
  final int totalPages;
  final Function(int start, int end) onRangeSelected;

  const _RangeSelectionDialog({
    required this.totalPages,
    required this.onRangeSelected,
  });

  @override
  _RangeSelectionDialogState createState() => _RangeSelectionDialogState();
}

class _RangeSelectionDialogState extends State<_RangeSelectionDialog> {
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: '1');
    _endController = TextEditingController(text: widget.totalPages.toString());
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Page Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select a range of pages to delete (1 - ${widget.totalPages}):'),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: TextField(
                  controller: _endController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final start = int.tryParse(_startController.text) ?? 1;
            final end = int.tryParse(_endController.text) ?? widget.totalPages;

            if (start >= 1 && end <= widget.totalPages && start <= end) {
              widget.onRangeSelected(start, end);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid range')),
              );
            }
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
