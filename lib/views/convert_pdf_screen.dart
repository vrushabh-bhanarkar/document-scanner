import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../services/pdf_service.dart';

class ConvertPdfScreen extends StatefulWidget {
  final File? initialPdfFile;

  const ConvertPdfScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<ConvertPdfScreen> createState() => _ConvertPdfScreenState();
}

class _ConvertPdfScreenState extends State<ConvertPdfScreen> {
  final PDFService _pdfService = PDFService();
  File? selectedPdf;
  bool isLoading = false;
  String selectedFormat =
      'images'; // 'images', 'word', 'excel', 'powerpoint', 'text'
  String imageFormat = 'jpg'; // 'jpg', 'png'
  double imageQuality = 0.8;
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
          'Convert PDF',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
        centerTitle: true,
      ),
      body: selectedPdf == null
          ? _buildSelectPdfScreen()
          : _buildConvertInterface(),
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
                color: Colors.deepOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.transform,
                size: 80.sp,
                color: Colors.deepOrange,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Convert PDF Format',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Convert your PDF documents to different file formats',
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
                backgroundColor: Colors.deepOrange,
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

  Widget _buildConvertInterface() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'Converting PDF...',
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

          // Format Selection
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
                  'Select Output Format',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.3,
                  children: [
                    _buildFormatCard(
                      'Images',
                      'Convert to JPG/PNG images',
                      Icons.image,
                      Colors.blue,
                      'images',
                    ),
                    _buildFormatCard(
                      'Word Document',
                      'Convert to DOCX format',
                      Icons.description,
                      Colors.blue.shade700,
                      'word',
                    ),
                    _buildFormatCard(
                      'Excel Sheet',
                      'Convert to XLSX format',
                      Icons.table_chart,
                      Colors.green,
                      'excel',
                    ),
                    _buildFormatCard(
                      'PowerPoint',
                      'Convert to PPTX format',
                      Icons.slideshow,
                      Colors.orange,
                      'powerpoint',
                    ),
                    _buildFormatCard(
                      'Text File',
                      'Extract as TXT format',
                      Icons.text_snippet,
                      Colors.grey.shade600,
                      'text',
                    ),
                    _buildFormatCard(
                      'HTML',
                      'Convert to web format',
                      Icons.web,
                      Colors.purple,
                      'html',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Format-specific Options
          if (selectedFormat == 'images') _buildImageOptions(),
          if (selectedFormat == 'word') _buildWordOptions(),
          if (selectedFormat == 'text') _buildTextOptions(),
          SizedBox(height: 24.h),

          // Conversion Info
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
                      'Conversion Information',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildInfoItem(_getFormatInfo()),
                _buildInfoItem('Original PDF will be preserved'),
                _buildInfoItem('Processing time depends on file size'),
                _buildInfoItem('Complex layouts may need manual adjustment'),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // Convert Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _convertPdf,
              icon: const Icon(Icons.transform),
              label: Text('Convert to ${_getFormatDisplayName()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String format,
  ) {
    final isSelected = selectedFormat == format;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFormat = format;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32.sp,
            ),
            SizedBox(height: 6.h),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2.h),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptions() {
    return Container(
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
            'Image Options',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Image Format',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _buildImageFormatOption('JPG', 'jpg'),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildImageFormatOption('PNG', 'png'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Quality: ${(imageQuality * 100).round()}%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: imageQuality,
            min: 0.3,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                imageQuality = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWordOptions() {
    return Container(
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
            'Word Conversion Options',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildOptionItem('Preserve formatting', true),
          _buildOptionItem('Extract images', true),
          _buildOptionItem('Maintain layout', false),
          SizedBox(height: 8.h),
          Text(
            'Note: Complex layouts may require manual formatting adjustments.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextOptions() {
    return Container(
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
            'Text Extraction Options',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          _buildOptionItem('Preserve line breaks', true),
          _buildOptionItem('Include page numbers', false),
          _buildOptionItem('Remove extra spaces', true),
        ],
      ),
    );
  }

  Widget _buildImageFormatOption(String label, String format) {
    final isSelected = imageFormat == format;

    return GestureDetector(
      onTap: () {
        setState(() {
          imageFormat = format;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(String title, bool value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.radio_button_unchecked,
            color: value ? Colors.green : Colors.grey,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blue, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormatDisplayName() {
    switch (selectedFormat) {
      case 'images':
        return imageFormat.toUpperCase();
      case 'word':
        return 'Word Document';
      case 'excel':
        return 'Excel Sheet';
      case 'powerpoint':
        return 'PowerPoint';
      case 'text':
        return 'Text File';
      case 'html':
        return 'HTML';
      default:
        return 'Selected Format';
    }
  }

  String _getFormatInfo() {
    switch (selectedFormat) {
      case 'images':
        return 'Each page will be converted to a separate $imageFormat image';
      case 'word':
        return 'Text and basic formatting will be preserved in DOCX format';
      case 'excel':
        return 'Tables and data will be extracted to spreadsheet format';
      case 'powerpoint':
        return 'Pages will be converted to presentation slides';
      case 'text':
        return 'All text content will be extracted as plain text';
      case 'html':
        return 'Content will be converted to web-compatible HTML format';
      default:
        return 'Conversion will preserve as much original formatting as possible';
    }
  }

  void _selectPdfFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedPdf = File(result.files.single.path!);
      });
      _loadPdfInfo();
    }
  }

  void _convertPdf() async {
    if (selectedPdf == null) return;

    setState(() => isLoading = true);

    try {
      dynamic result;

      switch (selectedFormat) {
        case 'images':
          // Convert PDF to images using existing PDF service functionality
          result = await _convertToImages();
          break;
        case 'text':
          result = await _convertToText();
          break;
        case 'word':
          result = await _convertToWord();
          break;
        case 'html':
          result = await _convertToHtml();
          break;
        case 'excel':
        case 'powerpoint':
          _showFeatureNotImplemented();
          return;
      }

      if (result != null && result == true) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(child: Text('Conversion Complete!')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Your PDF has been successfully converted to ${_getFormatDisplayName()}.'),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder, color: Colors.green.shade700),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Files saved in the same directory as the original PDF',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to convert PDF to ${_getFormatDisplayName()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> _convertToImages() async {
    try {
      // Convert PDF pages to individual image files
      final imageFiles = await _pdfService.convertPdfPagesToImages(
        pdfFile: selectedPdf!,
        imageFormat: imageFormat,
        quality: imageQuality,
      );

      if (imageFiles != null && imageFiles.isNotEmpty) {
        // Images were successfully created
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully converted ${imageFiles.length} pages to ${imageFormat.toUpperCase()} images'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Show dialog with file location info
        if (mounted) {
          final firstFile = imageFiles.first;
          final directory = firstFile.parent.path;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(child: Text('Conversion Complete!')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Successfully converted ${imageFiles.length} pages to images.'),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.folder,
                                  color: Colors.green.shade700, size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Saved Location:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            directory,
                            style: TextStyle(
                                fontSize: 11.sp, color: Colors.grey[700]),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        return true;
      } else {
        // Conversion failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to convert PDF pages to images'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      print('Error converting to images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  Future<bool> _convertToText() async {
    try {
      final extracted = await _pdfService.extractTextFromPdf(pdfFile: selectedPdf!);
      if (extracted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found in PDF'), backgroundColor: Colors.red),
        );
        return false;
      }

      final dir = await getApplicationDocumentsDirectory();
      final base = selectedPdf!.path.split('/').last.replaceAll('.pdf', '');
      final outFile = File('${dir.path}/${base}_${DateTime.now().millisecondsSinceEpoch}.txt');
      await outFile.writeAsString(extracted);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(child: Text('Conversion Complete!')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully extracted text from the PDF.'),
                SizedBox(height: 12.h),
                Text('Saved to:'),
                SizedBox(height: 6.h),
                Text(outFile.path, style: TextStyle(color: Colors.grey[700], fontSize: 12.sp)),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }

      return true;
    } catch (e) {
      print('Error converting to text: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<bool> _convertToHtml() async {
    try {
      final extracted = await _pdfService.extractTextFromPdf(pdfFile: selectedPdf!);
      if (extracted.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No text found in PDF'), backgroundColor: Colors.red),
        );
        return false;
      }

      final html = '''<!doctype html>
<html>
<head><meta charset="utf-8"><title>Converted PDF</title></head>
<body><pre style="white-space: pre-wrap; font-family: sans-serif;">${HtmlEscape().convert(extracted)}</pre></body>
</html>
''';

      final dir = await getApplicationDocumentsDirectory();
      final base = selectedPdf!.path.split('/').last.replaceAll('.pdf', '');
      final outFile = File('${dir.path}/${base}_${DateTime.now().millisecondsSinceEpoch}.html');
      await outFile.writeAsString(html);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(child: Text('Conversion Complete!')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HTML file created from PDF content.'),
                SizedBox(height: 12.h),
                Text('Saved to:'),
                SizedBox(height: 6.h),
                Text(outFile.path, style: TextStyle(color: Colors.grey[700], fontSize: 12.sp)),
              ],
            ),
            actions: [
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }

      return true;
    } catch (e) {
      print('Error converting to HTML: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<bool> _convertToWord() async {
    try {
      final wordFile = await _pdfService.convertPdfToWord(pdfFile: selectedPdf!);
      
      if (wordFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to convert PDF to Word'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
                SizedBox(width: 12.w),
                Expanded(child: Text('Conversion Complete!')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully converted PDF to Word document.'),
                SizedBox(height: 12.h),
                Text('Saved to:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6.h),
                Text(
                  wordFile.path,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      return true;
    } catch (e) {
      print('Error converting to Word: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void _showFeatureNotImplemented() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text('Feature Coming Soon')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Conversion to ${_getFormatDisplayName()} is not yet implemented.'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Currently Available:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.h),
                  Text('• Image extraction (extract embedded images)'),
                  Text('• PDF merging and splitting'),
                  Text('• Page rotation and deletion'),
                  Text('• Password protection'),
                  Text('• PDF compression'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
