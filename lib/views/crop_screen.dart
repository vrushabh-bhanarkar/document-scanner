import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/themes.dart';
import '../providers/document_provider.dart';
import 'pdf_settings_screen.dart' show CameraFramePreset;

enum CropMode { original, freeCrop }

class CropScreen extends StatefulWidget {
  final String imagePath;
  final String? title;
  final double? imageAspectRatio;
  final CameraFramePreset? cameraFramePreset;

  const CropScreen({
    super.key,
    required this.imagePath,
    this.title,
    this.imageAspectRatio,
    this.cameraFramePreset,
  });

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  Uint8List? _imageBytes;
  bool _isCropping = false;
  bool _isLoading = true;
  bool _isCropReady = false;
  Timer? _cropTimeout;
  CropMode _cropMode = CropMode.original;
  final GlobalKey<_PerspectiveCropWidgetState> _perspectiveKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Image loading timed out');
        },
      );

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
        _isCropReady = _cropMode == CropMode.original;
      });

      // Add safety timeout - if crop doesn't become ready in 3 seconds, force ready
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_isCropReady && _imageBytes != null) {
          print('CropScreen: Forcing crop ready state after timeout');
          setState(() => _isCropReady = true);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load image: $e')),
      );
      Navigator.pop(context, {'cropped': false, 'path': widget.imagePath});
    }
  }

  Future<void> _onCropped(Uint8List croppedBytes) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final croppedDir = Directory('${dir.path}/cropped_images');
      if (!await croppedDir.exists()) {
        await croppedDir.create(recursive: true);
      }
      final path =
          '${croppedDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);

      // If Original mode is selected, use original image bytes
      final bytesToSave =
          _cropMode == CropMode.original ? _imageBytes! : croppedBytes;

      await file.writeAsBytes(bytesToSave, flush: true);

      if (!mounted) return;
      await Provider.of<DocumentProvider>(context, listen: false)
          .setCurrentImagePath(path);
      if (!mounted) return;
      // Clear cropping state and any timeout before leaving
      _cropTimeout?.cancel();
      _cropTimeout = null;
      if (mounted) setState(() => _isCropping = false);
      Navigator.pop(context, {'cropped': true, 'path': path});
    } catch (e) {
      if (!mounted) return;
      _cropTimeout?.cancel();
      _cropTimeout = null;
      setState(() => _isCropping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save cropped image: $e')),
      );
    }
  }

  Future<void> _startCrop() async {
    print('CropScreen: _startCrop called, mode: $_cropMode');
    final isEnabled = _cropMode == CropMode.original || _isCropReady;

    if (_imageBytes == null || _isCropping || !isEnabled) {
      print(
          'CropScreen: Crop blocked - imageBytes: ${_imageBytes != null}, isCropping: $_isCropping, isEnabled: $isEnabled');
      if (mounted && !_isCropReady && _cropMode != CropMode.original) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please wait, image is still preparing.')),
        );
      }
      return;
    }

    setState(() => _isCropping = true);
    try {
      print('CropScreen: Starting crop process...');
      // Get cropped bytes
      Uint8List croppedBytes;
      if (_cropMode == CropMode.original) {
        print('CropScreen: Using original image');
        croppedBytes = _imageBytes!;
      } else {
        print('CropScreen: Getting perspective cropped image...');
        // Get perspective cropped image from widget
        final state = _perspectiveKey.currentState;
        if (state != null) {
          print('CropScreen: Calling getCroppedImage()...');
          croppedBytes = await Future(() => state.getCroppedImage());
          print('CropScreen: Got cropped bytes, size: ${croppedBytes.length}');
        } else {
          print(
              'CropScreen: WARNING - perspective key state is null, using original');
          croppedBytes = _imageBytes!;
        }
      }

      // Save cropped image
      print('CropScreen: Saving cropped image...');
      final dir = await getApplicationDocumentsDirectory();
      final croppedDir = Directory('${dir.path}/cropped_images');
      if (!await croppedDir.exists()) {
        await croppedDir.create(recursive: true);
      }
      final path =
          '${croppedDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('CropScreen: Save path: $path');
      final file = File(path);
      await file.writeAsBytes(croppedBytes, flush: true);
      print('CropScreen: File saved, size: ${await file.length()} bytes');

      if (!mounted) return;
      print('CropScreen: Updating document provider...');
      await Provider.of<DocumentProvider>(context, listen: false)
          .setCurrentImagePath(path);

      if (!mounted) return;
      _cropTimeout?.cancel();
      _cropTimeout = null;
      if (mounted) setState(() => _isCropping = false);
      print('CropScreen: Navigating back with success');
      Navigator.pop(context, {'cropped': true, 'path': path});
    } catch (e, stackTrace) {
      print('CropScreen: ERROR in _startCrop: $e');
      print('CropScreen: Stack trace: $stackTrace');
      if (!mounted) return;
      _cropTimeout?.cancel();
      _cropTimeout = null;
      setState(() => _isCropping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Crop failed: $e'),
            duration: const Duration(seconds: 5)),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(
                  context, {'cropped': false, 'path': widget.imagePath}),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title ?? 'Crop Image',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropper(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Loading image...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_imageBytes == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load image',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Original mode - just show the image
    if (_cropMode == CropMode.original) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Free crop mode - show perspective cropper with 8 control points
    return PerspectiveCropWidget(
      key: _perspectiveKey,
      imageBytes: _imageBytes!,
      onReady: () {
        if (mounted && !_isCropReady) {
          setState(() => _isCropReady = true);
        }
      },
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instruction hint for crop mode
          if (_cropMode == CropMode.freeCrop)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Drag the corner points to adjust crop area',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 90,
                child: _buildModeButton(
                  mode: CropMode.original,
                  icon: Icons.image_outlined,
                  label: 'Original',
             
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: _buildModeButton(
                  mode: CropMode.freeCrop,
                  icon: Icons.crop_free,
                  label: 'Free Crop',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required CropMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _cropMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _cropMode = mode;
          _isCropReady = mode == CropMode.original ? true : false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.gray300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.gray700,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.gray900,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final isEnabled =
        (_cropMode == CropMode.original || _isCropReady) && !_isCropping;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(
                    context, {'cropped': false, 'path': widget.imagePath}),
                icon: const Icon(Icons.close, size: 22),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.gray300, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  foregroundColor: AppColors.gray700,
                ),
                label: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isEnabled ? AppColors.primaryGradient : null,
                  color: isEnabled ? null : AppColors.gray300,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton.icon(
                  onPressed: isEnabled ? _startCrop : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: Text(
                    _cropMode == CropMode.original
                        ? 'Use Original'
                        : 'Apply Crop',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cropTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildCropper(context)),
              _buildModeSelector(),
              _buildBottomBar(context),
            ],
          ),
          if (_isCropping)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _cropMode == CropMode.original
                            ? 'Saving original...'
                            : 'Cropping image...',
                        style: TextStyle(
                          color: AppColors.gray800,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
}

// Custom Perspective Crop Widget with 8-point diagonal control
class PerspectiveCropWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final VoidCallback onReady;

  const PerspectiveCropWidget({
    super.key,
    required this.imageBytes,
    required this.onReady,
  });

  @override
  State<PerspectiveCropWidget> createState() => _PerspectiveCropWidgetState();
}

class _PerspectiveCropWidgetState extends State<PerspectiveCropWidget> {
  late List<Offset> cropPoints;
  int? _draggedPointIndex;
  late Size _imageSize;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    try {
      final image = await decodeImageFromList(widget.imageBytes);
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _initializeCropPoints();
        _isInitialized = true;
      });
      widget.onReady();
    } catch (e) {
      print('Error initializing image: $e');
    }
  }

  void _initializeCropPoints() {
    // 4 corner points only - like professional document scanners
    // Top-left, Top-right, Bottom-right, Bottom-left
    // Use smaller margin for better initial crop area
    final marginPercent = 0.05; // 5% margin
    final marginX = _imageSize.width * marginPercent;
    final marginY = _imageSize.height * marginPercent;

    cropPoints = [
      Offset(marginX, marginY), // Top-Left
      Offset(_imageSize.width - marginX, marginY), // Top-Right
      Offset(_imageSize.width - marginX,
          _imageSize.height - marginY), // Bottom-Right
      Offset(marginX, _imageSize.height - marginY), // Bottom-Left
    ];
  }

  Uint8List _perspectiveCrop() {
    try {
      print('PerspectiveCrop: Starting perspective crop...');
      final image = img.decodeImage(widget.imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      print('PerspectiveCrop: Image decoded: ${image.width}x${image.height}');

      // Use the 4 corner points (TL, TR, BR, BL)
      final src = [
        cropPoints[0], // TL
        cropPoints[1], // TR
        cropPoints[2], // BR
        cropPoints[3], // BL
      ];

      print(
          'PerspectiveCrop: Source points: ${src.map((p) => "(${p.dx.toInt()},${p.dy.toInt()})").join(", ")}');

      // Calculate output dimensions based on AVERAGE of opposite edges
      // This preserves the actual shape of the cropped region
      final widthTop = _distance(src[0], src[1]);
      final widthBottom = _distance(src[3], src[2]);
      final heightLeft = _distance(src[0], src[3]);
      final heightRight = _distance(src[1], src[2]);

      // Average the widths and heights to get proper dimensions
      final destWidth =
          ((widthTop + widthBottom) / 2).round().clamp(10, image.width * 3);
      final destHeight =
          ((heightLeft + heightRight) / 2).round().clamp(10, image.height * 3);

      print('PerspectiveCrop: Destination size: ${destWidth}x${destHeight}');
      print(
          'PerspectiveCrop: Aspect ratio: ${(destWidth / destHeight).toStringAsFixed(2)}');

      // Use copyRectify for perspective transformation
      var cropped = img.copyRectify(
        image,
        topLeft: img.Point(src[0].dx.toInt(), src[0].dy.toInt()),
        topRight: img.Point(src[1].dx.toInt(), src[1].dy.toInt()),
        bottomRight: img.Point(src[2].dx.toInt(), src[2].dy.toInt()),
        bottomLeft: img.Point(src[3].dx.toInt(), src[3].dy.toInt()),
      );

      print(
          'PerspectiveCrop: Initial cropped size: ${cropped.width}x${cropped.height}');

      // Resize to match the calculated dimensions to preserve aspect ratio
      if (cropped.width != destWidth || cropped.height != destHeight) {
        print(
            'PerspectiveCrop: Resizing from ${cropped.width}x${cropped.height} to ${destWidth}x${destHeight}');
        cropped = img.copyResize(
          cropped,
          width: destWidth,
          height: destHeight,
          interpolation: img.Interpolation.cubic,
        );
      }

      print('PerspectiveCrop: Final size: ${cropped.width}x${cropped.height}');
      print('PerspectiveCrop: Transform complete, encoding...');
      final encoded = Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
      print('PerspectiveCrop: Done, size: ${encoded.length} bytes');
      return encoded;
    } catch (e, stackTrace) {
      print('PerspectiveCrop: ERROR: $e');
      print('PerspectiveCrop: Stack: $stackTrace');

      // Fallback: try simple crop if perspective fails
      try {
        final fallbackImage = img.decodeImage(widget.imageBytes);
        if (fallbackImage != null) {
          // Find bounding box
          final minX = [
            cropPoints[0].dx,
            cropPoints[1].dx,
            cropPoints[2].dx,
            cropPoints[3].dx
          ].reduce(min).clamp(0.0, fallbackImage.width.toDouble()).toInt();
          final maxX = [
            cropPoints[0].dx,
            cropPoints[1].dx,
            cropPoints[2].dx,
            cropPoints[3].dx
          ].reduce(max).clamp(0.0, fallbackImage.width.toDouble()).toInt();
          final minY = [
            cropPoints[0].dy,
            cropPoints[1].dy,
            cropPoints[2].dy,
            cropPoints[3].dy
          ].reduce(min).clamp(0.0, fallbackImage.height.toDouble()).toInt();
          final maxY = [
            cropPoints[0].dy,
            cropPoints[1].dy,
            cropPoints[2].dy,
            cropPoints[3].dy
          ].reduce(max).clamp(0.0, fallbackImage.height.toDouble()).toInt();

          final cropped = img.copyCrop(
            fallbackImage,
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY,
          );

          return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
        }
      } catch (e2) {
        print('Fallback crop also failed: $e2');
      }

      return widget.imageBytes;
    }
  }

  double _distance(Offset p1, Offset p2) {
    final dx = p1.dx - p2.dx;
    final dy = p1.dy - p2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  Uint8List getCroppedImage() {
    return _perspectiveCrop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Calculate display dimensions preserving aspect ratio
        final imageAspect = _imageSize.width / _imageSize.height;
        final screenAspect = availableWidth / availableHeight;

        late double displayWidth;
        late double displayHeight;
        late double offsetX;
        late double offsetY;

        if (imageAspect > screenAspect) {
          displayWidth = availableWidth;
          displayHeight = availableWidth / imageAspect;
          offsetX = 0;
          offsetY = (availableHeight - displayHeight) / 2;
        } else {
          displayHeight = availableHeight;
          displayWidth = availableHeight * imageAspect;
          offsetX = (availableWidth - displayWidth) / 2;
          offsetY = 0;
        }

        final scaleX = displayWidth / _imageSize.width;
        final scaleY = displayHeight / _imageSize.height;

        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Image and crop overlay
              Positioned(
                left: offsetX,
                top: offsetY,
                width: displayWidth,
                height: displayHeight,
                child: Stack(
                  children: [
                    // Background image
                    Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.cover,
                      width: displayWidth,
                      height: displayHeight,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          width: displayWidth,
                          height: displayHeight,
                          child:  Center(
                                  child: Icon(Icons.broken_image, color: Colors.white54),
                          ),
                        );
                      },
                    ),
                    // Crop overlay painter
                    CustomPaint(
                      size: Size(displayWidth, displayHeight),
                      painter: PerspectiveCropPainter(
                        cropPoints: cropPoints,
                        imageSize: _imageSize,
                        displayWidth: displayWidth,
                        displayHeight: displayHeight,
                      ),
                    ),
                  ],
                ),
              ),
              // Control points with integrated gesture handling
              ..._buildControlPoints(offsetX, offsetY, scaleX, scaleY),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildControlPoints(
      double offsetX, double offsetY, double scaleX, double scaleY) {
    final pointLabels = ['TL', 'TR', 'BR', 'BL'];

    return List.generate(cropPoints.length, (index) {
      final point = cropPoints[index];
      final screenPos = Offset(
        offsetX + point.dx * scaleX,
        offsetY + point.dy * scaleY,
      );
      final isSelected = _draggedPointIndex == index;

      return Positioned(
        left: screenPos.dx - 35,
        top: screenPos.dy - 35,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            setState(() => _draggedPointIndex = index);
          },
          onPanUpdate: (details) {
            setState(() {
              final newOffset = cropPoints[index] +
                  Offset(details.delta.dx / scaleX, details.delta.dy / scaleY);
              cropPoints[index] = Offset(
                newOffset.dx.clamp(0, _imageSize.width),
                newOffset.dy.clamp(0, _imageSize.height),
              );
            });
          },
          onPanEnd: (_) {
            setState(() => _draggedPointIndex = null);
          },
          child: Container(
            width: 70,
            height: 70,
            color: Colors.transparent,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse animation outer ring when selected
                  if (isSelected)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  // Outer glow ring for better visibility
                  Container(
                    width: isSelected ? 42 : 36,
                    height: isSelected ? 42 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  // Main control point
                  Container(
                    width: isSelected ? 34 : 28,
                    height: isSelected ? 34 : 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: isSelected ? 4 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: isSelected ? 12 : 8,
                          spreadRadius: isSelected ? 2 : 1,
                        ),
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(
                            isSelected ? 0.7 : 0.4,
                          ),
                          blurRadius: isSelected ? 16 : 10,
                          spreadRadius: isSelected ? 3 : 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: isSelected ? 10 : 8,
                        height: isSelected ? 10 : 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  // Corner indicator lines
                  if (!isSelected)
                    CustomPaint(
                      size: Size(28, 28),
                      painter: CornerIndicatorPainter(
                        color: AppColors.primaryBlue.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class PerspectiveCropPainter extends CustomPainter {
  final List<Offset> cropPoints;
  final Size imageSize;
  final double displayWidth;
  final double displayHeight;

  PerspectiveCropPainter({
    required this.cropPoints,
    required this.imageSize,
    required this.displayWidth,
    required this.displayHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // Safety checks
      if (cropPoints.isEmpty || cropPoints.length < 4) return;

      // Validate dimensions
      if (displayWidth <= 0 ||
          displayHeight <= 0 ||
          imageSize.width <= 0 ||
          imageSize.height <= 0) {
        return;
      }

      // Calculate scale factors
      final scaleX = displayWidth / imageSize.width;
      final scaleY = displayHeight / imageSize.height;

      // Draw semi-transparent overlay outside crop area
      try {
        final cropQuad = [
          Offset(cropPoints[0].dx * scaleX, cropPoints[0].dy * scaleY),
          Offset(cropPoints[1].dx * scaleX, cropPoints[1].dy * scaleY),
          Offset(cropPoints[2].dx * scaleX, cropPoints[2].dy * scaleY),
          Offset(cropPoints[3].dx * scaleX, cropPoints[3].dy * scaleY),
        ];

        canvas.drawPath(
          Path()
            ..addRect(Rect.fromLTWH(0, 0, displayWidth, displayHeight))
            ..addPolygon(cropQuad, true),
          Paint()..color = Colors.black.withOpacity(0.5),
        );
      } catch (e) {
        print('Overlay drawing error: $e');
      }

      // Draw crop quadrilateral outline with double border for better visibility
      try {
        final cropPath = Path();
        cropPath.moveTo(
          cropPoints[0].dx * scaleX,
          cropPoints[0].dy * scaleY,
        );
        for (int i = 1; i < 4; i++) {
          cropPath.lineTo(
            cropPoints[i].dx * scaleX,
            cropPoints[i].dy * scaleY,
          );
        }
        cropPath.close();

        // Draw outer border (darker)
        canvas.drawPath(
          cropPath,
          Paint()
            ..color = Colors.black.withOpacity(0.8)
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke,
        );

        // Draw inner border (bright blue)
        canvas.drawPath(
          cropPath,
          Paint()
            ..color = AppColors.primaryBlue
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      } catch (e) {
        print('Crop outline drawing error: $e');
      }

      // Draw grid lines
      try {
        _drawGridLines(canvas, scaleX, scaleY);
      } catch (e) {
        print('Grid lines drawing error: $e');
      }
    } catch (e) {
      print('Fatal paint error: $e');
    }
  }

  void _drawGridLines(Canvas canvas, double scaleX, double scaleY) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5;

    final tl = Offset(cropPoints[0].dx * scaleX, cropPoints[0].dy * scaleY);
    final tr = Offset(cropPoints[1].dx * scaleX, cropPoints[1].dy * scaleY);
    final br = Offset(cropPoints[2].dx * scaleX, cropPoints[2].dy * scaleY);
    final bl = Offset(cropPoints[3].dx * scaleX, cropPoints[3].dy * scaleY);

    // Horizontal grid lines
    for (int i = 1; i < 3; i++) {
      final t = i / 3.0;
      final p1 = Offset(
        tl.dx + (tr.dx - tl.dx) * t,
        tl.dy + (tr.dy - tl.dy) * t,
      );
      final p2 = Offset(
        bl.dx + (br.dx - bl.dx) * t,
        bl.dy + (br.dy - bl.dy) * t,
      );
      canvas.drawLine(p1, p2, gridPaint);
    }

    // Vertical grid lines
    for (int i = 1; i < 3; i++) {
      final t = i / 3.0;
      final p1 = Offset(
        tl.dx + (bl.dx - tl.dx) * t,
        tl.dy + (bl.dy - tl.dy) * t,
      );
      final p2 = Offset(
        tr.dx + (br.dx - tr.dx) * t,
        tr.dy + (br.dy - tr.dy) * t,
      );
      canvas.drawLine(p1, p2, gridPaint);
    }
  }

  @override
  bool shouldRepaint(PerspectiveCropPainter oldDelegate) => true;
}

// Custom painter for corner indicator lines on control points
class CornerIndicatorPainter extends CustomPainter {
  final Color color;

  CornerIndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = size.width / 2;
    final lineLength = size.width * 0.25;

    // Draw L-shaped corner indicator
    // Top-left corner lines
    canvas.drawLine(
      Offset(center - lineLength, center - lineLength),
      Offset(center - lineLength / 2, center - lineLength),
      paint,
    );
    canvas.drawLine(
      Offset(center - lineLength, center - lineLength),
      Offset(center - lineLength, center - lineLength / 2),
      paint,
    );

    // Top-right corner lines
    canvas.drawLine(
      Offset(center + lineLength, center - lineLength),
      Offset(center + lineLength / 2, center - lineLength),
      paint,
    );
    canvas.drawLine(
      Offset(center + lineLength, center - lineLength),
      Offset(center + lineLength, center - lineLength / 2),
      paint,
    );

    // Bottom-right corner lines
    canvas.drawLine(
      Offset(center + lineLength, center + lineLength),
      Offset(center + lineLength / 2, center + lineLength),
      paint,
    );
    canvas.drawLine(
      Offset(center + lineLength, center + lineLength),
      Offset(center + lineLength, center + lineLength / 2),
      paint,
    );

    // Bottom-left corner lines
    canvas.drawLine(
      Offset(center - lineLength, center + lineLength),
      Offset(center - lineLength / 2, center + lineLength),
      paint,
    );
    canvas.drawLine(
      Offset(center - lineLength, center + lineLength),
      Offset(center - lineLength, center + lineLength / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerIndicatorPainter oldDelegate) =>
      color != oldDelegate.color;
}
