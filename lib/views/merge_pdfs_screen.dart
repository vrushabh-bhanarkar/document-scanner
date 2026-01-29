import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/interstitial_ad_helper.dart';

class MergePdfsScreen extends StatefulWidget {
  const MergePdfsScreen({Key? key}) : super(key: key);

  @override
  State<MergePdfsScreen> createState() => _MergePdfsScreenState();
}

class _MergePdfsScreenState extends State<MergePdfsScreen> {
  List<File> selectedPdfs = [];
  bool isMerging = false;
  final PDFService _pdfService = PDFService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Merge PDFs',
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
          if (selectedPdfs.length >= 2)
            TextButton(
              onPressed: isMerging ? null : _mergePdfs,
              child: Text(
                'Merge',
                style: TextStyle(
                  color: isMerging ? Colors.grey : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Icon(Icons.merge_type, color: Colors.white, size: 32.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merge PDF Files',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Combine multiple PDFs into one document',
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

          // Instructions
          if (selectedPdfs.isEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Select at least 2 PDF files to merge them together',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Selected PDFs List
          Expanded(
            child: selectedPdfs.isEmpty ? _buildEmptyState() : _buildPdfsList(),
          ),

          // Add PDF Button
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16.w),
            child: ElevatedButton.icon(
              onPressed: _selectPdfFiles,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                selectedPdfs.isEmpty ? 'Select PDF Files' : 'Add More PDFs',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          // Native Ad
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NativeAdWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 80.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No PDFs Selected',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the button below to select PDF files',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfsList() {
    return ReorderableListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: selectedPdfs.length,
      onReorder: _reorderPdfs,
      itemBuilder: (context, index) {
        final pdf = selectedPdfs[index];
        final fileName = pdf.path.split('/').last;

        return Container(
          key: ValueKey(pdf.path),
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
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 24.sp,
              ),
            ),
            title: Text(
              fileName,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Position ${index + 1}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.drag_handle,
                  color: Colors.grey[400],
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 20.sp,
                  ),
                  onPressed: () => _removePdf(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectPdfFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedPdfs.addAll(
          result.files.map((file) => File(file.path!)).toList(),
        );
      });
    }
  }

  void _removePdf(int index) {
    setState(() {
      selectedPdfs.removeAt(index);
    });
  }

  void _reorderPdfs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = selectedPdfs.removeAt(oldIndex);
      selectedPdfs.insert(newIndex, item);
    });
  }

  void _mergePdfs() {
    if (selectedPdfs.length < 2) return;

    InterstitialAdHelper.showInterstitialAd(
      onAdClosed: _runMergeFlow,
    );
  }

  Future<void> _runMergeFlow() async {
    setState(() => isMerging = true);

    try {
      // Check for password-protected PDFs
      Map<String, String> passwords = {};
      bool needsPassword = false;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text('Checking PDFs...', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
        ),
      );

      // Check each PDF for password protection
      for (var pdf in selectedPdfs) {
        bool isProtected = await _pdfService.isPdfPasswordProtected(pdf);
        if (isProtected) {
          needsPassword = true;
          Navigator.pop(context); // Close checking dialog

          // Prompt for password
          String? password = await _promptForPassword(pdf);
          if (password == null || password.isEmpty) {
            setState(() => isMerging = false);
            _showErrorDialog(
                'Password required for: ${pdf.path.split('/').last}');
            return;
          }

          // Verify password
          bool isValid = await _pdfService.verifyPdfPassword(pdf, password);
          if (!isValid) {
            setState(() => isMerging = false);
            _showErrorDialog(
                'Invalid password for: ${pdf.path.split('/').last}');
            return;
          }

          passwords[pdf.path] = password;

          // Show checking dialog again for next PDF
          if (selectedPdfs.indexOf(pdf) < selectedPdfs.length - 1) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    Text('Checking PDFs...', style: TextStyle(fontSize: 16.sp)),
                  ],
                ),
              ),
            );
          }
        }
      }

      if (!needsPassword) {
        Navigator.pop(context); // Close checking dialog
      }

      // Show merging dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text('Merging PDFs...', style: TextStyle(fontSize: 16.sp)),
            ],
          ),
        ),
      );

      final mergedPdf = await _pdfService.mergePDFs(
        pdfFiles: selectedPdfs,
        outputFileName: 'Merged_PDF_${DateTime.now().millisecondsSinceEpoch}',
        passwords: passwords.isEmpty ? null : passwords,
      );

      Navigator.pop(context); // Close loading dialog

      if (mergedPdf != null && mounted) {
        // Directly navigate to preview screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: mergedPdf,
              title: 'Merged PDF',
              subtitle: '${selectedPdfs.length} files combined',
            ),
          ),
        ).then((_) {
          // After preview closes, go back to previous screen
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        _showErrorDialog('Failed to merge PDFs');
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }
      _showErrorDialog('Error: $e');
    } finally {
      setState(() => isMerging = false);
    }
  }

  Future<String?> _promptForPassword(File pdfFile) async {
    String? password;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordDialog(
        pdfFile: pdfFile,
        onPasswordEntered: (value) {
          password = value;
        },
      ),
    );

    return password;
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

class _PasswordDialog extends StatefulWidget {
  final File pdfFile;
  final Function(String?) onPasswordEntered;

  const _PasswordDialog({
    required this.pdfFile,
    required this.onPasswordEntered,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock, color: Colors.orange, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Password Required',
              style: TextStyle(fontSize: 18.sp),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This PDF is password protected:',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            widget.pdfFile.path.split('/').last,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Enter Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              prefixIcon: const Icon(Icons.key),
            ),
            onSubmitted: (value) {
              widget.onPasswordEntered(value);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onPasswordEntered(null);
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onPasswordEntered(_passwordController.text);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
