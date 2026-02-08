import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../core/themes.dart';
import 'document_scanner_screen.dart';

class ScanPreviewScreen extends StatefulWidget {
  final String imagePath;
  final ScanMode scanMode;
  final List<Offset>? detectedCorners;

  const ScanPreviewScreen({
    Key? key,
    required this.imagePath,
    required this.scanMode,
    this.detectedCorners,
  }) : super(key: key);

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  File? _processedImage;
  bool _isProcessing = false;
  bool _isEnhanced = false;
  String _selectedFilter = 'Original';

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'icon': Icons.image},
    {'name': 'Enhanced', 'icon': Icons.auto_fix_high},
    {'name': 'Black & White', 'icon': Icons.filter_b_and_w},
    {'name': 'Grayscale', 'icon': Icons.gradient},
    {'name': 'Magic Color', 'icon': Icons.color_lens},
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _processedImage = File(widget.imagePath);
    });
  }

  Future<void> _applyFilter(String filterName) async {
    if (_processedImage == null) return;

    setState(() {
      _isProcessing = true;
      _selectedFilter = filterName;
    });

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return;

      img.Image processedImage;

      switch (filterName) {
        case 'Enhanced':
          processedImage = _enhanceDocument(image);
          break;
        case 'Black & White':
          processedImage = _applyBlackAndWhite(image);
          break;
        case 'Grayscale':
          processedImage = img.grayscale(image);
          break;
        case 'Magic Color':
          processedImage = _applyMagicColor(image);
          break;
        default:
          processedImage = image;
      }

      // Save processed image
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(tempPath);
      await processedFile
          .writeAsBytes(img.encodeJpg(processedImage, quality: 95));

      setState(() {
        _processedImage = processedFile;
        _isProcessing = false;
      });
    } catch (e) {
      print('Filter error: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  img.Image _enhanceDocument(img.Image image) {
    // Enhance contrast and brightness
    var enhanced =
        img.adjustColor(image, brightness: 1.1, contrast: 1.3, saturation: 1.1);
    enhanced = img.adjustColor(enhanced, brightness: 1.05);
    return enhanced;
  }

  img.Image _applyBlackAndWhite(img.Image image) {
    // Convert to grayscale first
    var bw = img.grayscale(image);
    // Apply threshold for binary black and white
    for (var y = 0; y < bw.height; y++) {
      for (var x = 0; x < bw.width; x++) {
        final pixel = bw.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        final newColor = luminance > 128
            ? img.ColorRgb8(255, 255, 255)
            : img.ColorRgb8(0, 0, 0);
        bw.setPixel(x, y, newColor);
      }
    }
    return bw;
  }

  img.Image _applyMagicColor(img.Image image) {
    // Enhance colors and remove shadows
    var enhanced = img.adjustColor(image,
        brightness: 1.15, contrast: 1.4, saturation: 1.2);
    enhanced = img.adjustColor(enhanced, brightness: 1.1);
    return enhanced;
  }

  Future<void> _cropAndSave() async {
    if (_processedImage == null) return;

    // Navigate back with the processed image path
    Navigator.pop(context, _processedImage!.path);
  }

  Future<void> _rotateImage() async {
    if (_processedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await _processedImage!.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return;

      final rotated = img.copyRotate(image, angle: 90);

      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final rotatedFile = File(tempPath);
      await rotatedFile.writeAsBytes(img.encodeJpg(rotated, quality: 95));

      setState(() {
        _processedImage = rotatedFile;
        _isProcessing = false;
      });
    } catch (e) {
      print('Rotate error: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.gray900),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getScanModeTitle(),
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.gray900,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.rotate_right, color: AppColors.gray900),
            onPressed: _rotateImage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            child: Container(
              color: Colors.black,
              child: _processedImage != null
                  ? Stack(
                      children: [
                        Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(
                              _processedImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        if (_isProcessing)
                          Container(
                            color: Colors.black.withOpacity(0.5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            ),
          ),

          // Filter Options
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: SizedBox(
              height: 90.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter['name'];
                  return GestureDetector(
                    onTap: () => _applyFilter(filter['name']),
                    child: Container(
                      width: 70.w,
                      margin: EdgeInsets.only(right: 12.w),
                      child: Column(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.gray100,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              filter['icon'],
                              color:
                                  isSelected ? Colors.white : AppColors.gray600,
                              size: 28.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            filter['name'],
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.gray600,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Retake',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _cropAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Use This Scan',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScanModeTitle() {
    switch (widget.scanMode) {
      case ScanMode.document:
        return 'Document Scan';
      case ScanMode.idCard:
        return 'ID Card Scan';
      case ScanMode.receipt:
        return 'Receipt Scan';
      case ScanMode.businessCard:
        return 'Business Card Scan';
    }
  }
}
