import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../core/themes.dart';
import '../services/pdf_service.dart';
import '../services/file_management_service.dart';
import '../services/notification_service.dart';
import '../providers/document_provider.dart';
import '../models/document_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'pdf_viewer_screen.dart';
import '../widgets/interstitial_ad_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/modern_ui_components.dart';

class ImageToPdfScreen extends StatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  State<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen>
    with TickerProviderStateMixin {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final PDFService _pdfService = PDFService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isProcessing = false;
  String _pdfTitle = '';
  PageSize _selectedPageSize = PageSize.a4;
  bool _fitToPage = true;
  final double _margin = 20.0;
  bool _addPageNumbers = false;
  String? _watermarkText;
  bool _showLoadingOverlay = false;
  final GlobalKey<AnimatedListState> _imageListKey =
      GlobalKey<AnimatedListState>();

  // New for success preview
  File? _generatedPDF;
  bool _showSuccessPreview = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    
    // Preload interstitial ad for smooth experience
    Future.delayed(const Duration(milliseconds: 500), () {
      InterstitialAdHelper.preloadAd();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isNotEmpty) {
        // Copy images to app cache to ensure they persist for PDF generation
        final persistentImages = <File>[];
        for (final xFile in images) {
          try {
            final sourceFile = File(xFile.path);
            if (await sourceFile.exists()) {
              // Read the image bytes to ensure it's accessible
              final bytes = await sourceFile.readAsBytes();
              
              // Copy to app's cache directory with a permanent name
              final cacheDir = await getApplicationCacheDirectory();
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final persistentFile = File(
                '${cacheDir.path}/selected_image_$timestamp${xFile.path.replaceAll(RegExp(r'.*\.'), '.')}'
              );
              
              // Write bytes to new location
              await persistentFile.writeAsBytes(bytes);
              persistentImages.add(persistentFile);
              
              print('ImageToPdfScreen: Copied image to ${persistentFile.path}');
            }
          } catch (e) {
            print('ImageToPdfScreen: Error copying image: $e');
            // Fall back to original file if copy fails
            persistentImages.add(File(xFile.path));
          }
        }

        if (persistentImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(persistentImages);
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error picking images: $e');
      print('ImageToPdfScreen: Error in _pickImages: $e');
    }
  }

  void _removeImage(int index) {
    if (index < 0 || index >= _selectedImages.length) return;
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: AppColors.successLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _createPDF() async {
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please select at least one image');
      return;
    }
    if (_pdfTitle.trim().isEmpty) {
      _showErrorSnackBar('Please enter a PDF title');
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _showLoadingOverlay = true;
      });
    }

    // Show system UI and start PDF generation
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (e) {
      print('ImageToPdfScreen: Error setting system UI mode: $e');
    }

    // Start PDF generation process
    _generatePDF();

    // Show interstitial ad after PDF generation starts (non-blocking)
    // This ensures the user sees the loading state while ad loads/shows
    InterstitialAdHelper.showInterstitialAd(
      onAdClosed: () {
        print('ImageToPdfScreen: Interstitial ad closed');
        // Ad handling is complete, PDF generation continues in background
      },
    );
  }

  Future<void> _generatePDF() async {
    try {
      print('ImageToPdfScreen: Starting PDF generation...');
      print('ImageToPdfScreen: Images count: ${_selectedImages.length}');
      print('ImageToPdfScreen: Title: ${_pdfTitle.trim()}');

      // Run PDF generation on main thread (platform channels don't work in isolates)
      final pdfService = PDFService();
      final file = await pdfService.createAdvancedPDF(
        imageFiles: _selectedImages,
        title: _pdfTitle.trim(),
        pageSize: _selectedPageSize,
        fitToPage: _fitToPage,
        margin: _margin,
        addPageNumbers: _addPageNumbers,
        watermarkText: _watermarkText,
      );

      print('ImageToPdfScreen: PDF generation completed. File: ${file?.path}');

      if (file != null && await file.exists()) {
        print('ImageToPdfScreen: PDF file exists, size: ${await file.length()} bytes');
        
        final documentProvider =
            Provider.of<DocumentProvider>(context, listen: false);
        await documentProvider.createDocument(
          name: _pdfTitle.trim(),
          imagePath: file.path,
          pdfPath: file.path,
          type: DocumentType.pdf,
        );

        print('ImageToPdfScreen: Document saved to provider');

        if (mounted) {
          setState(() {
            _isProcessing = false;
            _showLoadingOverlay = false;
            _generatedPDF = file;
            _showSuccessPreview = true;
          });
          _showSuccessSnackBar('PDF created successfully!');
          print('ImageToPdfScreen: PDF creation successful, showing preview');
        }
      } else {
        print('ImageToPdfScreen: PDF file does not exist or is null');
        if (mounted) {
          _showErrorSnackBar('Failed to create PDF: File not found');
          setState(() {
            _isProcessing = false;
            _showLoadingOverlay = false;
          });
        }
      }
    } catch (e) {
      print('ImageToPdfScreen: Error in _generatePDF: $e');
      print('ImageToPdfScreen: Stack trace: ${StackTrace.current}');
      if (mounted) {
        _showErrorSnackBar('Error creating PDF: $e');
        setState(() {
          _isProcessing = false;
          _showLoadingOverlay = false;
        });
      }
    }
  }

  Widget _buildLoadingOverlay() {
    return AnimatedOpacity(
      opacity: _showLoadingOverlay ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: _showLoadingOverlay
          ? ModernLoadingOverlay(
              message: 'Generating PDF...',
              subtitle: 'Please wait while we create your document',
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildImageGrid() {
    if (_selectedImages.isEmpty) {
      return ModernEmptyState(
        icon: Icons.image_outlined,
        title: 'No Images Selected',
        subtitle: 'Tap "Add from Gallery" above to select images for your PDF',
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Column(
        key: ValueKey(_selectedImages.length),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Selected Images (${_selectedImages.length})',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                      color: AppColors.gray900)),
              TextButton.icon(
                onPressed: _clearAllImages,
                icon: Icon(Icons.delete_sweep_rounded,
                    color: AppColors.error, size: 20.sp),
                label: Text('Clear All',
                    style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gray50, AppColors.background],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.gray200,
                width: 1.5,
              ),
            ),
            padding: EdgeInsets.all(12.w),
            child: StaggeredGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 3 : 5,
              mainAxisSpacing: 14.h,
              crossAxisSpacing: 14.w,
              children: List.generate(_selectedImages.length, (index) {
                final file = _selectedImages[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    key: ValueKey(file.path),
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: FutureBuilder<bool>(
                          future: file.exists(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                color: AppColors.gray100,
                                height: 120.h,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryBlue)),
                              );
                            }
                            if (snapshot.hasError ||
                                !(snapshot.data ?? false)) {
                              return Container(
                                color: AppColors.gray100,
                                height: 120.h,
                                child: Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        color: AppColors.error, size: 32.sp)),
                              );
                            }
                            return Image.file(
                              file,
                              width: double.infinity,
                              height: 120.h,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors.gray100,
                                height: 120.h,
                                child: Center(
                                    child: Icon(Icons.broken_image,
                                        color: AppColors.error, size: 32.sp)),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 6.h,
                        right: 6.w,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            padding: EdgeInsets.all(4.w),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6.h,
                        left: 6.w,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          child: Text('Page ${index + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                  color: AppColors.primaryBlue)),
                        ),
                      ),
                      Positioned(
                        bottom: 6.h,
                        right: 6.w,
                        child: ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            padding: EdgeInsets.all(4.w),
                            child: Icon(Icons.drag_handle,
                                color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccessPreview && _generatedPDF != null) {
      return _buildPDFSuccessPreview();
    }
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final screenWidth = MediaQuery.of(context).size.width;
        final cardColor = isDark ? AppColors.surface : Colors.white;
        final textColor = isDark ? AppColors.gray900 : AppColors.gray900;
        final subtitleColor = isDark ? AppColors.gray300 : AppColors.gray600;
        final borderColor = isDark ? AppColors.gray700 : AppColors.gray200;
        final iconBgColor = isDark ? AppColors.gray800 : AppColors.gray100;

        return Stack(
          children: [
            // Banner ad at the very top, inside SafeArea
            // SafeArea(
            //   top: true,
            //   bottom: false,
            //   child: Container(
            //     width: double.infinity,
            //     child: const NativeAdWidget(),
            //   ),
            // ),
            Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.image_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Image to PDF',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.background,
                foregroundColor: textColor,
                elevation: 0,
                iconTheme: IconThemeData(color: textColor),
                actions: [
                  if (_selectedImages.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.emerald.withOpacity(0.15),
                                AppColors.emerald.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: AppColors.emerald.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.emerald,
                                size: 16.sp,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${_selectedImages.length} ${_selectedImages.length == 1 ? "Image" : "Images"}',
                                style: TextStyle(
                                  color: AppColors.emerald,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              floatingActionButton: _selectedImages.isNotEmpty
                  ? FloatingActionButton.extended(
                      onPressed: _isProcessing ? null : _createPDF,
                      icon: _isProcessing
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white),
                      label:
                          Text(_isProcessing ? 'Generating...' : 'Create PDF',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              )),
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 8,
                      highlightElevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    )
                  : null,
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Card
                      ModernCard(
                        padding: EdgeInsets.all(24.w),
                        borderColor: AppColors.primaryBlue.withOpacity(0.15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add Images Button with modern design
                            ModernActionButton(
                              label: 'Add from Gallery',
                              icon: Icons.add_photo_alternate_rounded,
                              onPressed: _pickImages,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.primaryBlueLight,
                                ],
                              ),
                            ),
                            SizedBox(height: 28.h),
                            _buildImageGrid(),
                            if (_selectedImages.isNotEmpty) ...[
                              SizedBox(height: 32.h),
                              Container(
                                height: 1.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.gray200,
                                      AppColors.gray100,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              // PDF Settings Section
                              ModernSectionHeader(
                                icon: Icons.settings_rounded,
                                iconColor: AppColors.primaryBlue,
                                title: 'PDF Settings',
                                subtitle: 'Customize your document',
                              ),
                              SizedBox(height: 20.h),
                              // PDF Title
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Document Title',
                                  hintText: 'Enter PDF title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                    borderSide: BorderSide(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.5),
                                        width: 1.5.w),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                    borderSide: BorderSide(
                                        color: AppColors.gray300, width: 1.5.w),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                    borderSide: BorderSide(
                                        color: AppColors.primaryBlue,
                                        width: 2.w),
                                  ),
                                  prefixIcon: Container(
                                    margin: EdgeInsets.all(8.w),
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryBlue
                                              .withOpacity(0.15),
                                          AppColors.primaryBlue
                                              .withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(Icons.title_rounded,
                                        color: AppColors.primaryBlue,
                                        size: 20.sp),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.gray50,
                                  labelStyle: TextStyle(
                                    color: AppColors.gray700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextStyle(
                                    fontSize: 15.sp, color: textColor),
                                onChanged: (value) => _pdfTitle = value,
                              ),
                              SizedBox(height: 16.h),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      canvasColor: Colors.white,
                                      textTheme:
                                          Theme.of(context).textTheme.copyWith(
                                                titleMedium: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14.sp),
                                                bodyMedium: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14.sp),
                                              ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButtonFormField<PageSize>(
                                        decoration: InputDecoration(
                                          labelText: 'Page Size',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                          ),
                                          prefixIcon: Icon(Icons.aspect_ratio,
                                              color: AppColors.primaryBlue),
                                          filled: true,
                                          fillColor: AppColors.gray50,
                                        ),
                                        value: _selectedPageSize,
                                        items: PageSize.values.map((size) {
                                          return DropdownMenuItem(
                                            value: size,
                                            child: Text(size.name.toUpperCase(),
                                                style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: Colors.black)),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedPageSize = value;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12.h),
                                  SwitchListTile(
                                    title: Text('Fit to Page',
                                        style: TextStyle(
                                            fontSize: 14.sp, color: textColor)),
                                    value: _fitToPage,
                                    onChanged: (value) {
                                      setState(() {
                                        _fitToPage = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: AppColors.primaryBlue,
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              SwitchListTile(
                                title: Text('Add Page Numbers',
                                    style: TextStyle(
                                        fontSize: 14.sp, color: textColor)),
                                value: _addPageNumbers,
                                onChanged: (value) {
                                  setState(() {
                                    _addPageNumbers = value;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primaryBlue,
                              ),
                              SizedBox(height: 12.h),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Watermark Text (Optional)',
                                  hintText: 'Enter watermark text',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.7),
                                        width: 2.w),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.7),
                                        width: 2.w),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide(
                                        color: AppColors.primaryBlue,
                                        width: 2.2.w),
                                  ),
                                  prefixIcon: Icon(Icons.water_drop,
                                      color: AppColors.primaryBlue),
                                  filled: true,
                                  fillColor: AppColors.gray50,
                                ),
                                style: TextStyle(
                                    fontSize: 15.sp, color: textColor),
                                onChanged: (value) => _watermarkText = value,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_showLoadingOverlay) _buildLoadingOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    double scale = 1.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25 * scale),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1 * scale,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25 * scale),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 18 * scale,
                ),
                SizedBox(width: 6 * scale),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14 * scale,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildPDFSuccessPreview(BuildContext context) {
  //   final theme = Theme.of(context);
  //   final textColor = theme.brightness == Brightness.dark
  //       ? AppColors.gray900
  //       : AppColors.gray900;
  //   final screenWidth = MediaQuery.of(context).size.width;
  //   final scale = screenWidth / 375.0;
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFF8FAFC),
  //     appBar: AppBar(
  //       title: const Text(
  //         'PDF Ready',
  //         style: TextStyle(
  //           fontWeight: FontWeight.w600,
  //           fontSize: 20,
  //         ),
  //       ),
  //       elevation: 0,
  //       backgroundColor: Colors.white,
  //       foregroundColor: const Color(0xFF1E293B),
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back_ios_new),
  //         onPressed: () {
  //           setState(() {
  //             _showSuccessPreview = false;
  //             _generatedPDF = null;
  //           });
  //         },
  //       ),
  //     ),
  //     body: Stack(
  //       children: [
  //         Column(
  //           children: [
  //             // Success Header
  //             Container(
  //               width: double.infinity,
  //               margin: const EdgeInsets.all(16),
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topLeft,
  //                   end: Alignment.bottomRight,
  //                   colors: [
  //                     Colors.green.shade50,
  //                     Colors.green.shade100,
  //                   ],
  //                 ),
  //                 borderRadius: BorderRadius.circular(16),
  //                 border: Border.all(
  //                   color: Colors.green.withOpacity(0.2),
  //                   width: 1,
  //                 ),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.all(12),
  //                     decoration: BoxDecoration(
  //                       color: Colors.green,
  //                       borderRadius: BorderRadius.circular(50),
  //                     ),
  //                     child: const Icon(
  //                       Icons.check_circle,
  //                       color: Colors.white,
  //                       size: 24,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Expanded(
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         const Text(
  //                           'PDF Generated Successfully!',
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.w700,
  //                             color: Color(0xFF1E293B),
  //                           ),
  //                         ),
  //                         Text(
  //                           'Ready to save and share',
  //                           style: TextStyle(
  //                             fontSize: 14,
  //                             color: Colors.grey,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             // View PDF Button
  //             Container(
  //               width: double.infinity,
  //               margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //               child: ElevatedButton.icon(
  //                 onPressed: () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => PDFViewerScreen(
  //                         pdfFile: _generatedPDF!,
  //                         title: _pdfTitle.trim(),
  //                         pageCount: _selectedImages.length,
  //                       ),
  //                     ),
  //                   );
  //                 },
  //                 icon: const Icon(Icons.visibility, size: 20),
  //                 label: const Text(
  //                   'View PDF',
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: AppColors.primaryBlue,
  //                   foregroundColor: Colors.white,
  //                   padding: const EdgeInsets.symmetric(vertical: 16),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   elevation: 4,
  //                   shadowColor: AppColors.primaryBlue.withOpacity(0.3),
  //                 ),
  //               ),
  //             ),
  //             // PDF Info
  //             Container(
  //               margin: const EdgeInsets.symmetric(horizontal: 16),
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(16),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: Colors.black.withOpacity(0.05),
  //                     blurRadius: 20,
  //                     offset: const Offset(0, 4),
  //                   ),
  //                 ],
  //                 border: Border.all(
  //                   color: Colors.grey.withOpacity(0.1),
  //                   width: 1,
  //                 ),
  //               ),
  //               child: Column(
  //                 children: [
  //                   // PDF Header
  //                   Container(
  //                     padding: const EdgeInsets.all(16),
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey.shade50,
  //                       borderRadius: const BorderRadius.only(
  //                         topLeft: Radius.circular(16),
  //                         topRight: Radius.circular(16),
  //                       ),
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         Container(
  //                           padding: const EdgeInsets.all(8),
  //                           decoration: BoxDecoration(
  //                             gradient: LinearGradient(
  //                               colors: [
  //                                 AppColors.primaryBlue,
  //                                 AppColors.primaryBlue.withOpacity(0.8),
  //                               ],
  //                             ),
  //                             borderRadius: BorderRadius.circular(8),
  //                           ),
  //                           child: const Icon(
  //                             Icons.picture_as_pdf,
  //                             color: Colors.white,
  //                             size: 20,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 12),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 _pdfTitle.trim(),
  //                                 style: const TextStyle(
  //                                   fontWeight: FontWeight.w700,
  //                                   fontSize: 16,
  //                                   color: Color(0xFF1E293B),
  //                                 ),
  //                               ),
  //                               Text(
  //                                 'PDF Document',
  //                                 style: TextStyle(
  //                                   color: Colors.grey.shade600,
  //                                   fontSize: 12,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                   // Compact Preview & Info
  //                   Container(
  //                     padding: const EdgeInsets.all(16),
  //                     child: Row(
  //                       children: [
  //                         // PDF Preview
  //                         Container(
  //                           width: 80,
  //                           height: 100,
  //                           decoration: BoxDecoration(
  //                             gradient: LinearGradient(
  //                               begin: Alignment.topLeft,
  //                               end: Alignment.bottomRight,
  //                               colors: [
  //                                 Colors.grey.shade50,
  //                                 Colors.grey.shade100,
  //                               ],
  //                             ),
  //                             borderRadius: BorderRadius.circular(8),
  //                             border: Border.all(
  //                               color: Colors.grey.withOpacity(0.2),
  //                               width: 1,
  //                             ),
  //                           ),
  //                           child: Column(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               Icon(
  //                                 Icons.picture_as_pdf,
  //                                 size: 24,
  //                                 color: AppColors.primaryBlue,
  //                               ),
  //                               const SizedBox(height: 4),
  //                               Text(
  //                                 '${_selectedImages.length}',
  //                                 style: TextStyle(
  //                                   fontSize: 12,
  //                                   fontWeight: FontWeight.w600,
  //                                   color: AppColors.primaryBlue,
  //                                 ),
  //                               ),
  //                               Text(
  //                                 'pages',
  //                                 style: TextStyle(
  //                                   fontSize: 10,
  //                                   color: Colors.grey.shade600,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                         const SizedBox(width: 16),
  //                         // File Details
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               _buildCompactDetailRow(
  //                                   'Pages', '${_selectedImages.length} pages'),
  //                               const SizedBox(height: 8),
  //                               _buildCompactDetailRow('Size',
  //                                   _selectedPageSize.name.toUpperCase()),
  //                               // File size can be added with a FutureBuilder if needed
  //                             ],
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const Spacer(),

  //             // Native Ad
  //             const Padding(
  //               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //               child: NativeAdWidget(),
  //             ),

  //             // Action Buttons (styled like create_pdf_screen.dart)
  //             SafeArea(
  //               child: Container(
  //                 margin: EdgeInsets.all(16 * scale),
  //                 child: Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     Flexible(
  //                       child: _buildSecondaryActionButton(
  //                         icon: Icons.save,
  //                         label: 'Save Only',
  //                         onTap: () async {
  //                           if (_generatedPDF == null) return;
  //                           final documentProvider =
  //                               Provider.of<DocumentProvider>(context,
  //                                   listen: false);
  //                           await documentProvider.createDocument(
  //                             name: _pdfTitle.trim(),
  //                             imagePath: _generatedPDF!.path,
  //                             pdfPath: _generatedPDF!.path,
  //                             type: DocumentType.pdf,
  //                           );
  //                           _showSuccessSnackBar('PDF saved to Documents!');
  //                         },
  //                         color: Colors.green,
  //                         scale: scale,
  //                       ),
  //                     ),
  //                     SizedBox(width: 12 * scale),
  //                     Flexible(
  //                       child: _buildSecondaryActionButton(
  //                         icon: Icons.share,
  //                         label: 'Share Only',
  //                         onTap: () async {
  //                           if (_generatedPDF == null) return;
  //                           await Share.shareXFiles(
  //                             [XFile(_generatedPDF!.path)],
  //                             text: 'PDF created with Document Scanner',
  //                             subject: _pdfTitle.trim(),
  //                           );
  //                           _showSuccessSnackBar('PDF shared successfully!');
  //                         },
  //                         color: Colors.blue,
  //                         scale: scale,
  //                       ),
  //                     ),
  //                     SizedBox(width: 12 * scale),
  //                     Flexible(
  //                       child: _buildSecondaryActionButton(
  //                         icon: Icons.edit,
  //                         label: 'Edit',
  //                         onTap: () {
  //                           setState(() {
  //                             _showSuccessPreview = false;
  //                             _generatedPDF = null;
  //                           });
  //                         },
  //                         color: Colors.orange,
  //                         scale: scale,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         if (_showLoadingOverlay) _buildLoadingOverlay(),
  //       ],
  //     ),
  //   );
  // }


  Widget _buildPDFSuccessPreview() {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PDF Ready',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            setState(() {
              _showSuccessPreview = false;
              _generatedPDF = null;
            });
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showMoreOptions,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.more_horiz_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'More',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Enhanced Success Banner with Gradient
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PDF Created Successfully!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedImages.length} page${_selectedImages.length == 1 ? '' : 's'} \u2022 ${_selectedPageSize.name.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Enhanced PDF Info Card with Image Thumbnails & Modern Design
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // PDF Header with Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF8FAFC),
                            Colors.grey.shade50,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pdfTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Color(0xFF1E293B),
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'PDF Document',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Thumbnail Preview Section
                    if (_selectedImages.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.photo_library_rounded,
                                    size: 18,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Page Preview',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton.icon(
                                    onPressed: _viewPDF,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: Icon(
                                      Icons.fullscreen_rounded,
                                      size: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    label: Text(
                                      'View Full',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 110,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length > 5
                                    ? 5
                                    : _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.3),
                                              width: 2.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.file(
                                              _selectedImages[index],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.black.withOpacity(0.8),
                                                  Colors.black.withOpacity(0.6),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
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
                            if (_selectedImages.length > 5)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '+${_selectedImages.length - 5} more page${_selectedImages.length - 5 == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade200,
                    ),

                    // File Details with Icons
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.description_rounded,
                            'Total Pages',
                            '${_selectedImages.length} page${_selectedImages.length == 1 ? '' : 's'}',
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            Icons.crop_square_rounded,
                            'Page Size',
                            _selectedPageSize.name.toUpperCase(),
                          ),
                          const SizedBox(height: 14),
                          FutureBuilder<String>(
                            future: _getPDFFileSize(),
                            builder: (context, snapshot) {
                              return _buildDetailRow(
                                Icons.storage_rounded,
                                'File Size',
                                snapshot.data ?? 'Calculating...',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Compact Action Buttons
              SafeArea(
                child: Container(
                  margin: EdgeInsets.all(16 * scale),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Secondary Actions Row
                      Row(
                        children: [
                          Flexible(
                            child: _buildSecondaryActionButton(
                              icon: Icons.save,
                              label: 'Save Only',
                              onTap: _savePDFOnly,
                              color: Colors.green,
                              scale: scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Flexible(
                            child: _buildSecondaryActionButton(
                              icon: Icons.share,
                              label: 'Share Only',
                              onTap: _sharePDFOnly,
                              color: Colors.blue,
                              scale: scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Flexible(
                            child: _buildSecondaryActionButton(
                              icon: Icons.edit,
                              label: 'Edit',
                              onTap: () {
                                setState(() {
                                  _showSuccessPreview = false;
                                  _generatedPDF = null;
                                });
                              },
                              color: Colors.orange,
                              scale: scale,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (_showLoadingOverlay)
                Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while we process your request',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String> _getPDFFileSize() async {
    try {
      if (_generatedPDF == null || !await _generatedPDF!.exists()) {
        return 'N/A';
      }
      final bytes = await _generatedPDF!.length();
      if (bytes < 1024) {
        return '${bytes}B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(2)}KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  void _viewPDF() {
    if (_generatedPDF == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          pdfFile: _generatedPDF!,
          title: _pdfTitle.trim(),
          pageCount: _selectedImages.length,
        ),
      ),
    );
  }

  Future<void> _savePDFOnly() async {
    if (_generatedPDF == null) {
      _showErrorSnackBar('No PDF to save');
      return;
    }

    print('ImageToPDFScreen: Saving PDF only...');
    setState(() => _showLoadingOverlay = true);

    try {
      final fileService = FileManagementService();
      final savedDocument = await fileService.savePDFDocument(
        name: _pdfTitle.trim(),
        pdfPath: _generatedPDF!.path,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (savedDocument != null) {
        print('ImageToPDFScreen: PDF saved successfully');
        if (mounted) {
          _showSuccessSnackBar('PDF saved to Documents successfully!');
          await NotificationService().showNotification(
            title: 'File Saved',
            body: 'Your PDF has been saved successfully!',
          );
        }
      } else {
        print('ImageToPDFScreen: Failed to save PDF');
        if (mounted) {
          _showErrorSnackBar('Failed to save PDF');
        }
      }
    } catch (e) {
      print('ImageToPDFScreen: Error saving PDF: $e');
      if (mounted) {
        _showErrorSnackBar('Error saving PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _showLoadingOverlay = false);
      }
    }
  }

  Future<void> _sharePDFOnly() async {
    if (_generatedPDF == null) {
      _showErrorSnackBar('No PDF to share');
      return;
    }

    print('ImageToPDFScreen: Sharing PDF only...');

    try {
      await Share.shareXFiles(
        [XFile(_generatedPDF!.path)],
        text: 'PDF created with Document Scanner',
        subject: _pdfTitle.trim(),
      );

      print('ImageToPDFScreen: PDF shared successfully');
      if (mounted) {
        _showSuccessSnackBar('PDF shared successfully!');
      }
    } catch (e) {
      print('ImageToPDFScreen: Error sharing PDF: $e');
      if (mounted) {
        _showErrorSnackBar('Error sharing PDF: $e');
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'More Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.save_alt, color: Theme.of(context).primaryColor),
                    title: const Text('Save & Share'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_generatedPDF == null) return;
                      setState(() => _showLoadingOverlay = true);
                      try {
                        final documentProvider =
                            Provider.of<DocumentProvider>(context, listen: false);
                        await documentProvider.createDocument(
                          name: _pdfTitle.trim(),
                          imagePath: _generatedPDF!.path,
                          pdfPath: _generatedPDF!.path,
                          type: DocumentType.pdf,
                        );
                        await Share.shareXFiles(
                          [XFile(_generatedPDF!.path)],
                          text: 'PDF created with Document Scanner',
                          subject: _pdfTitle.trim(),
                        );
                        _showSuccessSnackBar('PDF saved and shared!');
                      } catch (e) {
                        _showErrorSnackBar('Error: $e');
                      } finally {
                        setState(() => _showLoadingOverlay = false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.file_download, color: Theme.of(context).primaryColor),
                    title: const Text('View PDF Details'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPDFDetails();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPDFDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${_pdfTitle.trim()}'),
            const SizedBox(height: 8),
            Text('Pages: ${_selectedImages.length}'),
            const SizedBox(height: 8),
            Text('Page Size: ${_selectedPageSize.name.toUpperCase()}'),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getPDFFileSize(),
              builder: (context, snapshot) {
                return Text('Size: ${snapshot.data ?? "Calculating..."}');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

