import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../services/file_management_service.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/interstitial_ad_helper.dart';

class ExtractTextScreen extends StatefulWidget {
  final File? initialPdfFile;

  const ExtractTextScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<ExtractTextScreen> createState() => _ExtractTextScreenState();
}

class _ExtractTextScreenState extends State<ExtractTextScreen> {
  final PDFService _pdfService = PDFService();
  final FileManagementService _fileService = FileManagementService();
  File? selectedPdf;
  bool isLoading = false;
  String? extractedText;
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
          'Extract Text',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (extractedText != null && extractedText!.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'copy') {
                  _copyToClipboard();
                } else if (value == 'save') {
                  _saveToFile();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy),
                      SizedBox(width: 8),
                      Text('Copy Text'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text('Save as Text File'),
                    ],
                  ),
                ),
              ],
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.text_fields,
                size: 80.sp,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Extract Text from PDF',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Extract and copy text content from your PDF documents',
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
                backgroundColor: Colors.blue,
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
              'Extracting text from PDF...',
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
          if (extractedText == null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _extractText,
                icon: const Icon(Icons.text_fields),
                label: const Text('Extract Text'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Text Extraction Features',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildFeatureItem('📝 Extract all text content'),
                  _buildFeatureItem('📋 Copy to clipboard'),
                  _buildFeatureItem('💾 Save as text file'),
                  _buildFeatureItem('🔍 Searchable text output'),
                  _buildFeatureItem('📄 Preserves text structure'),
                ],
              ),
            ),
          ],

          // Extracted Text Display
          if (extractedText != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extracted Text',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy to Clipboard',
                    ),
                    IconButton(
                      onPressed: _saveToFile,
                      icon: const Icon(Icons.save),
                      tooltip: 'Save as Text File',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          extractedText = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Extract Again',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Text Statistics
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Characters', extractedText!.length.toString()),
                  _buildStatItem(
                      'Words', extractedText!.split(' ').length.toString()),
                  _buildStatItem(
                      'Lines', extractedText!.split('\n').length.toString()),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Text Content
            Container(
              width: double.infinity,
              height: 400.h,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  extractedText!.isEmpty
                      ? 'No text found in the PDF.'
                      : extractedText!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                    height: 1.5,
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
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.green.shade600,
          ),
        ),
      ],
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
        extractedText = null;
      });
      _loadPdfInfo();
    }
  }

  void _extractText() {
    if (selectedPdf == null) return;

    InterstitialAdHelper.showInterstitialAd(
      onAdClosed: _runTextExtraction,
    );
  }

  Future<void> _runTextExtraction() async {
    setState(() => isLoading = true);

    try {
      // Extract text from PDF using PDFService
      final text = await _pdfService.extractTextFromPdf(
        pdfFile: selectedPdf!,
        pageIndex: null, // Extract from all pages
      );

      if (text.isNotEmpty) {
        setState(() {
          extractedText = text;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Text extracted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text found in the PDF'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error extracting text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _copyToClipboard() {
    if (extractedText != null && extractedText!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: extractedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _saveToFile() async {
    if (extractedText == null || extractedText!.isEmpty) return;

    try {
      final fileName = selectedPdf!.path
          .split('/')
          .last
          .replaceAll('.pdf', '_extracted_text.txt');

      // Create a temporary directory for the text file
      final directory = await Directory.systemTemp.createTemp();
      final textFile = File('${directory.path}/$fileName');
      await textFile.writeAsString(extractedText!);

      // Save to downloads using FileManagementService
      final result = await _fileService.saveToDownloads(textFile);

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Text file saved to Downloads!',
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
            content: const Text('Failed to save text file'),
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
            content: Text('Error saving file: $e'),
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
