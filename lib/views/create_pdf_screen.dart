import 'dart:io';
import 'package:docscanner/widgets/banner_ad_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:reorderables/reorderables.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../services/pdf_service.dart';
import '../services/file_management_service.dart';
import '../services/camera_service.dart';
import '../providers/document_provider.dart';
import '../core/themes.dart';
import 'image_editor_screen.dart';

import 'crop_screen.dart';
import '../main.dart';
import 'pdf_viewer_screen.dart';
import 'pdf_settings_screen.dart';
import '../services/notification_service.dart';
import '../widgets/interstitial_ad_helper.dart';
import 'package:flutter/foundation.dart';

class CreatePDFScreen extends StatefulWidget {
  final File? editedImage;

  const CreatePDFScreen({Key? key, this.editedImage}) : super(key: key);

  @override
  State<CreatePDFScreen> createState() => _CreatePDFScreenState();
}

class _CreatePDFScreenState extends State<CreatePDFScreen>
    with WidgetsBindingObserver {
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  late CameraService _cameraService;
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  bool _isHDMode = true;
  bool _isFlashOn = false;
  bool _isCapturing = false;
  bool _isPickingFile = false;
  bool _isLoading = false;
  bool _showCamera = true;
  bool _showPreview = false;
  bool _isReorderMode = false;
  bool _pendingCapture = false;
  DateTime? _cameraInitStartTime;
  final Duration _cameraInitTimeout = const Duration(seconds: 5);
  File? _previewPDF;
  String _pdfTitle = 'My PDF';
  PageSize _selectedPageSize = PageSize.a4;
  bool _fitToPage = true;
  double _margin = 16;
  bool _addPageNumbers = false;
  String _watermarkText = '';
  CameraFramePreset _cameraFrame = CameraFramePreset.a4Portrait;
  Map<String, dynamic>? _topNotification;

  // Track aspect ratio for each image (image path -> aspect ratio)
  final Map<String, double> _imageAspectRatios = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService = CameraService();

    // Add edited image if provided
    if (widget.editedImage != null) {
      _selectedImages.add(widget.editedImage!);
      print('CreatePDFScreen: Added edited image: ${widget.editedImage!.path}');
    }

    _initializeCamera();
    
    // Preload interstitial ad in background to avoid lag during PDF generation
    Future.delayed(const Duration(milliseconds: 500), () {
      InterstitialAdHelper.preloadAd();
    });
  }

  @override
  void dispose() {
    print('CreatePDFScreen: Disposing...');
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('CreatePDFScreen: App lifecycle changed to $state');
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (!_isPickingFile) {
        print(
            'CreatePDFScreen: App inactive/paused, disposing camera and resetting service...');
        _disposeCamera();
        _cameraService.reset();
        if (mounted) {
          setState(() {
            _isCameraInitialized = false;
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      print('CreatePDFScreen: App resumed, checking camera state...');
      // Always reset and reinitialize camera on resume if we're in camera view
      if (_showCamera) {
        print(
            'CreatePDFScreen: App resumed, resetting and reinitializing camera...');
        _cameraService.reset();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _initializeCamera();
          }
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    print('CreatePDFScreen: Disposing camera...');
    await _cameraService.dispose();
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _isInitializingCamera = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    print('CreatePDFScreen: Initializing camera...');
    // Always reset before initializing to avoid stuck state
    _cameraService.reset();
    // Prevent multiple simultaneous initializations
    if (_isInitializingCamera || _isCameraInitialized) {
      print(
          'CreatePDFScreen: Camera already initializing or initialized, skipping');
      return;
    }
    setState(() {
      _isInitializingCamera = true;
      _isCameraInitialized = false;
      _cameraInitStartTime = DateTime.now();
    });
    try {
      // Check camera availability
      final availableCameras = await getAvailableCameras();
      if (availableCameras.isEmpty) {
        print('CreatePDFScreen: No cameras available');
        if (mounted) {
          _showTopNotification('No cameras available', color: Colors.red);
        }
        return;
      }
      // Check camera permission
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) {
        print('CreatePDFScreen: Camera permission denied');
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }
      // Initialize camera with optimized resolution for speed
      print('CreatePDFScreen: Initializing camera controller...');
      await _cameraService.initialize(
        availableCameras.first,
        // Use medium resolution by default for faster initialization and capture
        resolution: _isHDMode ? ResolutionPreset.ultraHigh : ResolutionPreset.high,
      );

      // Ensure flash starts off by default until the user enables it
      try {
        await _cameraService.controller?.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      } catch (e) {
        print('CreatePDFScreen: Unable to enforce flash off on init: $e');
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isInitializingCamera = false;
          _cameraInitStartTime = null;
        });
        print('CreatePDFScreen: Camera initialized successfully');
        // If user tapped capture while initializing, trigger a pending capture now
        if (_pendingCapture && !_isCapturing) {
          _pendingCapture = false;
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _captureImage();
          });
        }
      }
    } catch (e) {
      print('CreatePDFScreen: Camera initialization failed: $e');
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
          _cameraInitStartTime = null;
        });
        _showTopNotification('Camera initialization failed: $e',
            color: Colors.red);
        // Fallback: allow user to force refresh if stuck
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && !_isCameraInitialized) {
            _forceRefreshCamera();
          }
        });
      }
    }
  }

  // Add a timer to check for camera init timeout and allow retry
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitializingCamera && _cameraInitStartTime != null) {
      Future.delayed(
          const Duration(milliseconds: 500), _checkCameraInitTimeout);
    }
  }

  void _checkCameraInitTimeout() {
    if (!_isInitializingCamera || _cameraInitStartTime == null) return;
    final elapsed = DateTime.now().difference(_cameraInitStartTime!);
    if (elapsed > _cameraInitTimeout) {
      if (mounted) {
        setState(() {
          _isInitializingCamera = false;
        });
        _showTopNotification('Camera initialization timed out. Tap retry.',
            color: Colors.red);
      }
    } else {
      // Keep checking until timeout or camera is ready
      if (mounted && _isInitializingCamera) {
        Future.delayed(
            const Duration(milliseconds: 500), _checkCameraInitTimeout);
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Camera Permission',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Camera permission is required to scan documents and capture images.',
          style: AppTextStyles.bodyMedium.copyWith(
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gray600,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            ),
            child: Text('Cancel',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text('Open Settings',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final scale = screenWidth / 375.0;
    return _buildMain(context, screenWidth, screenHeight, scale);
  }

  Widget _buildMain(BuildContext context, double screenWidth,
      double screenHeight, double scale) {
    if (_showPreview && _previewPDF != null) {
      return _buildPDFPreview(screenWidth, screenHeight, scale);
    }

    if (_showCamera) {
      return _buildKagazStyleCameraView(screenWidth, screenHeight, scale);
    }
    // return _buildPDFPreview();
    return _buildPDFSettingsView(screenWidth, screenHeight, scale);
  }

  Widget _buildKagazStyleCameraView(
      double screenWidth, double screenHeight, double scale) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Actual camera view - takes full screen height
          Positioned.fill(
            child: (_isCameraInitialized &&
                    _cameraService.controller != null &&
                    _cameraService.controller!.value.isInitialized)
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      try {
                        final cameraAspect =
                            _cameraService.controller!.value.aspectRatio;

                        if (_cameraFrame == CameraFramePreset.device) {
                          // Fill the available space using the device ratio to avoid letterboxing
                          return Positioned.fill(
                            child: CameraPreview(_cameraService.controller!),
                          );
                        }

                        final targetAspect = _cameraFrame.aspect;

                        double previewWidth = constraints.maxWidth;
                        double previewHeight = previewWidth / targetAspect;
                        if (previewHeight > constraints.maxHeight) {
                          previewHeight = constraints.maxHeight;
                          previewWidth = previewHeight * targetAspect;
                        }

                        return Center(
                          child: SizedBox(
                            width: previewWidth,
                            height: previewHeight,
                            child: CameraPreview(
                              _cameraService.controller!,
                            ),
                          ),
                        );
                      } catch (e) {
                        print('CameraPreview build error: $e');
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Text(
                              'Camera initializing... please wait',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16 * scale,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1a1a1a),
                          const Color(0xFF2d2d2d),
                          const Color(0xFF1a1a1a),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 24),
                          if (!_isInitializingCamera)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    print(
                                        'CreatePDFScreen: User requested camera retry');
                                    _forceRefreshCamera();
                                  },
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Retry Camera',
                                          style: TextStyle(
                                            color: Colors.white,
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
                    ),
                  ),
          ),

          // Top controls with improved design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Row(
                children: [
                  // Back button with improved design
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // HD/Normal toggle with improved design
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _setCameraQuality(false),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isHDMode
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                'Normal',
                                style: TextStyle(
                                  color:
                                      !_isHDMode ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _setCameraQuality(true),
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: _isHDMode
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                'HD',
                                style: TextStyle(
                                  color:
                                      _isHDMode ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls with improved design
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8 * scale,
                left: 0,
                right: 0,
                top: 0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Image preview strip with improved design
                  if (_selectedImages.isNotEmpty) ...[
                    Container(
                      height: 80 * scale,
                      margin: EdgeInsets.only(
                          bottom: 16 * scale,
                          left: 20 * scale,
                          right: 20 * scale),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: 12 * scale),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => _previewImage(index),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(12 * scale),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2 * scale,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8 * scale,
                                          offset: Offset(0, 4 * scale),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10 * scale),
                                      child: Stack(
                                        children: [
                                          Image.file(
                                            _selectedImages[index],
                                            width: 76 * scale,
                                            height: 76 * scale,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            bottom: 4 * scale,
                                            right: 4 * scale,
                                            child: Container(
                                              padding:
                                                  EdgeInsets.all(4 * scale),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6 * scale),
                                              ),
                                              child: Icon(
                                                Icons.visibility,
                                                size: 12 * scale,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6 * scale,
                                  left: 6 * scale,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6 * scale,
                                        vertical: 3 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius:
                                          BorderRadius.circular(8 * scale),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1 * scale,
                                      ),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6 * scale,
                                  right: 6 * scale,
                                  child: GestureDetector(
                                    onTap: () {
                                      _deleteImage(index);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 22 * scale,
                                      height: 22 * scale,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red.shade400,
                                            Colors.red.shade600,
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(11 * scale),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5 * scale,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 4 * scale,
                                            offset: Offset(0, 2 * scale),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 12 * scale,
                                        color: Colors.white,
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

                  // Bottom control buttons with improved design
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale, vertical: 12 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Upload PDF button
                        Flexible(
                          child: _buildBottomButton(
                            icon: Icons.picture_as_pdf,
                            label: 'PDF',
                            onTap: _pickPDF,
                            color: const Color(0xFFF59E0B),
                            scale: scale,
                          ),
                        ),

                        SizedBox(width: 4 * scale),

                        // Upload Image button
                        Flexible(
                          child: _buildBottomButton(
                            icon: Icons.photo_library,
                            label: 'Image',
                            onTap: _pickFromGallery,
                            color: const Color(0xFF10B981),
                            scale: scale,
                          ),
                        ),

                        SizedBox(width: 4 * scale),

                        // Capture button (center) - larger and more prominent
                        GestureDetector(
                          onTap: (_isCapturing ||
                                  !_isCameraInitialized ||
                                  _isInitializingCamera ||
                                  _cameraService.controller == null ||
                                  !_cameraService.isInitialized)
                              ? null
                              : _captureImage,
                          child: Container(
                            width: 88 * scale,
                            height: 88 * scale,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.grey.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(44 * scale),
                              border: Border.all(
                                color: Colors.white,
                                width: 4 * scale,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 15 * scale,
                                  offset: Offset(0, 6 * scale),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 8 * scale,
                                  offset: Offset(0, -2 * scale),
                                ),
                              ],
                            ),
                            child: _isCapturing
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                    strokeWidth: 3 * scale,
                                  )
                                : Opacity(
                                    opacity: (_isCameraInitialized &&
                                            !_isInitializingCamera &&
                                            _cameraService.controller != null &&
                                            _cameraService.isInitialized)
                                        ? 1.0
                                        : 0.4,
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.black,
                                      size: 36 * scale,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(width: 4 * scale),

                        // Torch button
                        Flexible(
                          child: _buildBottomButton(
                            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            label: 'Torch',
                            onTap: _toggleFlash,
                            color: Colors.white,
                            scale: scale,
                          ),
                        ),

                        SizedBox(width: 4 * scale),

                        // Done button (when images are selected) or placeholder
                        if (_selectedImages.isNotEmpty)
                          Flexible(
                            child: _buildBottomButton(
                              icon: Icons.check_circle,
                              label: 'Done',
                              onTap: () => setState(() => _showCamera = false),
                              color: const Color(0xFF3B82F6),
                              scale: scale,
                            ),
                          )
                        else
                          SizedBox(
                              width: 50 * scale), // Placeholder for spacing
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay for PDF processing with improved design
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Processing PDF...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we create your document',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    double scale = 1.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56 * scale,
            height: 56 * scale,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1.5 * scale,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 4 * scale,
                  offset: Offset(0, -2 * scale),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 26 * scale,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFSettingsView(
      double screenWidth, double screenHeight, double scale) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8 * scale),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 20 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              '',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20 * scale,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20 * scale),
          onPressed: _returnToCamera,
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16 * scale),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(25 * scale),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _generatePDF,
                borderRadius: BorderRadius.circular(25 * scale),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20 * scale, vertical: 10 * scale),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 20 * scale,
                      ),
                      SizedBox(width: 8 * scale),
                      Text(
                        'Generate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * scale,
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
          Column(
            children: [
              // Enhanced Selected images count section
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(8 * scale),
                padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale, vertical: 16 * scale),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25 * scale,
                      offset: Offset(0, 8 * scale),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10 * scale,
                      offset: Offset(0, 2 * scale),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1 * scale,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale, vertical: 8 * scale),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 10 * scale,
                              offset: Offset(0, 4 * scale),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(4 * scale),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6 * scale),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 16 * scale,
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            Flexible(
                              child: Text(
                                '${_selectedImages.length} page${_selectedImages.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14 * scale,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Container(
                      constraints: BoxConstraints(maxWidth: 140 * scale),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.1),
                            Colors.green.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25 * scale),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1 * scale,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _returnToCamera,
                          borderRadius: BorderRadius.circular(25 * scale),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8 * scale, vertical: 8 * scale),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: Colors.green.shade600,
                                  size: 18 * scale,
                                ),
                                SizedBox(width: 6 * scale),
                                Flexible(
                                  child: Text(
                                    'Add More',
                                    style: TextStyle(
                                      color: Colors.green.shade600,
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
                    ),
                  ],
                ),
              ),

              // Enhanced Images section with reordering
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced header with reorder button
                      Container(
                        padding: EdgeInsets.all(16 * scale),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16 * scale),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1 * scale,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8 * scale),
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
                                borderRadius: BorderRadius.circular(8 * scale),
                              ),
                              child: Icon(
                                Icons.photo_library,
                                color: Theme.of(context).primaryColor,
                                size: 20 * scale,
                              ),
                            ),
                            SizedBox(width: 12 * scale),
                            Flexible(
                              child: Text(
                                'Selected Images',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18 * scale,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Spacer(),
                            Container(
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
                                borderRadius: BorderRadius.circular(20 * scale),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  width: 1 * scale,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _toggleReorderMode,
                                  borderRadius:
                                      BorderRadius.circular(20 * scale),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12 * scale,
                                        vertical: 8 * scale),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isReorderMode
                                              ? Icons.check
                                              : Icons.swap_vert,
                                          size: 16 * scale,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        SizedBox(width: 4 * scale),
                                        Text(
                                          _isReorderMode ? 'Done' : 'Reorder',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12 * scale,
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
                      ),
                      SizedBox(height: 16 * scale),

                      // Enhanced reorderable grid
                      Expanded(
                        child: _isReorderMode
                            ? _buildReorderableGrid(
                                screenWidth, screenHeight, scale)
                            : _buildStaticGrid(
                                screenWidth, screenHeight, scale),
                      ),
                    ],
                  ),
                ),
              ),

              // Enhanced Settings section
              Container(
                margin: EdgeInsets.all(15 * scale),
                padding: EdgeInsets.all(15 * scale),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF8FAFC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 25 * scale,
                      offset: Offset(0, -8 * scale),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10 * scale,
                      offset: Offset(0, -2 * scale),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1 * scale,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8 * scale),
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
                              borderRadius: BorderRadius.circular(8 * scale),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Theme.of(context).primaryColor,
                              size: 20 * scale,
                            ),
                          ),
                          SizedBox(width: 12 * scale),
                          Text(
                            'PDF Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18 * scale,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24 * scale),

                      // Enhanced PDF Title field
                      TextField(
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'PDF Title',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: 'Enter PDF title...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16 * scale,
                          ),
                          prefixIcon: Container(
                            margin: EdgeInsets.all(8 * scale),
                            padding: EdgeInsets.all(8 * scale),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8 * scale),
                            ),
                            child: Icon(
                              Icons.title,
                              color: Theme.of(context).primaryColor,
                              size: 20 * scale,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16 * scale),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16 * scale),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16 * scale),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2 * scale,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 16 * scale,
                          ),
                        ),
                        onChanged: (value) => _pdfTitle = value,
                        controller: TextEditingController(text: _pdfTitle),
                      ),
                      SizedBox(height: 10 * scale),

                      // Enhanced Page Size and Fit to Page
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 400) {
                            // Stack vertically on small screens
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DropdownButtonFormField<PageSize>(
                                  value: _selectedPageSize,
                                  style: TextStyle(
                                    color: Color(0xFF1E293B),
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  dropdownColor: Colors.white,
                                  decoration: InputDecoration(
                                    labelText: 'Page Size',
                                    labelStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Container(
                                      margin: EdgeInsets.all(6 * scale),
                                      padding: EdgeInsets.all(6 * scale),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8 * scale),
                                      ),
                                      child: Icon(
                                        Icons.aspect_ratio,
                                        color: Theme.of(context).primaryColor,
                                        size: 16 * scale,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(16 * scale),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(16 * scale),
                                      borderSide: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(16 * scale),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 2 * scale,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 6 * scale,
                                      vertical: 8 * scale,
                                    ),
                                  ),
                                  items: PageSize.values.map((size) {
                                    return DropdownMenuItem(
                                      value: size,
                                      child: Text(
                                        size.name.toUpperCase(),
                                        style: TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14 * scale,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPageSize = value!;
                                    });
                                  },
                                ),
                                SizedBox(height: 8 * scale),
                                Container(
                                  padding: EdgeInsets.all(4 * scale),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(16 * scale),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: SwitchListTile(
                                    title: Text(
                                      'Fit to Page',
                                      style: TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14 * scale,
                                      ),
                                    ),
                                    value: _fitToPage,
                                    onChanged: (value) {
                                      setState(() {
                                        _fitToPage = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Use a row on larger screens
                            return Row(
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: DropdownButtonFormField<PageSize>(
                                    value: _selectedPageSize,
                                    style: TextStyle(
                                      color: Color(0xFF1E293B),
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    dropdownColor: Colors.white,
                                    decoration: InputDecoration(
                                      labelText: 'Page Size',
                                      labelStyle: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Container(
                                        margin: EdgeInsets.all(6 * scale),
                                        padding: EdgeInsets.all(6 * scale),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8 * scale),
                                        ),
                                        child: Icon(
                                          Icons.aspect_ratio,
                                          color: Theme.of(context).primaryColor,
                                          size: 16 * scale,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16 * scale),
                                        borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16 * scale),
                                        borderSide: BorderSide(
                                          color: Colors.grey.withOpacity(0.3),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16 * scale),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).primaryColor,
                                          width: 2 * scale,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 6 * scale,
                                        vertical: 8 * scale,
                                      ),
                                    ),
                                    items: PageSize.values.map((size) {
                                      return DropdownMenuItem(
                                        value: size,
                                        child: Text(
                                          size.name.toUpperCase(),
                                          style: TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14 * scale,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPageSize = value!;
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 6 * scale),
                                Flexible(
                                  flex: 1,
                                  child: Container(
                                    padding: EdgeInsets.all(4 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(16 * scale),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: SwitchListTile(
                                      title: Text(
                                        'Fit to Page',
                                        style: TextStyle(
                                          color: Color(0xFF1E293B),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14 * scale,
                                        ),
                                      ),
                                      value: _fitToPage,
                                      onChanged: (value) {
                                        setState(() {
                                          _fitToPage = value;
                                        });
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      activeColor:
                                          Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Enhanced Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: CircularProgressIndicator(
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Generating PDF...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait while we create your document',
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
    );
  }

  Widget _buildImageCard(File image, int index, double scale) {
    return Container(
      key: ValueKey(image.path),
      width: 110,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image with improved border
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                image,
                width: 110,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Page number with improved design
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          // Action buttons with improved design
          Positioned(
            bottom: 10,
            right: 10,
            child: Column(
              children: [
                // Edit button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _editImage(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Delete button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _deleteImage(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
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

  Widget _buildPDFPreview(
      double screenWidth, double screenHeight, double scale) {
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
              _showPreview = false;
              _previewPDF = null;
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

              // Flexible spacing - only takes available space
              // Expanded(
              //   child: Column(
              //     children: [
              //       const Spacer(),
              //       // Native Ad
              //       const Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //         child: BannerAdWidget(),
              //       ),
              //     ],
              //   ),
              // ),
              // Compact Action Buttons
              SafeArea(
                child: Container(
                  margin: EdgeInsets.all(16 * scale),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Primary Action - Save & Share
                      // Container(
                      //   width: double.infinity,
                      //   decoration: BoxDecoration(
                      //     gradient: LinearGradient(
                      //       colors: [
                      //         Theme.of(context).primaryColor,
                      //         Theme.of(context).primaryColor.withOpacity(0.8),
                      //       ],
                      //     ),
                      //     borderRadius: BorderRadius.circular(25 * scale),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Theme.of(context)
                      //             .primaryColor
                      //             .withOpacity(0.3),
                      //         blurRadius: 12 * scale,
                      //         offset: Offset(0, 6 * scale),
                      //       ),
                      //     ],
                      //   ),
                      //   child: Material(
                      //     color: Colors.transparent,
                      //     child: InkWell(
                      //       onTap: _saveAndSharePDF,
                      //       borderRadius: BorderRadius.circular(25 * scale),
                      //       child: Container(
                      //         padding:
                      //             EdgeInsets.symmetric(vertical: 16 * scale),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             Icon(
                      //               Icons.save_alt,
                      //               color: Colors.white,
                      //               size: 22 * scale,
                      //             ),
                      //             SizedBox(width: 10 * scale),
                      //             Text(
                      //               'Save & Share PDF',
                      //               style: TextStyle(
                      //                 color: Colors.white,
                      //                 fontWeight: FontWeight.w700,
                      //                 fontSize: 16 * scale,
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(height: 12 * scale),
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
                                  _showPreview = false;
                                  _previewPDF = null;
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
              if (_isLoading)
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

  Widget _buildCompactDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showTopNotification(String message, {Color color = Colors.green}) {
    setState(() {
      _topNotification = {'message': message, 'color': color};
    });

    // Auto-dismiss after a short delay to keep UI clean
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_topNotification != null && _topNotification!['message'] == message) {
        setState(() => _topNotification = null);
      }
    });
  }

  Widget _buildTopNotification({required double scale}) {
    if (_topNotification == null) return const SizedBox.shrink();
    final Color color = (_topNotification!['color'] as Color?) ?? Colors.blue;
    final String message = (_topNotification!['message'] as String?) ?? '';

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 14 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8 * scale,
            offset: Offset(0, 4 * scale),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: Colors.white, size: 18 * scale),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    if (_cameraService.controller == null || !_cameraService.isInitialized) {
      print('CreatePDFScreen: Camera not ready for flash toggle');
      _showErrorSnackBar('Camera not ready for flash toggle');
      return;
    }

    try {
      print(
          'CreatePDFScreen: Toggling flash from $_isFlashOn to ${!_isFlashOn}');
      _isFlashOn = !_isFlashOn;

      await _cameraService.controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );

      setState(() {});
      print('CreatePDFScreen: Flash toggled successfully');
    } catch (e) {
      print('CreatePDFScreen: Failed to toggle flash: $e');
      // Revert the state if toggle failed
      _isFlashOn = !_isFlashOn;
      setState(() {});
      _showErrorSnackBar('Failed to toggle flash: $e');
    }
  }

  Future<void> _pickPDF() async {
    _isPickingFile = true;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        print('Selected ${result.files.length} PDF files');
        setState(() => _isLoading = true);

        try {
          final pdfService = PDFService();
          int totalPagesExtracted = 0;
          int filesProcessed = 0;

          for (final file in result.files) {
            if (file.path != null) {
              print('Processing PDF file: ${file.name}');
              final pdfFile = File(file.path!);

              // Extract images from PDF
              final extractedImages = await pdfService.extractImagesFromPDF(
                pdfFile: pdfFile,
                scale: _isHDMode ? 3.0 : 2.0,
              );

              print(
                  'Extracted ${extractedImages.length} pages from ${file.name}');

              if (extractedImages.isNotEmpty) {
                setState(() {
                  _selectedImages.addAll(extractedImages);
                });
                totalPagesExtracted += extractedImages.length;
                filesProcessed++;
              }
            }
          }

          print(
              'Total pages extracted: $totalPagesExtracted from $filesProcessed files');
          print('Total images in list: ${_selectedImages.length}');

          if (totalPagesExtracted > 0) {
            final fileText = filesProcessed == 1 ? 'file' : 'files';
            final pageText = totalPagesExtracted == 1 ? 'page' : 'pages';
            _showTopNotification(
                'PDF import successful! Extracted $totalPagesExtracted $pageText from $filesProcessed $fileText.',
                color: Colors.green);
          } else {
            _showTopNotification(
                'No pages could be extracted from the PDF files',
                color: Colors.red);
          }
        } catch (e) {
          print('Error processing PDF: $e');
          _showTopNotification('Failed to process PDF: $e', color: Colors.red);
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error picking PDF: $e');
      _showTopNotification('Failed to pick PDF: $e', color: Colors.red);
      setState(() => _isLoading = false);
    } finally {
      _isPickingFile = false;
      // Always reinitialize camera after file picking
      _reinitializeCameraAfterFileOperation();
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    if (!_isCameraInitialized ||
        _cameraService.controller == null ||
        !_cameraService.isInitialized) {
      print('CreatePDFScreen: Camera not ready for capture');
      _showTopNotification('Camera not ready. Please wait.',
          color: Colors.orange);
      return;
    }
    
    // Set capturing state immediately for instant UI feedback
    if (mounted) {
      setState(() {
        _isCapturing = true;
      });
    }
    
    try {
      print('CreatePDFScreen: Attempting to capture image...');
      // Use compute or background isolate for faster capture
      final imageFile = await _cameraService.takePicture();

      if (imageFile != null) {
        print(
            'CreatePDFScreen: Image captured successfully: ${imageFile.path}');

        // Calculate aspect ratio based on the current camera frame preset
        final aspectRatio =
            _cameraFrame.aspect > 0 ? _cameraFrame.aspect : null;

        // Reset capturing state before navigation for smoother UX
        if (mounted) {
          setState(() {
            _isCapturing = false;
          });
        }
        
        // Navigate to crop screen with the camera frame preset
        if (mounted) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CropScreen(
                imagePath: imageFile.path,
                title: 'Crop Document',
                cameraFramePreset: _cameraFrame,
                imageAspectRatio: aspectRatio,
              ),
            ),
          );

          // Handle the result from crop screen
          if (result != null &&
              result['cropped'] == true &&
              result['path'] != null) {
            if (mounted) {
              final croppedFile = File(result['path']);
              setState(() {
                _selectedImages.add(croppedFile);
                // Store the aspect ratio for this image
                if (aspectRatio != null) {
                  _imageAspectRatios[croppedFile.path] = aspectRatio;
                }
              });
              _showTopNotification('Page ${_selectedImages.length} added',
                  color: Colors.green);
            }
          } else {
            if (mounted) {
              _showTopNotification('Image capture cancelled',
                  color: Colors.orange);
            }
          }
        }
      } else {
        print('CreatePDFScreen: Failed to capture image - no file returned');
        if (mounted) {
          _showTopNotification('Failed to capture image. Try again.',
              color: Colors.red);
        }
      }
    } catch (e) {
      print('CreatePDFScreen: Error capturing image: $e');
      if (mounted) {
        _showTopNotification('Capture failed. Try again.', color: Colors.red);
        // Only reset if we haven't navigated yet
        if (_isCapturing) {
          setState(() {
            _isCapturing = false;
          });
        }
      }
    }
  }

  Future<void> _pickFromGallery() async {
    _isPickingFile = true;
    try {
      // Optimize image quality - 85 is good balance between quality and size
      final List<XFile> picked = await _picker.pickMultiImage(
        imageQuality: _isHDMode ? 95 : 85,
      );

      if (picked.isNotEmpty) {
        // Navigate to crop screen for the first image
        final firstImage = File(picked.first.path);

        // Navigate to crop screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CropScreen(
              imagePath: firstImage.path,
              title: 'Crop Document',
            ),
          ),
        );

        // Handle the result from crop screen
        if (result != null &&
            result['cropped'] == true &&
            result['path'] != null) {
          setState(() {
            _selectedImages.add(File(result['path']));
          });
          _showTopNotification('Page ${_selectedImages.length} added',
              color: Colors.green);
        } else {
          _showTopNotification('Image processing cancelled',
              color: Colors.orange);
        }
      }
    } catch (e) {
      _showTopNotification('Failed to pick images: $e', color: Colors.red);
    } finally {
      _isPickingFile = false;
      // Always reinitialize camera after file picking
      _reinitializeCameraAfterFileOperation();
    }
  }

  // Optimized method to handle camera reinitialization after file operations
  Future<void> _reinitializeCameraAfterFileOperation() async {
    print('CreatePDFScreen: Reinitializing camera after file operation...');

    // Reset camera state to ensure clean reinitialization
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
        _isInitializingCamera = false;
      });
    }

    // Reduced delay for faster response
    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      print('CreatePDFScreen: Starting camera reinitialization...');
      _initializeCamera();
    }
  }

  void _reorderImages() {
    _toggleReorderMode();
  }

  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
    });
  }

  Widget _buildReorderableGrid(
      double screenWidth, double screenHeight, double scale) {
    return ReorderableWrap(
      spacing: 12,
      runSpacing: 12,
      children: _selectedImages.asMap().entries.map((entry) {
        final index = entry.key;
        final image = entry.value;
        return _buildReorderableImageCard(
            image, index, screenWidth, screenHeight, scale);
      }).toList(),
      onReorder: (oldIndex, newIndex) {
        setState(() {
          // When moving an item down the list, the reported newIndex
          // refers to the position after removal — adjust to correct index.
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final item = _selectedImages.removeAt(oldIndex);
          _selectedImages.insert(newIndex, item);
        });
      },
    );
  }

  Widget _buildStaticGrid(
      double screenWidth, double screenHeight, double scale) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return _buildImageCard(_selectedImages[index], index, scale);
      },
    );
  }

  Widget _buildReorderableImageCard(File image, int index, double screenWidth,
      double screenHeight, double scale) {
    return Container(
      key: ValueKey(image.path),
      width: 110,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image with enhanced border
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                image,
                width: 110,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Enhanced page number with drag indicator
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _removeImage(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _editImage(int index) {
    final currentImage = _selectedImages[index];
    final storedAspectRatio = _imageAspectRatios[currentImage.path];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          imageFile: currentImage,
          title: 'Edit Page ${index + 1}',
          isFromCreatePdf: true,
          initialAspectRatio: storedAspectRatio,
        ),
      ),
    ).then((editedFile) {
      if (editedFile != null) {
        setState(() {
          // Transfer aspect ratio to new edited file
          if (storedAspectRatio != null) {
            _imageAspectRatios.remove(currentImage.path);
            _imageAspectRatios[editedFile.path] = storedAspectRatio;
          }
          _selectedImages[index] = editedFile;
        });
      }

      // Reinitialize camera if we're in camera view and camera is not ready
      if (_showCamera && !_isCameraInitialized && !_isInitializingCamera) {
        print(
            'CreatePDFScreen: Returning from image edit, reinitializing camera...');
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _initializeCamera();
          }
        });
      }
    });
  }

  void _deleteImage(int index) {
    print(
        'CreatePDFScreen: Deleting image at index: $index, total images: ${_selectedImages.length}');

    if (index < 0 || index >= _selectedImages.length) {
      print('CreatePDFScreen: Invalid index for deletion: $index');
      return;
    }

    setState(() {
      final deletedImage = _selectedImages.removeAt(index);
      print(
          'CreatePDFScreen: Successfully deleted image: ${deletedImage.path}');
      print('CreatePDFScreen: Remaining images: ${_selectedImages.length}');
    });

    // Show feedback to user
    _showTopNotification('Page ${index + 1} removed', color: Colors.orange);
  }

  void _showPDFSettings() {
    // Open dedicated PDF settings screen so user can adjust page size,
    // fit, margin, page numbers and watermark. Preserve camera state.
    print('CreatePDFScreen: Opening PDF settings screen...');
    // Keep camera alive; push settings screen and wait for result
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PdfSettingsScreen(
          initialPageSize: _selectedPageSize,
          initialFitToPage: _fitToPage,
          initialMargin: _margin,
          initialAddPageNumbers: _addPageNumbers,
          initialWatermark: _watermarkText,
          initialCameraFrame: _cameraFrame,
        ),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _selectedPageSize =
              result['pageSize'] as PageSize? ?? _selectedPageSize;
          _fitToPage = result['fitToPage'] as bool? ?? _fitToPage;
          _margin = result['margin'] as double? ?? _margin;
          _addPageNumbers =
              result['addPageNumbers'] as bool? ?? _addPageNumbers;
          _watermarkText = result['watermarkText'] as String? ?? _watermarkText;
          _cameraFrame =
              result['cameraFrame'] as CameraFramePreset? ?? _cameraFrame;
        });
      }
    });
  }

  // Method to handle returning to camera view
  void _returnToCamera() {
    print('CreatePDFScreen: Returning to camera view...');
    setState(() {
      _showCamera = true;
    });

    // Reinitialize camera if it's not ready
    if (!_isCameraInitialized && !_isInitializingCamera) {
      print('CreatePDFScreen: Camera not ready, reinitializing...');
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _initializeCamera();
        }
      });
    }
  }

  // Force refresh camera - useful when camera gets stuck
  Future<void> _forceRefreshCamera() async {
    print('CreatePDFScreen: Force refreshing camera...');

    // Prevent multiple simultaneous refreshes
    if (_isInitializingCamera) {
      print(
          'CreatePDFScreen: Camera already initializing, skipping force refresh');
      return;
    }

    await _disposeCamera();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _initializeCamera();
    }
  }

  Future<void> _startPdfGeneration() async {
    try {
      print('CreatePDFScreen: Starting PDF generation...');
      print('CreatePDFScreen: Images count: ${_selectedImages.length}');
      print('CreatePDFScreen: Title: $_pdfTitle');
      print('CreatePDFScreen: Page size: $_selectedPageSize');
      print('CreatePDFScreen: Fit to page: $_fitToPage');

      final stopwatch = Stopwatch()..start();

      File? pdfFile;
      try {
        final pdfService = PDFService();
        
        // Use lower quality for faster generation with many images
        final imageQuality = _selectedImages.length > 10 ? 75 : 82;
        final maxDimension = _selectedImages.length > 10 ? 1800 : 2000;
        
        print('CreatePDFScreen: Using imageQuality=$imageQuality, maxDimension=$maxDimension');
        
        pdfFile = await pdfService.createAdvancedPDF(
          imageFiles: _selectedImages,
          title: _pdfTitle,
          pageSize: _selectedPageSize,
          fitToPage: _fitToPage,
          margin: _margin,
          addPageNumbers: _addPageNumbers,
          watermarkText: _watermarkText.isEmpty ? null : _watermarkText,
          author: 'Document Scanner App',
          subject: 'Scanned Document',
          imageQuality: imageQuality,
          maxImageDimension: maxDimension,
        );
      } catch (e) {
        print('CreatePDFScreen: Advanced PDF failed: $e');
        pdfFile = null;
      }

      if (pdfFile == null) {
        print('CreatePDFScreen: Using simple PDF generation fallback...');
        final pdfService = PDFService();
        pdfFile = await pdfService.createSimplePDF(
          imageFiles: _selectedImages,
          title: _pdfTitle,
        );
      }

      stopwatch.stop();
      print('CreatePDFScreen: PDF generation took ${stopwatch.elapsedMilliseconds}ms');

      if (pdfFile != null) {
        if (!await pdfFile.exists()) {
          throw Exception('Generated PDF file does not exist');
        }

        final fileSize = await pdfFile.length();
        if (fileSize == 0) {
          throw Exception('Generated PDF file is empty');
        }

        print('CreatePDFScreen: PDF generated successfully: \x1B[32m${pdfFile.path}\x1B[0m');
        print('CreatePDFScreen: PDF file size: ${fileSize} bytes');

        if (mounted) {
          setState(() {
            _isLoading = false;
            _previewPDF = pdfFile;
            _showPreview = true;
          });
        }
      } else {
        print('CreatePDFScreen: PDF generation failed - null file returned');
        if (mounted) {
          _showErrorSnackBar('Failed to create PDF. Please try again.');
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('CreatePDFScreen: Error creating PDF: $e');
      String errorMessage = 'Error creating PDF';

      if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied. Please check app permissions.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Storage error. Please check available space.';
      } else if (e.toString().contains('image')) {
        errorMessage = 'Image processing error. Please check your images.';
      } else {
        errorMessage = 'Error creating PDF: ${e.toString().split(':').last.trim()}';
      }

      if (mounted) {
        _showErrorSnackBar(errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generatePDF() async {
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('No images selected');
      return;
    }

    if (_pdfTitle.trim().isEmpty) {
      _showErrorSnackBar('Please enter a PDF title');
      return;
    }

    // Quick validation without blocking
    final validationResults = await Future.wait(
      _selectedImages.map((img) => img.exists()),
    );

    for (int i = 0; i < validationResults.length; i++) {
      if (!validationResults[i]) {
        _showErrorSnackBar(
            'Image ${i + 1} not found. Please remove and re-add it.');
        return;
      }
    }

    if (mounted) setState(() => _isLoading = true);

    // Start PDF generation immediately in background
    _startPdfGeneration();

    // Show ad without blocking PDF generation
    InterstitialAdHelper.showInterstitialAd(
      onAdClosed: () {
        print('CreatePDFScreen: Interstitial ad closed');
      },
    );
  }

  Future<void> _saveAndSharePDF() async {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to save and share');
      return;
    }

    print('CreatePDFScreen: Starting PDF save and share...');
    setState(() => _isLoading = true);

    try {
      // First, save to local storage
      print('CreatePDFScreen: Saving PDF to local storage...');
      final fileService = FileManagementService();
      final savedDocument = await fileService.savePDFDocument(
        name: _pdfTitle,
        pdfPath: _previewPDF!.path,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (savedDocument != null) {
        print('CreatePDFScreen: PDF saved successfully to local storage');
        print('CreatePDFScreen: Document ID: ${savedDocument.id}');

        // Show success message
        _showSuccessSnackBar('PDF saved to Documents!');

        // Small delay to show the success message
        await Future.delayed(const Duration(milliseconds: 500));

        // Then share the PDF
        print('CreatePDFScreen: Sharing PDF...');
        await Share.shareXFiles(
          [XFile(_previewPDF!.path)],
          text: 'PDF created with Document Scanner',
          subject: _pdfTitle,
        );

        print('CreatePDFScreen: PDF shared successfully');

        // Show final success message
        _showSuccessSnackBar('PDF saved and shared successfully!');

        // Navigate back to home after a delay
        await Future.delayed(const Duration(milliseconds: 1000));

        print('CreatePDFScreen: Disposing camera and navigating back...');
        // Ensure camera is disposed before navigation
        await _disposeCamera();

        // Mark that camera reset is needed after PDF export
        markCameraResetNeeded();

        print('CreatePDFScreen: Navigating back to home...');
        // Navigate back to home
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        print('CreatePDFScreen: Failed to save PDF to local storage');
        _showErrorSnackBar('Failed to save PDF to local storage');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('CreatePDFScreen: Error in save and share: $e');
      _showErrorSnackBar('Error saving PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  // New method to save PDF without sharing
  Future<void> _savePDFOnly() async {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to save');
      return;
    }

    print('CreatePDFScreen: Saving PDF only...');
    setState(() => _isLoading = true);

    try {
      final fileService = FileManagementService();
      final savedDocument = await fileService.savePDFDocument(
        name: _pdfTitle,
        pdfPath: _previewPDF!.path,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (savedDocument != null) {
        print('CreatePDFScreen: PDF saved successfully');
        _showSuccessSnackBar('PDF saved to Documents successfully!');
        await NotificationService().showNotification(
          title: 'File Saved',
          body: 'Your PDF has been saved successfully!',
        );
      } else {
        print('CreatePDFScreen: Failed to save PDF');
        _showErrorSnackBar('Failed to save PDF');
      }
    } catch (e) {
      print('CreatePDFScreen: Error saving PDF: $e');
      _showErrorSnackBar('Error saving PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // New method to share PDF without saving
  Future<void> _sharePDFOnly() async {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to share');
      return;
    }

    print('CreatePDFScreen: Sharing PDF only...');

    try {
      await Share.shareXFiles(
        [XFile(_previewPDF!.path)],
        text: 'PDF created with Document Scanner',
        subject: _pdfTitle,
      );

      print('CreatePDFScreen: PDF shared successfully');
      if (mounted) {
        _showSuccessSnackBar('PDF shared successfully!');
      }
    } catch (e) {
      print('CreatePDFScreen: Error sharing PDF: $e');
      if (mounted) {
        _showErrorSnackBar('Error sharing PDF: $e');
      }
    }
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

  void _setCameraQuality(bool isHDMode) async {
    if (_isHDMode == isHDMode) return;

    // final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    // if (isHDMode && !sub.isSubscribed) {
    //  if (isHDMode) {
    //   // Prompt user to subscribe to enable HD
    //   showDialog(
    //     context: context,
    //     builder: (ctx) => AlertDialog(
    //       title: const Text('Premium feature'),
    //       content: const Text('HD mode is available for subscribed users only.'),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(ctx).pop(),
    //           child: const Text('Cancel'),
    //         ),
    //         ElevatedButton(
    //           onPressed: () {
    //             Navigator.of(ctx).pop();
    //             // Navigator.of(context).pushNamed('/subscription'); // Temporarily disabled
    //           },
    //           child: const Text('Close'), // Changed from 'Subscribe'
    //         ),
    //       ],
    //     ),
    //   );
    //   return;
    // }

    print(
        'CreatePDFScreen: Changing camera quality to ${isHDMode ? "HD" : "Normal"}');

    setState(() {
      _isHDMode = isHDMode;
    });

    // Only reinitialize if camera is currently working
    if (_isCameraInitialized && !_isInitializingCamera) {
      print('CreatePDFScreen: Reinitializing camera with new quality...');
      await _disposeCamera();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _initializeCamera();
      }
    }
  }

  void _previewImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildImagePreviewScreen(index),
      ),
    ).then((_) {
      // Reinitialize camera if we're in camera view and camera is not ready
      if (_showCamera && !_isCameraInitialized && !_isInitializingCamera) {
        print(
            'CreatePDFScreen: Returning from image preview, reinitializing camera...');
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _initializeCamera();
          }
        });
      }
    });
  }

  Widget _buildImagePreviewScreen(int index) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Page ${index + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pop(context);
              _editImage(index);
            },
            tooltip: 'Edit Image',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareImage(index),
            tooltip: 'Share Image',
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.file(
            _selectedImages[index],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Previous button
            IconButton(
              onPressed: index > 0
                  ? () {
                      Navigator.pop(context);
                      _previewImage(index - 1);
                    }
                  : null,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              tooltip: 'Previous Page',
            ),

            // Page indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1} of ${_selectedImages.length}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),

            // Next button
            IconButton(
              onPressed: index < _selectedImages.length - 1
                  ? () {
                      Navigator.pop(context);
                      _previewImage(index + 1);
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              tooltip: 'Next Page',
            ),
          ],
        ),
      ),
    );
  }

  void _shareImage(int index) {
    try {
      Share.shareXFiles(
        [XFile(_selectedImages[index].path)],
        text: 'Page ${index + 1} from Document Scanner',
        subject: 'Document Page',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share image: $e');
    }
  }

  // Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Helper method to get PDF file size
  Future<String> _getPDFFileSize() async {
    if (_previewPDF == null) return 'Unknown';
    try {
      final size = await _previewPDF!.length();
      return _formatFileSize(size);
    } catch (e) {
      return 'Unknown';
    }
  }

  // Helper method to sanitize filename
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show more options menu
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
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'More Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            _buildOptionTile(
              icon: Icons.download,
              title: 'Download PDF',
              subtitle: 'Save to Downloads folder',
              onTap: _downloadPDF,
            ),
            _buildOptionTile(
              icon: Icons.email,
              title: 'Send via Email',
              subtitle: 'Open email app with PDF attached',
              onTap: _sendViaEmail,
            ),
            _buildOptionTile(
              icon: Icons.cloud_upload,
              title: 'Upload to Cloud',
              subtitle: 'Save to Google Drive, Dropbox, etc.',
              onTap: _uploadToCloud,
            ),
            _buildOptionTile(
              icon: Icons.qr_code,
              title: 'Generate QR Code',
              subtitle: 'Create QR code for sharing',
              onTap: _generateQRCode,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }

  // Build secondary action button
  Widget _buildSecondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required double scale,
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

  // Print PDF functionality
  Future<void> _printPDF() async {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to print');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pdfService = PDFService();
      final success = await pdfService.printPDF(_previewPDF!);

      if (success) {
        _showSuccessSnackBar('Print request sent successfully!');
      } else {
        _showErrorSnackBar('Failed to send print request');
      }
    } catch (e) {
      _showErrorSnackBar('Error printing PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Download PDF functionality
  Future<void> _downloadPDF() async {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to download');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // For now, just save to documents and show success
      final fileService = FileManagementService();
      final savedDocument = await fileService.savePDFDocument(
        name: _pdfTitle,
        pdfPath: _previewPDF!.path,
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (savedDocument != null) {
        _showSuccessSnackBar('PDF downloaded to Documents!');
      } else {
        _showErrorSnackBar('Failed to download PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Error downloading PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Send via email functionality
  Future<void> _sendViaEmail() async {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to send');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(_previewPDF!.path)],
        text: 'PDF created with Document Scanner',
        subject: _pdfTitle,
      );
      _showSuccessSnackBar('Email app opened with PDF attached!');
    } catch (e) {
      _showErrorSnackBar('Error opening email app: $e');
    }
  }

  // Upload to cloud functionality
  Future<void> _uploadToCloud() async {
    _showErrorSnackBar('Cloud upload feature coming soon!');
  }

  // Generate QR code functionality
  Future<void> _generateQRCode() async {
    _showErrorSnackBar('QR code generation feature coming soon!');
  }

  // View PDF functionality
  void _viewPDF() {
    if (_previewPDF == null) {
      _showErrorSnackBar('No PDF to view');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          pdfFile: _previewPDF!,
          title: _pdfTitle,
          pageCount: _selectedImages.length,
        ),
      ),
    );
  }

  Future<void> _showPostSaveOptions(BuildContext context, File file) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Save to Downloads'),
              onTap: () async {
                Navigator.pop(ctx);
                final fileService = FileManagementService();
                final result = await fileService.saveToDownloads(file);
                _showSuccessSnackBar(result
                    ? 'Saved to Downloads!'
                    : 'Failed to save to Downloads');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Recent Downloads'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/recent_downloads');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostSaveDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Saved'),
        content: const Text('Your file has been saved successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
