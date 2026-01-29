import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/pdf_service.dart';
import '../widgets/pdf_preview_screen.dart';
import '../widgets/password_protected_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/native_ad_widget.dart';

class WatermarkScreen extends StatefulWidget {
  final File? initialPdfFile;

  const WatermarkScreen({Key? key, this.initialPdfFile}) : super(key: key);

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  final PDFService _pdfService = PDFService();
  final _textController = TextEditingController();
  File? selectedPdf;
  File? watermarkImage;
  bool isLoading = false;
  int? totalPages;

  // Watermark settings
  String watermarkType = 'text'; // 'text' or 'image'
  double opacity = 0.5;
  double fontSize = 24;
  String position =
      'center'; // 'center', 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'
  Color textColor = Colors.grey;
  double rotation = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPdfFile != null) {
      selectedPdf = widget.initialPdfFile;
      _loadPdfInfo();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
    final sub = Provider.of<SubscriptionProvider>(context);
    if (!sub.isSubscribed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Watermark'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Watermark is a premium feature.'),
                const SizedBox(height: 12),
                // Subscription temporarily disabled
                // ElevatedButton(
                //   onPressed: () => Navigator.pop(context), // Navigator.pushNamed(context, '/subscription'), // Temporarily disabled
                //   child: const Text('Close'), // Changed from 'Subscribe to unlock'
                // ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Add Watermark',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: selectedPdf == null
          ? _buildSelectPdfScreen()
          : _buildWatermarkInterface(),
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
                color: Colors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.water_drop,
                size: 80.sp,
                color: Colors.lightBlue,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Add Watermark to PDF',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Protect your documents with text or image watermarks',
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
                backgroundColor: Colors.lightBlue,
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

  Widget _buildWatermarkInterface() {
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

          // Watermark Type Selection
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
                  'Watermark Type',
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
                      child: _buildTypeCard(
                        'Text Watermark',
                        'Add custom text',
                        Icons.text_fields,
                        'text',
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildTypeCard(
                        'Image Watermark',
                        'Add image/logo',
                        Icons.image,
                        'image',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // Watermark Content Configuration
          if (watermarkType == 'text') _buildTextWatermarkConfig(),
          if (watermarkType == 'image') _buildImageWatermarkConfig(),
          SizedBox(height: 24.h),

          // Watermark Settings
          _buildWatermarkSettings(),
          SizedBox(height: 24.h),

          // Preview Card
          _buildPreviewCard(),
          SizedBox(height: 32.h),

          // Apply Watermark Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canApplyWatermark() ? _applyWatermark : null,
              icon: const Icon(Icons.water_drop),
              label: const Text('Apply Watermark'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
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

  Widget _buildTypeCard(
      String title, String subtitle, IconData icon, String type) {
    final isSelected = watermarkType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          watermarkType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.lightBlue.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? Colors.lightBlue : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.lightBlue : Colors.grey[600],
              size: 32.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.lightBlue : Colors.black87,
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

  Widget _buildTextWatermarkConfig() {
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
            'Text Configuration',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Watermark Text',
              hintText: 'Enter your watermark text',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16.h),
          Text(
            'Font Size: ${fontSize.round()}pt',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: fontSize,
            min: 12,
            max: 72,
            divisions: 30,
            onChanged: (value) {
              setState(() {
                fontSize = value;
              });
            },
          ),
          SizedBox(height: 16.h),
          Text(
            'Text Color',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildColorOption(Colors.grey),
              _buildColorOption(Colors.red),
              _buildColorOption(Colors.blue),
              _buildColorOption(Colors.green),
              _buildColorOption(Colors.orange),
              _buildColorOption(Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageWatermarkConfig() {
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
            'Image Configuration',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          if (watermarkImage == null) ...[
            ElevatedButton.icon(
              onPressed: _selectWatermarkImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.file(
                      watermarkImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    watermarkImage!.path.split('/').last,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      watermarkImage = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWatermarkSettings() {
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
            'Watermark Settings',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Opacity: ${(opacity * 100).round()}%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: opacity,
            min: 0.1,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                opacity = value;
              });
            },
          ),
          SizedBox(height: 16.h),
          Text(
            'Position',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 2.5,
            children: [
              _buildPositionOption('Top Left', 'topLeft'),
              _buildPositionOption('Top Center', 'topCenter'),
              _buildPositionOption('Top Right', 'topRight'),
              _buildPositionOption('Center', 'center'),
              _buildPositionOption('Center', 'center'),
              _buildPositionOption('Center', 'center'),
              _buildPositionOption('Bottom Left', 'bottomLeft'),
              _buildPositionOption('Bottom Center', 'bottomCenter'),
              _buildPositionOption('Bottom Right', 'bottomRight'),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Rotation: ${rotation.round()}°',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: rotation,
            min: -45,
            max: 45,
            divisions: 18,
            onChanged: (value) {
              setState(() {
                rotation = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = textColor == color;

    return GestureDetector(
      onTap: () {
        setState(() {
          textColor = color;
        });
      },
      child: Container(
        width: 40.w,
        height: 40.h,
        margin: EdgeInsets.only(right: 8.w),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, color: Colors.white, size: 20.sp)
            : null,
      ),
    );
  }

  Widget _buildPositionOption(String label, String pos) {
    final isSelected = position == pos;

    return GestureDetector(
      onTap: () {
        setState(() {
          position = pos;
        });
      },
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.lightBlue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.lightBlue : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.lightBlue : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
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
            'Preview',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            height: 200.h,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                // Document background
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 8.h,
                        width: double.infinity,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 8.h,
                        width: 200.w,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 8.h,
                        width: 150.w,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
                // Watermark preview
                if (watermarkType == 'text' && _textController.text.isNotEmpty)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: rotation * 3.14159 / 180,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            _textController.text,
                            style: TextStyle(
                              fontSize: fontSize / 2,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (watermarkType == 'image' && watermarkImage != null)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: rotation * 3.14159 / 180,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(watermarkImage!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

  bool _canApplyWatermark() {
    if (watermarkType == 'text') {
      return _textController.text.isNotEmpty;
    } else {
      return watermarkImage != null;
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

  void _selectWatermarkImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        watermarkImage = File(result.files.single.path!);
      });
    }
  }

  void _applyWatermark() async {
    if (!_canApplyWatermark()) return;

    setState(() => isLoading = true);

    try {
      // Apply watermark using PDFService
      final result = await _pdfService.addWatermarkToPdf(
        pdfFile: selectedPdf!,
        outputTitle: 'Watermarked_${selectedPdf!.path.split('/').last}',
        text: watermarkType == 'text' ? _textController.text : null,
        imageFile: watermarkType == 'image' ? watermarkImage : null,
        opacity: opacity,
        fontSize: fontSize,
        textColor: textColor,
      );

      setState(() => isLoading = false);

      if (result != null && mounted) {
        // Navigate to preview screen with the watermarked PDF
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              pdfFile: result,
              title: 'Watermarked PDF',
              subtitle: 'Watermark applied successfully',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to apply watermark'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        // Check if it's a password-protected PDF
        if (PasswordProtectedPdfDialog.isPasswordError(e)) {
          PasswordProtectedPdfDialog.show(context, toolName: 'watermarked');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
