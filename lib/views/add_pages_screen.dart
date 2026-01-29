import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';
import '../widgets/native_ad_widget.dart';

class AddPagesScreen extends StatefulWidget {
  final File? initialPdfFile;

  const AddPagesScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<AddPagesScreen> createState() => _AddPagesScreenState();
}

class _AddPagesScreenState extends State<AddPagesScreen> {
  final PDFService _pdfService = PDFService();
  File? selectedPdf;
  int? totalPages;
  bool isLoading = false;
  List<File> selectedImages = [];
  List<File> selectedPdfs = [];
  int insertPosition = 1;

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
        insertPosition = totalPages! + 1; // Default to end
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
          'Add Pages',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (selectedPdf != null &&
              (selectedImages.isNotEmpty || selectedPdfs.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _addPages,
            ),
        ],
      ),
      body:
          selectedPdf == null ? _buildSelectPdfScreen() : _buildAddInterface(),
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
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.add_circle_outline,
                size: 80.sp,
                color: Colors.teal,
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
              'Choose a PDF file to add new pages',
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
                backgroundColor: Colors.teal,
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

  Widget _buildAddInterface() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                Text(
                  'Current Pages: ${totalPages ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Content Type Selection
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
                Text(
                  'Add Content',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildContentTypeCard(
                        title: 'Add Images',
                        subtitle: 'Convert images to PDF pages',
                        icon: Icons.image,
                        color: Colors.blue,
                        onTap: _selectImages,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildContentTypeCard(
                        title: 'Merge PDFs',
                        subtitle: 'Add pages from other PDFs',
                        icon: Icons.picture_as_pdf,
                        color: Colors.green,
                        onTap: _selectPdfs,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Selected Images Section
          if (selectedImages.isNotEmpty) ...[
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
                        'Selected Images (${selectedImages.length})',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedImages.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 100.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        final image = selectedImages[index];
                        return Container(
                          width: 80.w,
                          margin: EdgeInsets.only(right: 8.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: Image.file(
                                  image,
                                  width: 80.w,
                                  height: 100.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(2.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Selected PDFs Section
          if (selectedPdfs.isNotEmpty) ...[
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
                        'Selected PDFs (${selectedPdfs.length})',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedPdfs.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  ...selectedPdfs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final pdf = entry.value;
                    return ListTile(
                      leading: Icon(Icons.picture_as_pdf,
                          color: Colors.red, size: 24.sp),
                      title: Text(
                        pdf.path.split('/').last,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedPdfs.removeAt(index);
                          });
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Insert Position Section
          if (totalPages != null &&
              (selectedImages.isNotEmpty || selectedPdfs.isNotEmpty)) ...[
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
                  Text(
                    'Insert Position',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Insert new pages at position: $insertPosition',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Slider(
                    value: insertPosition.toDouble(),
                    min: 1,
                    max: (totalPages! + 1).toDouble(),
                    divisions: totalPages!,
                    label: insertPosition == totalPages! + 1
                        ? 'End'
                        : 'After page $insertPosition',
                    onChanged: (value) {
                      setState(() {
                        insertPosition = value.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Beginning', style: TextStyle(fontSize: 12.sp)),
                      Text('End', style: TextStyle(fontSize: 12.sp)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Action Button
          if (selectedImages.isNotEmpty || selectedPdfs.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addPages,
                icon: const Icon(Icons.add),
                label: Text(
                  'Add ${selectedImages.length + selectedPdfs.length} Item(s) to PDF',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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

  Widget _buildContentTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
        selectedImages.clear();
        selectedPdfs.clear();
      });
      _loadPdfInfo();
    }
  }

  void _selectImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedImages.addAll(
          result.files
              .where((file) => file.path != null)
              .map((file) => File(file.path!)),
        );
      });
    }
  }

  void _selectPdfs() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        selectedPdfs.addAll(
          result.files
              .where((file) => file.path != null)
              .map((file) => File(file.path!)),
        );
      });
    }
  }

  void _addPages() async {
    if (selectedPdf == null) return;

    // Check if any operation was performed
    if (selectedImages.isEmpty && selectedPdfs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select images or PDFs to add'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      File? result;

      // Case 1: Only images selected
      if (selectedImages.isNotEmpty && selectedPdfs.isEmpty) {
        // Convert images to a PDF first
        final imagesPdf = await _pdfService.createPDFFromImages(
          imageFiles: selectedImages,
          title: 'temp_images_pdf',
        );

        if (imagesPdf == null) {
          throw Exception('Failed to convert images to PDF');
        }

        // Insert the images PDF into the main PDF
        result = await _pdfService.insertPagesIntoPDF(
          pdfFile: selectedPdf!,
          pagesToInsert: [imagesPdf],
          insertAt: insertPosition - 1, // Convert to 0-based index
          outputTitle: 'document_with_images',
        );

        // Clean up the temporary PDF
        try {
          await imagesPdf.delete();
        } catch (e) {
          print('Could not delete temporary file: $e');
        }
      }
      // Case 2: Only PDFs selected
      else if (selectedImages.isEmpty && selectedPdfs.isNotEmpty) {
        result = await _pdfService.insertPagesIntoPDF(
          pdfFile: selectedPdf!,
          pagesToInsert: selectedPdfs,
          insertAt: insertPosition - 1,
          outputTitle: 'document_with_pdfs',
        );
      }
      // Case 3: Both images and PDFs selected
      else {
        // First convert images to PDF
        final imagesPdf = await _pdfService.createPDFFromImages(
          imageFiles: selectedImages,
          title: 'temp_images_pdf',
        );

        if (imagesPdf == null) {
          throw Exception('Failed to convert images to PDF');
        }

        // Combine images PDF with selected PDFs
        final allPdfsToInsert = [imagesPdf, ...selectedPdfs];

        // Insert all into the main PDF
        result = await _pdfService.insertPagesIntoPDF(
          pdfFile: selectedPdf!,
          pagesToInsert: allPdfsToInsert,
          insertAt: insertPosition - 1,
          outputTitle: 'document_with_pages',
        );

        // Clean up the temporary PDF
        try {
          await imagesPdf.delete();
        } catch (e) {
          print('Could not delete temporary file: $e');
        }
      }

      if (result == null) {
        throw Exception('Failed to add pages to PDF');
      }

      setState(() => isLoading = false);

      // Navigate to preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            pdfFile: result!,
            title: 'Updated PDF',
            subtitle:
                'Added ${selectedImages.length + selectedPdfs.length} item(s)',
          ),
        ),
      ).then((_) {
        // Go back after preview
        Navigator.pop(context);
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
