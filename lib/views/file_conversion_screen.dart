import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../core/themes.dart';
import '../core/utils.dart';
import '../services/file_management_service.dart';
import '../services/pdf_service.dart';
import 'pdf_viewer_screen.dart';

enum _ConversionMode { pdfToWord, wordToPdf }

class FileConversionScreen extends StatefulWidget {
  const FileConversionScreen({super.key});

  @override
  State<FileConversionScreen> createState() => _FileConversionScreenState();
}

class _FileConversionScreenState extends State<FileConversionScreen> {
  final PDFService _pdfService = PDFService();
  final FileManagementService _fileService = FileManagementService();
  _ConversionMode _mode = _ConversionMode.pdfToWord;
  File? _selectedFile;
  int? _selectedFileSize;
  bool _isProcessing = false;
  String? _statusMessage;

  String get _modeTitle =>
      _mode == _ConversionMode.pdfToWord ? 'PDF to Word' : 'Word to PDF';

  String get _primaryCta =>
      _mode == _ConversionMode.pdfToWord ? 'Convert to DOCX' : 'Convert to PDF';

  Future<void> _pickFile() async {
    final extensions = _mode == _ConversionMode.pdfToWord
        ? ['pdf']
        : ['docx', 'doc'];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result == null || result.files.single.path == null) return;

    final original = File(result.files.single.path!);
    final cached = await _cacheFile(original);

    final size = await _safeLength(cached);

