import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/image_enhancement_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../providers/document_provider.dart';
import '../models/document_model.dart';
import 'package:flutter/foundation.dart';
import 'create_pdf_screen.dart';
import 'dart:async';
import '../services/notification_service.dart';

// Image state class for history management
class ImageState {
  final File image;
  final ImageFilter filter;
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final double blur;
  final double vignette;
  final int rotation;
  final bool flipHorizontal;
  final bool flipVertical;

  ImageState({
    required this.image,
    required this.filter,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.sharpness,
    required this.blur,
    required this.vignette,
    required this.rotation,
    required this.flipHorizontal,
    required this.flipVertical,
  });
}

class ImageEditorScreen extends StatefulWidget {
  final File imageFile;
  final String? title;
  final bool isFromCreatePdf;
  final double? initialAspectRatio;

  const ImageEditorScreen({
    Key? key,
    required this.imageFile,
    this.title,
    this.isFromCreatePdf = false,
    this.initialAspectRatio,
  }) : super(key: key);

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen>
    with TickerProviderStateMixin {
  late ImageEnhancementService _enhancementService;
  late OCRService _ocrService;
  late PDFService _pdfService;

  File _currentImage;
  bool _isProcessing = false;
  String _processingText = '';

  // Enhancement controls with real-time updates
  ImageFilter _selectedFilter = ImageFilter.none;
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _sharpness = 1.0;
  double _blur = 0.0;
  double _vignette = 0.0;
  int _rotation = 0;
  bool _flipHorizontal = false;
  bool _flipVertical = false;

  // Filter preview cache
  final Map<ImageFilter, Uint8List?> _filterPreviews = {};

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // UI state
  bool _showBeforeAfter = false;
  File? _originalImage;
  int _selectedTabIndex = 0;

  // History management for undo/redo
  final List<ImageState> _history = [];
  int _currentHistoryIndex = -1;
  static const int _maxHistorySize = 15;

  // Real-time editing
  Timer? _applyTimer;
  bool _hasUnsavedChanges = false;

  _ImageEditorScreenState() : _currentImage = File('');

  @override
  void initState() {
    super.initState();
    _currentImage = widget.imageFile;
    _originalImage = widget.imageFile;
    _enhancementService = ImageEnhancementService();
    _ocrService = OCRService();
    _pdfService = PDFService();

    // Initialize history with original state
    _addToHistory(_createImageState());

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _applyTimer?.cancel();
    _ocrService.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  ImageState _createImageState() {
    return ImageState(
      image: _currentImage,
      filter: _selectedFilter,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      sharpness: _sharpness,
      blur: _blur,
      vignette: _vignette,
      rotation: _rotation,
      flipHorizontal: _flipHorizontal,
      flipVertical: _flipVertical,
    );
  }

  void _applyImageState(ImageState state) {
    setState(() {
      _currentImage = state.image;
      _selectedFilter = state.filter;
      _brightness = state.brightness;
      _contrast = state.contrast;
      _saturation = state.saturation;
      _sharpness = state.sharpness;
      _blur = state.blur;
      _vignette = state.vignette;
      _rotation = state.rotation;
      _flipHorizontal = state.flipHorizontal;
      _flipVertical = state.flipVertical;
    });
  }

  // History management methods
  void _addToHistory(ImageState state) {
    // Remove any history after current index
    if (_currentHistoryIndex < _history.length - 1) {
      _history.removeRange(_currentHistoryIndex + 1, _history.length);
    }

    // Add new state to history
    _history.add(state);
    _currentHistoryIndex = _history.length - 1;

    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _currentHistoryIndex--;
    }
  }

  bool get _canUndo => _currentHistoryIndex > 0;
  bool get _canRedo => _currentHistoryIndex < _history.length - 1;

  void _undo() {
    if (_canUndo) {
      setState(() {
        _currentHistoryIndex--;
        _applyImageState(_history[_currentHistoryIndex]);
      });
    }
  }

  void _redo() {
    if (_canRedo) {
      setState(() {
        _currentHistoryIndex++;
        _applyImageState(_history[_currentHistoryIndex]);
      });
    }
  }

  // Real-time editing with debounced apply
  void _scheduleApply() {
    _hasUnsavedChanges = true;
    _applyTimer?.cancel();
    _applyTimer = Timer(const Duration(milliseconds: 500), () {
      _applyChanges();
    });
  }

  Future<void> _applyChanges() async {
    if (!_hasUnsavedChanges) return;

    setState(() {
      _isProcessing = true;
      _processingText = 'Applying changes...';
    });

    try {
      File? processedImage = await _enhancementService.applyEnhancements(
        _originalImage!,
        filter: _selectedFilter,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        rotation: _rotation,
        flipHorizontal: _flipHorizontal,
        flipVertical: _flipVertical,
      );

      if (mounted && processedImage != null) {
        setState(() {
          _currentImage = processedImage;
          _hasUnsavedChanges = false;
          _isProcessing = false;
        });

        // Add to history after successful apply
        _addToHistory(_createImageState());
      } else {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to apply changes'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying changes: $e')),
        );
      }
    }
  }

  // Reset all changes
  void _resetChanges() {
    setState(() {
      _selectedFilter = ImageFilter.none;
      _brightness = 1.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _sharpness = 1.0;
      _blur = 0.0;
      _vignette = 0.0;
      _rotation = 0;
      _flipHorizontal = false;
      _flipVertical = false;
    });
    _scheduleApply();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),

            // Image Display Area
            Expanded(
              flex: 3,
              child: _buildImageDisplayArea(),
            ),

            // Controls Area
            Expanded(
              flex: 2,
              child: _buildControlsArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              widget.title ?? 'Edit Image',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              // Undo button
              IconButton(
                onPressed: _canUndo ? _undo : null,
                icon: Icon(
                  Icons.undo,
                  color: _canUndo ? Colors.white : Colors.white38,
                ),
              ),
              // Redo button
              IconButton(
                onPressed: _canRedo ? _redo : null,
                icon: Icon(
                  Icons.redo,
                  color: _canRedo ? Colors.white : Colors.white38,
                ),
              ),
              // Reset button
              IconButton(
                onPressed: _resetChanges,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
              if (widget.isFromCreatePdf) ...[
                IconButton(
                  onPressed: _applyChangesForPdf,
                  icon: const Icon(Icons.check, color: Colors.white),
                  tooltip: 'Apply Changes for PDF',
                ),
                IconButton(
                  onPressed: _saveImageToGallery,
                  icon: const Icon(Icons.image, color: Colors.white),
                  tooltip: 'Save Image to Gallery',
                ),
              ] else ...[
                IconButton(
                  onPressed: _saveImage,
                  icon: const Icon(Icons.save, color: Colors.white),
                  tooltip: 'Save',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplayArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: _isProcessing
                  ? Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Image.file(
                      _currentImage,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),

            // Processing overlay
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _processingText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Tab bar
          _buildTabBar(),

          // Tab content
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = [
      {'icon': Icons.filter, 'label': 'Filters'},
      {'icon': Icons.tune, 'label': 'Adjust'},
      {'icon': Icons.transform, 'label': 'Transform'},
      {'icon': Icons.crop, 'label': 'Crop'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFiltersTab();
      case 1:
        return _buildAdjustTab();
      case 2:
        return _buildTransformTab();
      case 3:
        return _buildCropTab();
      default:
        return _buildFiltersTab();
    }
  }

  Widget _buildFiltersTab() {
    final filters = [
      {'filter': ImageFilter.none, 'name': 'None', 'icon': Icons.crop_original},
      {
        'filter': ImageFilter.grayscale,
        'name': 'B&W',
        'icon': Icons.filter_b_and_w
      },
      {
        'filter': ImageFilter.sepia,
        'name': 'Sepia',
        'icon': Icons.filter_vintage
      },
      {'filter': ImageFilter.warm, 'name': 'Warm', 'icon': Icons.wb_sunny},
      {'filter': ImageFilter.cool, 'name': 'Cool', 'icon': Icons.ac_unit},
      {
        'filter': ImageFilter.vintage,
        'name': 'Vintage',
        'icon': Icons.camera_alt
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Choose a filter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter['filter'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['filter'] as ImageFilter;
                  });
                  _scheduleApply();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        filter['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filter['name'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSlider('Brightness', _brightness, 0.0, 2.0, Icons.brightness_6,
              (value) {
            setState(() => _brightness = value);
            _scheduleApply();
          }),
          const SizedBox(height: 16),
          _buildSlider('Contrast', _contrast, 0.0, 2.0, Icons.contrast,
              (value) {
            setState(() => _contrast = value);
            _scheduleApply();
          }),
          const SizedBox(height: 16),
          _buildSlider('Saturation', _saturation, 0.0, 2.0, Icons.color_lens,
              (value) {
            setState(() => _saturation = value);
            _scheduleApply();
          }),
          const SizedBox(height: 16),
          _buildSlider(
              'Sharpness', _sharpness, 0.0, 2.0, Icons.center_focus_strong,
              (value) {
            setState(() => _sharpness = value);
            _scheduleApply();
          }),
          const SizedBox(height: 16),
          _buildSlider('Blur', _blur, 0.0, 10.0, Icons.blur_on, (value) {
            setState(() => _blur = value);
            _scheduleApply();
          }),
          const SizedBox(height: 16),
          _buildSlider('Vignette', _vignette, 0.0, 1.0, Icons.center_focus_weak,
              (value) {
            setState(() => _vignette = value);
            _scheduleApply();
          }),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max,
      IconData icon, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTransformTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rotation
          _buildTransformSection(
            'Rotation',
            Icons.rotate_right,
            [
              _buildTransformButton(
                Icons.rotate_left,
                'Left',
                () {
                  setState(() => _rotation = (_rotation - 90) % 360);
                  _scheduleApply();
                },
              ),
              _buildTransformButton(
                Icons.rotate_right,
                'Right',
                () {
                  setState(() => _rotation = (_rotation + 90) % 360);
                  _scheduleApply();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Flip
          _buildTransformSection(
            'Flip',
            Icons.flip,
            [
              _buildTransformButton(
                Icons.flip,
                'Horizontal',
                () {
                  setState(() => _flipHorizontal = !_flipHorizontal);
                  _scheduleApply();
                },
                isActive: _flipHorizontal,
              ),
              _buildTransformButton(
                Icons.flip,
                'Vertical',
                () {
                  setState(() => _flipVertical = !_flipVertical);
                  _scheduleApply();
                },
                isActive: _flipVertical,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransformSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _buildTransformButton(
      IconData icon, String label, VoidCallback onPressed,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.white : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.crop,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Crop Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select the area you want to keep',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cropImage,
              icon: const Icon(Icons.crop_free),
              label: const Text('Open Crop Editor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cropImage() async {
    try {
      final croppedFile = await _enhancementService.cropImage(
        _currentImage,
        aspectRatio: widget.initialAspectRatio,
      );
      if (croppedFile != null && mounted) {
        setState(() {
          _currentImage = croppedFile;
          _originalImage = croppedFile;
        });
        _addToHistory(_createImageState());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _processingText = 'Saving image...';
      });

      // Apply any pending changes first
      if (_hasUnsavedChanges) {
        await _applyChanges();
      }

      // Save to app using document provider
      final documentProvider =
          Provider.of<DocumentProvider>(context, listen: false);

      // Generate a document name based on current date/time
      final now = DateTime.now();
      final documentName =
          'Edited_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

      // Create the document
      final document = await documentProvider.createDocument(
        name: documentName,
        imagePath: _currentImage.path,
        type: DocumentType.image,
      );

      // Save to gallery using SaverGallery after creating the document
      final galleryResult = await documentProvider
          .saveImageWithSaverGallery(File(_currentImage.path));
      if (galleryResult && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image downloaded to Gallery!'),
            backgroundColor: Colors.blue,
          ),
        );
        // Show system notification
        await NotificationService().showNotification(
          title: 'Image Saved',
          body: 'Your edited image has been saved to the gallery!',
        );
      } else if (!galleryResult && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download image to Gallery'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (document != null) {
          Navigator.pop(context, _currentImage);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyChangesForPdf() {
    // Pop and return the edited image file
    Navigator.pop(context, _currentImage);
  }

  void _saveImageToGallery() {
    // Placeholder: implement logic to save image to gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save Image to Gallery pressed!')),
    );
  }
}
