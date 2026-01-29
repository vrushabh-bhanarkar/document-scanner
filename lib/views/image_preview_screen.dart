import 'dart:io';
import 'package:flutter/material.dart';
import '../core/themes.dart';
import '../services/file_management_service.dart';
import '../services/image_enhancement_service.dart';
import '../models/document_model.dart';
import '../services/notification_service.dart';
import '../widgets/interstitial_ad_helper.dart';

class ImagePreviewScreen extends StatefulWidget {
  final String originalImagePath;
  final String processedImagePath;
  final List<Offset> detectedCorners;
  final double qualityScore;

  const ImagePreviewScreen({
    Key? key,
    required this.originalImagePath,
    required this.processedImagePath,
    required this.detectedCorners,
    required this.qualityScore,
  }) : super(key: key);

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FileManagementService _fileService = FileManagementService();
  final ImageEnhancementService _enhancementService = ImageEnhancementService();

  String _currentImagePath = '';
  bool _isProcessing = false;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.processedImagePath;
    _setupAnimations();
  }

  void _setupAnimations() {
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
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _enhanceImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final enhancedPath = await _enhancementService.applyFilter(
        File(_currentImagePath),
        ImageFilter.enhance,
      );

      if (enhancedPath != null) {
        setState(() {
          _currentImagePath = enhancedPath.path;
        });
        _showSuccessMessage('Image enhanced successfully');
      }
    } catch (e) {
      _showErrorMessage('Failed to enhance image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _saveImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Save document using file management service
      final document = await _fileService.saveDocument(
        sourceFile: File(_currentImagePath),
        title:
            'Scanned Document ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
        type: DocumentType.image,
        metadata: {
          'qualityScore': widget.qualityScore,
          'hasCorners': widget.detectedCorners.isNotEmpty,
          'originalPath': widget.originalImagePath,
          'processedPath': widget.processedImagePath,
        },
      );

      if (document != null) {
        _showSuccessMessage('Document saved successfully');
        await NotificationService().showNotification(
          title: 'File Saved',
          body: 'Your image has been saved successfully!',
        );
        InterstitialAdHelper.showInterstitialAd(
          onAdClosed: () async {
            await _showPostSaveOptions(context, File(_currentImagePath));
            // Return to previous screen with success result
            Navigator.pop(context, {
              'saved': true,
              'document': document,
              'imagePath': _currentImagePath,
            });
          },
        );
      } else {
        _showErrorMessage('Failed to save document');
      }
    } catch (e) {
      _showErrorMessage('Failed to save image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.gray800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.gray800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final textScale = media.textScaleFactor;
    final padding = screenWidth * 0.04;
    final borderRadius = screenWidth * 0.06;
    final cardPadding = screenWidth * 0.03;
    final iconSize = screenWidth * 0.07;
    final fontSize = screenWidth * 0.045;
    final smallFontSize = screenWidth * 0.035;
    final buttonHeight = screenHeight * 0.07;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Preview',
            style: TextStyle(
                fontSize: fontSize * 1.1, fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveImage,
            tooltip: 'Save Image',
            iconSize: iconSize,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image preview
                Container(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: AppShadows.cardShadow,
                  ),
                  child: Image.file(
                    File(_currentImagePath),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: padding),
                // Quality and info
                Row(
                  children: [
                    Icon(Icons.verified,
                        color: AppColors.success, size: iconSize),
                    SizedBox(width: cardPadding),
                    Flexible(
                      child: Text(
                        'Quality: ${widget.qualityScore.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: smallFontSize,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: cardPadding),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _enhanceImage,
                      icon: Icon(Icons.auto_fix_high, size: iconSize),
                      label: FittedBox(
                          child: Text('Enhance',
                              style: TextStyle(fontSize: smallFontSize))),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(screenWidth * 0.3, buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveImage,
                      icon: Icon(Icons.save, size: iconSize),
                      label: FittedBox(
                          child: Text('Save',
                              style: TextStyle(fontSize: smallFontSize))),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(screenWidth * 0.3, buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isProcessing)
                  Padding(
                    padding: EdgeInsets.only(top: cardPadding),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.gray700,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Image Preview',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getQualityColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Quality: ${_getQualityText()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                _showOriginal ? Icons.auto_fix_high : Icons.photo,
                color: AppColors.gray700,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showOriginal = !_showOriginal;
                  _currentImagePath = _showOriginal
                      ? widget.originalImagePath
                      : widget.processedImagePath;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: Image.file(
                File(_currentImagePath),
                fit: BoxFit.contain,
              ),
            ),

            // Corner indicators if available
            if (widget.detectedCorners.isNotEmpty && !_showOriginal)
              _buildCornerOverlay(),

            // Processing overlay
            if (_isProcessing) _buildProcessingOverlay(),

            // Image type indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _showOriginal ? 'Original' : 'Processed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerOverlay() {
    return CustomPaint(
      painter: CornerOverlayPainter(
        corners: widget.detectedCorners,
        color: _getQualityColor(),
      ),
      size: Size.infinite,
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
                const SizedBox(height: 16),
                Text(
                  'Processing...',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.auto_fix_high,
                  label: 'Enhance',
                  onTap: _enhanceImage,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.crop,
                  label: 'Crop',
                  onTap: () {
                    // TODO: Navigate to crop screen
                  },
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.tune,
                  label: 'Adjust',
                  onTap: () {
                    // TODO: Navigate to adjustment screen
                  },
                  color: AppColors.amber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _saveImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Save Document',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getQualityColor() {
    if (widget.qualityScore >= 0.8) return AppColors.success;
    if (widget.qualityScore >= 0.6) return AppColors.amber;
    return AppColors.error;
  }

  String _getQualityText() {
    if (widget.qualityScore >= 0.8) return 'Excellent';
    if (widget.qualityScore >= 0.6) return 'Good';
    if (widget.qualityScore >= 0.4) return 'Fair';
    return 'Poor';
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
              leading: const Icon(Icons.photo_library),
              title: const Text('Save to Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await _fileService.saveToGallery(file);
                _showSuccessMessage(
                    result ? 'Saved to Gallery!' : 'Failed to save to Gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Save to Downloads'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await _fileService.saveToDownloads(file);
                _showSuccessMessage(result
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

  Future<void> _showPostDialog(BuildContext context) async {
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

class CornerOverlayPainter extends CustomPainter {
  final List<Offset> corners;
  final Color color;

  CornerOverlayPainter({
    required this.corners,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create path for document outline
    final path = Path();
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();

    // Draw filled area
    canvas.drawPath(path, fillPaint);

    // Draw border
    canvas.drawPath(path, paint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(corner, 8, cornerPaint);
      canvas.drawCircle(corner, 4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(CornerOverlayPainter oldDelegate) {
    return corners != oldDelegate.corners || color != oldDelegate.color;
  }
}
