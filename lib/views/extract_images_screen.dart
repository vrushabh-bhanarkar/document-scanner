import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../services/file_management_service.dart';
import '../widgets/native_ad_widget.dart';

class ExtractImagesScreen extends StatefulWidget {
  final File? initialPdfFile;

  const ExtractImagesScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<ExtractImagesScreen> createState() => _ExtractImagesScreenState();
}

class _ExtractImagesScreenState extends State<ExtractImagesScreen> {
  final PDFService _pdfService = PDFService();
  final FileManagementService _fileService = FileManagementService();
  File? selectedPdf;
  bool isLoading = false;
  List<File>? extractedImages;
  int? totalPages;

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
          'Extract Images',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (extractedImages != null && extractedImages!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save_alt, color: Colors.white),
              onPressed: _saveAllImages,
              tooltip: 'Save All Images',
            ),
        ],
      ),
      body: selectedPdf == null
          ? _buildSelectPdfScreen()
          : _buildExtractInterface(),
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
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.image,
                size: 80.sp,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Extract Images from PDF',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Extract and save all images from your PDF documents',
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
                backgroundColor: Colors.green.shade700,
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

  Widget _buildExtractInterface() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'Extracting images from PDF...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
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
                if (totalPages != null)
                  Text(
                    'Total Pages: $totalPages',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Extract Button
          if (extractedImages == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _extractImages,
                icon: const Icon(Icons.image_search),
                label: const Text('Extract Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Info Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.green, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Image Extraction Features',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildFeatureItem('🖼️ Extract all embedded images'),
                  _buildFeatureItem('💾 Save in original quality'),
                  _buildFeatureItem('📁 Organized file naming'),
                  _buildFeatureItem('🔍 Preview before saving'),
                  _buildFeatureItem('📊 Multiple format support'),
                ],
              ),
            ),
          ],

          // Extracted Images Display
          if (extractedImages != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extracted Images (${extractedImages!.length})',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _saveAllImages,
                      icon: const Icon(Icons.save_alt),
                      tooltip: 'Save All Images',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          extractedImages = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Extract Again',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (extractedImages!.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48.sp,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No Images Found',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'This PDF does not contain any extractable images.',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.orange.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Images Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1,
                ),
                itemCount: extractedImages!.length,
                itemBuilder: (context, index) {
                  final image = extractedImages![index];
                  return _buildImageCard(image, index);
                },
              ),
              SizedBox(height: 24.h),

              // Save All Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveAllImages,
                  icon: const Icon(Icons.save_alt),
                  label: Text('Save All ${extractedImages!.length} Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Native Ad
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: NativeAdWidget(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildImageCard(File image, int index) {
    return Container(
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
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
              child: GestureDetector(
                onTap: () => _showImagePreview(image, index),
                child: Image.file(
                  image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                        size: 48.sp,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Image ${index + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _saveImage(image, index),
                  icon: Icon(Icons.save_alt, size: 20.sp),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.green.shade700,
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
        extractedImages = null;
      });
      _loadPdfInfo();
    }
  }

  void _extractImages() async {
    if (selectedPdf == null) return;

    setState(() => isLoading = true);

    try {
      final images = await _pdfService.extractImagesFromPDF(
        pdfFile: selectedPdf!,
        scale: 1.0,
      );

      setState(() {
        extractedImages = images;
      });

      if (extractedImages == null || extractedImages!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No images found in the PDF.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully extracted ${extractedImages!.length} images'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error extracting images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showImagePreview(File image, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Image ${index + 1}'),
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveImage(image, index);
                  },
                  icon: const Icon(Icons.save_alt),
                ),
              ],
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Image.file(
                image,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _saveImage(image, index);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveImage(File image, int index) async {
    try {
      // Save to downloads using FileManagementService
      final result = await _fileService.saveToDownloads(image);

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Image ${index + 1} saved to Downloads!',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
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
            content: const Text('Failed to save image'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    }
  }

  void _saveAllImages() async {
    if (extractedImages == null || extractedImages!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      int savedCount = 0;
      int failedCount = 0;

      for (int i = 0; i < extractedImages!.length; i++) {
        try {
          final result =
              await _fileService.saveToDownloads(extractedImages![i]);
          if (result) {
            savedCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
          print('Error saving image ${i + 1}: $e');
        }
      }

      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  savedCount > 0 ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    failedCount > 0
                        ? 'Saved $savedCount/${extractedImages!.length} images to Downloads'
                        : 'Saved $savedCount images to Downloads!',
                    style:
                        TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving images: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    }
  }
}
