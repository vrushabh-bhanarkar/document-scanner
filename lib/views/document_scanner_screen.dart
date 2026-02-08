import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/themes.dart';
import '../services/document_scanner_service.dart';
import '../main.dart' as main;
import 'scan_preview_screen.dart';

enum ScanMode {
  document,
  idCard,
  receipt,
  businessCard,
}

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({Key? key}) : super(key: key);

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  final DocumentScannerService _scannerService = DocumentScannerService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _flashEnabled = false;
  bool _autoCapture = false;
  bool _isStreamingImages = false;
  bool _isDetectionEnabled = false;
  ScanMode _selectedMode = ScanMode.document;

  List<Offset> _detectedCorners = [];
  bool _isDocumentDetected = false;
  double _documentQuality = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDialog();
        return;
      }

      if (main.cameras.isEmpty) {
        _showErrorDialog('No camera found on device');
        return;
      }

      // Initialize camera with back camera
      _cameraController = CameraController(
        main.cameras.first,
        ResolutionPreset.high, // Use high resolution for better edge detection
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isDetectionEnabled = true; // Enable detection by default
        });
        // Start edge detection automatically
        _startImageStream();
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorDialog('Failed to initialize camera: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null || _isStreamingImages) return;

    _isStreamingImages = true;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isProcessing || !_isDetectionEnabled) return;

      _isProcessing = true;

      try {
        // Use the new processFrame method with built-in frame skipping
        final result = await _scannerService.processFrame(image);

        if (mounted && result.corners.isNotEmpty) {
          setState(() {
            _detectedCorners = result.corners;
            _isDocumentDetected = result.isDocumentDetected;
            _documentQuality = result.qualityScore;
          });

          // Auto capture if enabled and document is detected with good quality
          if (_autoCapture &&
              result.shouldAutoCapture &&
              result.qualityScore > 0.7) {
            _autoCaptureTrigger();
          }
        }
      } catch (e) {
        print('Edge detection error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _stopImageStream() {
    if (_cameraController != null && _isStreamingImages) {
      _cameraController!.stopImageStream();
      _isStreamingImages = false;
      _isProcessing = false;
    }
  }

  void _toggleEdgeDetection() {
    setState(() {
      _isDetectionEnabled = !_isDetectionEnabled;
    });

    if (_isDetectionEnabled) {
      _startImageStream();
    } else {
      _stopImageStream();
      // Clear detected corners
      setState(() {
        _detectedCorners = [];
        _isDocumentDetected = false;
        _documentQuality = 0.0;
      });
    }
  }

  Future<void> _autoCaptureTrigger() async {
    if (_isProcessing) return;

    // Delay to ensure stability
    await Future.delayed(const Duration(milliseconds: 500));

    if (_isDocumentDetected && _documentQuality > 0.8) {
      _captureDocument();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanPreviewScreen(
              imagePath: image.path,
              scanMode: _selectedMode,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _captureDocument() async {
    if (_isProcessing || _cameraController == null || !_isCameraInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Stop image stream before capturing
      _stopImageStream();

      final XFile image = await _cameraController!.takePicture();

      // Resume image stream after capture if we're staying on this screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanPreviewScreen(
              imagePath: image.path,
              scanMode: _selectedMode,
              detectedCorners:
                  _detectedCorners.isNotEmpty ? _detectedCorners : null,
            ),
          ),
        ).then((_) {
          // Restart stream when coming back
          if (mounted && _cameraController != null) {
            _startImageStream();
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to capture: $e');
      // Restart stream on error
      _startImageStream();
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;

    setState(() {
      _flashEnabled = !_flashEnabled;
    });

    await _cameraController!.setFlashMode(
      _flashEnabled ? FlashMode.torch : FlashMode.off,
    );
  }

  void _changeScanMode(ScanMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content:
            const Text('Please grant camera permission to scan documents.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  @override
  void dispose() {
    _stopImageStream();
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Detection Overlay
          if (_isDocumentDetected && _detectedCorners.isNotEmpty)
            CustomPaint(
              size: Size.infinite,
              painter: DocumentOverlayPainter(
                corners: _detectedCorners,
                quality: _documentQuality,
              ),
            ),

          // Top Controls
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                SizedBox(height: 20.h),
                _buildScanModeSelector(),
                const Spacer(),
                _buildBottomControls(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Flash Toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _flashEnabled ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
          ),

          // Edge Detection Indicator
          if (_isDocumentDetected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _documentQuality > 0.7
                    ? Colors.green.withOpacity(0.8)
                    : Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _documentQuality > 0.7 ? 'Perfect' : 'Align',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Edge Detection Toggle
          Container(
            decoration: BoxDecoration(
              color: _isDetectionEnabled
                  ? AppColors.primaryBlue.withOpacity(0.8)
                  : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isDetectionEnabled
                    ? Icons.crop_free
                    : Icons.crop_free_outlined,
                color: Colors.white,
              ),
              onPressed: _toggleEdgeDetection,
              tooltip: _isDetectionEnabled
                  ? 'Disable Edge Detection'
                  : 'Enable Edge Detection',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanModeSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModeButton(
            icon: Icons.description_outlined,
            label: 'Document',
            mode: ScanMode.document,
          ),
          _buildModeButton(
            icon: Icons.credit_card,
            label: 'ID Card',
            mode: ScanMode.idCard,
          ),
          _buildModeButton(
            icon: Icons.receipt_long,
            label: 'Receipt',
            mode: ScanMode.receipt,
          ),
          _buildModeButton(
            icon: Icons.business_center,
            label: 'Card',
            mode: ScanMode.businessCard,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required ScanMode mode,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => _changeScanMode(mode),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery Button
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child:
                  Icon(Icons.photo_library, color: Colors.white, size: 28.sp),
            ),
          ),

          // Capture Button
          ScaleTransition(
            scale: _isDocumentDetected
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1.0),
            child: GestureDetector(
              onTap: _captureDocument,
              child: Container(
                width: 72.w,
                height: 72.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _isProcessing
                    ? Padding(
                        padding: EdgeInsets.all(20.w),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.camera,
                        color: AppColors.primaryBlue,
                        size: 36.sp,
                      ),
              ),
            ),
          ),

          // Auto Capture Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _autoCapture = !_autoCapture;
              });
            },
            child: Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                color: _autoCapture
                    ? AppColors.primaryBlue
                    : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _autoCapture ? AppColors.primaryBlue : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentOverlayPainter extends CustomPainter {
  final List<Offset> corners;
  final double quality;

  DocumentOverlayPainter({
    required this.corners,
    required this.quality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    // Determine color based on quality
    final Color overlayColor = quality > 0.7 ? Colors.green : Colors.orange;

    // Draw semi-transparent fill
    final fillPaint = Paint()
      ..color = overlayColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final fillPath = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(fillPath, fillPaint);

    // Draw thicker border lines
    final borderPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final borderPath = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(borderPath, borderPaint);

    // Draw corner circles with white border
    for (final corner in corners) {
      // White outer circle
      final outerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(corner, 12, outerPaint);

      // Colored inner circle
      final innerPaint = Paint()
        ..color = overlayColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(corner, 9, innerPaint);
    }

    // Draw lines connecting corners with scanning animation
    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final nextCorner = corners[(i + 1) % corners.length];

      // Draw short lines extending from corners
      final dx = (nextCorner.dx - corner.dx) * 0.1;
      final dy = (nextCorner.dy - corner.dy) * 0.1;

      canvas.drawLine(
        corner,
        Offset(corner.dx + dx, corner.dy + dy),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