    setState(() {
      _selectedFile = cached;
      _selectedFileSize = size;
    });
  }

  Future<void> _startConversion() async {
    if (_selectedFile == null) {
      _showSnack('Please select a file first.');
      return;
    }

    // Validate file exists and is readable
    if (!await _selectedFile!.exists()) {
      setState(() {
        _selectedFile = null;
        _selectedFileSize = null;
      });
      _showSnack('Selected file is no longer available. Please reselect.');
      return;
    }

    final path = _selectedFile!.path.toLowerCase();
    
    // Validate file extension
    if (_mode == _ConversionMode.wordToPdf && !path.endsWith('.docx') && !path.endsWith('.doc')) {
      _showSnack('Only DOCX files are supported for Word to PDF conversion.');
      return;
    }
    if (_mode == _ConversionMode.pdfToWord && !path.endsWith('.pdf')) {
      _showSnack('Please select a valid PDF file.');
      return;
    }

    // Check file size (optional: warn if too large)
    final fileSize = await _safeLength(_selectedFile!);
    if (fileSize != null && fileSize > 100 * 1024 * 1024) { // 100MB
      _showSnack('File is larger than 100MB. Conversion may take longer.');
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Preparing file...';
    });

    try {
      File? output;
      
      if (_mode == _ConversionMode.pdfToWord) {
        setState(() {
          _statusMessage = 'Extracting text from PDF...';
        });
        print('Starting PDF to Word conversion for: ${_selectedFile!.path}');
        output = await _pdfService.convertPdfToWord(pdfFile: _selectedFile!);
        
        if (output == null) {
          if (mounted) {
            _showSnack('PDF conversion failed. The file may not contain extractable text.');
          }
          return;
        }
      } else {
        setState(() {
          _statusMessage = 'Converting Word to PDF...';
        });
        print('Starting Word to PDF conversion for: ${_selectedFile!.path}');
        output = await _pdfService.convertWordToPdf(wordFile: _selectedFile!);
        
        if (output == null) {
          if (mounted) {
            _showSnack('Word to PDF conversion failed. The file may be empty or corrupted. Check the logs for details.');
          }
          return;
        }
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });

      // Show success result
      if (output != null && await output.exists()) {
        _showResultSheet(output);
      } else {
        _showSnack('Conversion completed but file could not be verified.');
      }
    } catch (e) {
      print('Conversion error: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = null;
      });
      _showSnack('Conversion error: ${e.toString()}');
    }
  }

  void _showResultSheet(File file) {
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    final fileName = p.basename(file.path);
    final fileSize = _formatBytes(_safeLengthSync(file) ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 16.h,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.secondaryTeal),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conversion complete', style: AppTextStyles.titleMedium.copyWith(color: AppColors.gray900)),
                      SizedBox(height: 4.h),
                      Text(fileName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray600)),
                    ],
                  ),
                ),
                Text(fileSize, style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray600)),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Icon(isPdf ? Icons.picture_as_pdf : Icons.description,
                      color: isPdf ? Colors.red : AppColors.primaryBlue, size: 28.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isPdf ? 'Preview available' : 'Preview opens in device app',
                            style: AppTextStyles.titleMedium.copyWith(color: AppColors.gray900)),
                        SizedBox(height: 4.h),
                        Text(
                          isPdf
                              ? 'Open the PDF to review before sharing.'
                              : 'DOCX will open with your default viewer.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.gray600),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openPreview(file, isPdf: isPdf),
                    child: Text(isPdf ? 'Preview' : 'Open'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareFile(file),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _saveToDownloads(file),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(color: AppColors.primaryBlue),
                      foregroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPreview(File file, {required bool isPdf}) async {
    if (isPdf) {
      try {
        final pages = await _pdfService.getPdfPageCount(file);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PDFViewerScreen(
              pdfFile: file,
              title: p.basenameWithoutExtension(file.path),
              pageCount: pages,
            ),
          ),
        );
      } catch (e) {
        if (mounted) {
          _showSnack('Error loading PDF: $e');
        }
      }
    } else {
      try {
        await Utils.openFile(file.path);
      } catch (e) {
        if (mounted) {
          _showSnack('Error opening file: $e');
        }
      }
    }
  }

  Future<void> _shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shared from Document Scanner',
      );
    } catch (e) {
      _showSnack('Unable to share file: $e');
    }
  }

  Future<void> _saveToDownloads(File file) async {
    final result = await _fileService.saveToDownloads(file);
    _showSnack(result ? 'Saved to Downloads!' : 'Failed to save to Downloads');
  }

  Future<File> _cacheFile(File source) async {
    final baseDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(p.join(baseDir.path, 'convert_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final safeName = Utils.sanitizeFileName(p.basename(source.path));
    final targetPath = p.join(cacheDir.path, '${DateTime.now().millisecondsSinceEpoch}_$safeName');
    return source.copy(targetPath);
  }

  Future<int?> _safeLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  int? _safeLengthSync(File file) {
    try {
      return file.lengthSync();
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Convert Files',
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            SizedBox(height: 18.h),
            _buildModeSelector(),
            SizedBox(height: 16.h),
            _buildFilePickerCard(),
            SizedBox(height: 16.h),
            _buildInfoCard(),
            SizedBox(height: 20.h),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.swap_horiz_rounded,
                    color: Colors.white, size: 26.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Convert between PDF and Word with one tap.',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: Colors.white, height: 1.4),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'Choose a direction below and we will handle the export for you.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    Widget buildTab(
      _ConversionMode mode,
      String label,
      IconData icon,
    ) {
      final isSelected = _mode == mode;
      return Expanded(
        child: InkWell(
          onTap: _isProcessing ? null : () => setState(() => _mode = mode),
          borderRadius: BorderRadius.circular(14.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.secondaryTeal : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isSelected ? AppColors.secondaryTeal : AppColors.gray200,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: isSelected ? Colors.white : AppColors.gray700,
                    size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          buildTab(_ConversionMode.pdfToWord, 'PDF → Word', Icons.description),
          SizedBox(width: 8.w),
          buildTab(_ConversionMode.wordToPdf, 'Word → PDF', Icons.picture_as_pdf),
        ],
      ),
    );
  }

  Widget _buildFilePickerCard() {
    final hasFile = _selectedFile != null && _selectedFile!.existsSync();
    final fileName = hasFile ? p.basename(_selectedFile!.path) : 'No file selected';
    final fileSize = hasFile ? (_selectedFileSize ?? _safeLengthSync(_selectedFile!)) : null;
    final supportedText = _mode == _ConversionMode.pdfToWord ? 'PDF' : 'DOCX only';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.insert_drive_file_rounded,
                    color: AppColors.primaryBlue, size: 22.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gray900,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      hasFile
                          ? 'Ready to convert $_modeTitle'
                          : 'Supported: $supportedText',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickFile,
                icon: Icon(Icons.folder_open, size: 18.sp),
                label: Text(hasFile ? 'Change' : 'Select'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
          if (hasFile) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.insert_drive_file,
                    size: 18.sp, color: AppColors.gray500),
                SizedBox(width: 6.w),
                Text(
                  _mode == _ConversionMode.pdfToWord ? 'PDF' : 'DOCX',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray700,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(Icons.storage, size: 18.sp, color: AppColors.gray500),
                SizedBox(width: 6.w),
                Text(
                  fileSize != null ? _formatBytes(fileSize) : 'Size unavailable',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          ],
          if (_isProcessing && _statusMessage != null) ...[
            SizedBox(height: 14.h),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final tips = _mode == _ConversionMode.pdfToWord
        ? [
            'Best for extracting text from PDFs.',
            'Complex layouts may need manual cleanup in Word.',
            'Original PDF is never modified.',
          ]
        : [
            'Great for sharing finalized Word docs.',
            'Images and text are baked into the PDF output.',
            'Keep source DOCX for future edits.',
          ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.gray700, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Tips for better results',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...tips.map(
            (tip) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.check_rounded,
                      size: 16.sp, color: AppColors.emerald),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray700,
                        height: 1.45,
                      ),
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

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _startConversion,
        icon: Icon(Icons.play_arrow_rounded, size: 20.sp),
        label: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Text(
            _primaryCta,
            style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final roundedSize = (size * 10).roundToDouble() / 10;
    return '${roundedSize.toStringAsFixed(1)} ${units[unitIndex]}';
  }
}
