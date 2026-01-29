import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';
import '../widgets/password_protected_dialog.dart';
import '../widgets/native_ad_widget.dart';

class PdfMetadataScreen extends StatefulWidget {
  final File? initialPdfFile;

  const PdfMetadataScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<PdfMetadataScreen> createState() => _PdfMetadataScreenState();
}

class _PdfMetadataScreenState extends State<PdfMetadataScreen> {
  final PDFService _pdfService = PDFService();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subjectController = TextEditingController();
  final _keywordsController = TextEditingController();
  final _creatorController = TextEditingController();
  final _producerController = TextEditingController();

  File? selectedPdf;
  bool isLoading = false;
  Map<String, dynamic>? currentMetadata;
  bool hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Add listeners to track changes
    _titleController.addListener(_onFieldChanged);
    _authorController.addListener(_onFieldChanged);
    _subjectController.addListener(_onFieldChanged);
    _keywordsController.addListener(_onFieldChanged);
    _creatorController.addListener(_onFieldChanged);
    _producerController.addListener(_onFieldChanged);

    if (widget.initialPdfFile != null) {
      selectedPdf = widget.initialPdfFile;
      _loadMetadata();
    }
  }

  void _onFieldChanged() {
    if (!hasChanges) {
      setState(() {
        hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    _keywordsController.dispose();
    _creatorController.dispose();
    _producerController.dispose();
    super.dispose();
  }

  void _loadMetadata() async {
    if (selectedPdf != null) {
      setState(() => isLoading = true);

      try {
        // Since getPdfMetadata doesn't exist in PDFService, use getPDFInfo instead
        final pdfInfo = await _pdfService.getPDFInfo(selectedPdf!);
        if (pdfInfo != null) {
          currentMetadata = pdfInfo;
          _titleController.text = pdfInfo['title'] ?? '';
          _authorController.text = pdfInfo['author'] ?? '';
          _subjectController.text = pdfInfo['subject'] ?? '';
          _keywordsController.text = pdfInfo['keywords'] ?? '';
          _creatorController.text = pdfInfo['creator'] ?? '';
          _producerController.text = pdfInfo['producer'] ?? '';
        } else {
          // If getPDFInfo returns null, set empty metadata
          currentMetadata = <String, dynamic>{};
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading metadata: $e'),
            backgroundColor: Colors.red,
          ),
        );
        currentMetadata = <String, dynamic>{};
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Edit Metadata',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (hasChanges)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveMetadata,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: selectedPdf == null
          ? _buildSelectPdfScreen()
          : _buildMetadataInterface(),
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
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.info_outline,
                size: 80.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Edit PDF Metadata',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Edit document properties and information of your PDF files',
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
                backgroundColor: Colors.grey.shade700,
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

  Widget _buildMetadataInterface() {
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
                if (hasChanges) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Unsaved changes',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Current Metadata Display
          if (currentMetadata != null) ...[
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
                        'Current Document Information',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  if (currentMetadata!['fileSize'] != null)
                    _buildInfoRow('File Size',
                        _formatFileSize(currentMetadata!['fileSize'])),
                  if (currentMetadata!['pageCount'] != null)
                    _buildInfoRow(
                        'Pages', currentMetadata!['pageCount'].toString()),
                  if (currentMetadata!['creationDate'] != null)
                    _buildInfoRow('Created',
                        _formatDate(currentMetadata!['creationDate'])),
                  if (currentMetadata!['modificationDate'] != null)
                    _buildInfoRow('Modified',
                        _formatDate(currentMetadata!['modificationDate'])),
                  if (currentMetadata!['version'] != null)
                    _buildInfoRow('PDF Version', currentMetadata!['version']),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Editable Metadata Fields
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
                  'Document Properties',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  hint: 'Enter document title',
                  icon: Icons.title,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: _authorController,
                  label: 'Author',
                  hint: 'Enter author name',
                  icon: Icons.person,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: _subjectController,
                  label: 'Subject',
                  hint: 'Enter document subject',
                  icon: Icons.subject,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: _keywordsController,
                  label: 'Keywords',
                  hint: 'Enter keywords (comma separated)',
                  icon: Icons.tag,
                  maxLines: 2,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: _creatorController,
                  label: 'Creator',
                  hint: 'Enter creator application',
                  icon: Icons.build,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: _producerController,
                  label: 'Producer',
                  hint: 'Enter producer information',
                  icon: Icons.business,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Metadata Guidelines
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
                    Icon(Icons.tips_and_updates,
                        color: Colors.green, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Metadata Best Practices',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildTipItem('Use descriptive titles for better organization'),
                _buildTipItem('Include relevant keywords for searchability'),
                _buildTipItem(
                    'Add author information for document attribution'),
                _buildTipItem('Keep subject concise but informative'),
                _buildTipItem('Metadata helps with document management'),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearAllFields,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade700,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasChanges ? _saveMetadata : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Metadata'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      onChanged: (_) {
        setState(() {
          hasChanges = true;
        });
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.blue.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
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
        hasChanges = false;
      });
      _loadMetadata();
    }
  }

  void _clearAllFields() {
    setState(() {
      _titleController.clear();
      _authorController.clear();
      _subjectController.clear();
      _keywordsController.clear();
      _creatorController.clear();
      _producerController.clear();
      hasChanges = true;
    });
  }

  void _saveMetadata() async {
    if (selectedPdf == null) return;

    // Check if any field has content
    bool hasAnyContent = _titleController.text.isNotEmpty ||
        _authorController.text.isNotEmpty ||
        _subjectController.text.isNotEmpty ||
        _keywordsController.text.isNotEmpty ||
        _creatorController.text.isNotEmpty ||
        _producerController.text.isNotEmpty;

    if (!hasAnyContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill at least one metadata field'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Update PDF metadata using PDFService
      final result = await _pdfService.updatePdfMetadata(
        pdfFile: selectedPdf!,
        outputTitle: _titleController.text.isNotEmpty
            ? _titleController.text
            : 'Updated_${selectedPdf!.path.split('/').last.replaceAll('.pdf', '')}',
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        author:
            _authorController.text.isNotEmpty ? _authorController.text : null,
        subject:
            _subjectController.text.isNotEmpty ? _subjectController.text : null,
        keywords: _keywordsController.text.isNotEmpty
            ? _keywordsController.text
            : null,
        creator:
            _creatorController.text.isNotEmpty ? _creatorController.text : null,
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
                const Expanded(child: Text('Metadata updated successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to preview screen with the updated PDF
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: result,
              title: 'Updated PDF Metadata',
              subtitle:
                  '${_titleController.text.isNotEmpty ? _titleController.text : "Document"} - Metadata updated',
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
                const Expanded(child: Text('Failed to update metadata')),
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
          PasswordProtectedPdfDialog.show(context, toolName: 'edited');
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
