import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

/// Result returned from the Signature Screen
class SignatureResult {
  final Uint8List signatureBytes;
  final File? stampedDocumentFile;

  SignatureResult({
    required this.signatureBytes,
    this.stampedDocumentFile,
  });
}

/// 100% OFFLINE Digital E-Signature Drawer Screen
/// - Provides a high-resolution, smooth signature canvas on a transparent background
/// - Allows pen color and stroke width adjustment
/// - Exports signature as PNG bytes
/// - If a document image is passed, provides an interactive stamp overlay workflow
class SignatureScreen extends StatefulWidget {
  final File? documentImage;

  const SignatureScreen({
    super.key,
    this.documentImage,
  });

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  late SignatureController _controller;
  Color _penColor = Colors.black;
  double _strokeWidth = 3.0;

  // Stamping mode states
  bool _isStampingMode = false;
  Uint8List? _exportedSignature;
  Offset _stampPosition = const Offset(0.6, 0.75); // Normalized 0..1
  final double _stampScale = 0.35; // Fraction of document width
  bool _isProcessing = false;

  final List<Color> _availableColors = [
    Colors.black,
    const Color(0xFF0D47A1), // Deep Blue
    const Color(0xFFB71C1C), // Deep Red
    const Color(0xFF1B5E20), // Forest Green
  ];

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _penColor,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPenColor(Color color) {
    if (_penColor == color) return;
    final points = _controller.points;
    _controller.dispose();
    setState(() {
      _penColor = color;
      _controller = SignatureController(
        penStrokeWidth: _strokeWidth,
        penColor: _penColor,
        exportBackgroundColor: Colors.transparent,
        points: points,
      );
    });
  }

  void _setStrokeWidth(double width) {
    if (_strokeWidth == width) return;
    final points = _controller.points;
    _controller.dispose();
    setState(() {
      _strokeWidth = width;
      _controller = SignatureController(
        penStrokeWidth: _strokeWidth,
        penColor: _penColor,
        exportBackgroundColor: Colors.transparent,
        points: points,
      );
    });
  }

  Future<void> _handleConfirmSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature first.')),
      );
      return;
    }

    final pngBytes = await _controller.toPngBytes();
    if (pngBytes == null || pngBytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export signature image.')),
      );
      return;
    }

    if (widget.documentImage != null) {
      // Transition to interactive document stamping overlay
      setState(() {
        _exportedSignature = pngBytes;
        _isStampingMode = true;
      });
    } else {
      // Standalone mode: return raw signature PNG bytes
      Navigator.of(context).pop(SignatureResult(signatureBytes: pngBytes));
    }
  }

  Future<void> _applyStampAndFinish() async {
    if (_exportedSignature == null || widget.documentImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final stampedFile = await _compositeSignatureOntoDocument(
        baseImageFile: widget.documentImage!,
        signatureBytes: _exportedSignature!,
        relX: _stampPosition.dx,
        relY: _stampPosition.dy,
        widthRatio: _stampScale,
      );

      if (!mounted) return;
      Navigator.of(context).pop(
        SignatureResult(
          signatureBytes: _exportedSignature!,
          stampedDocumentFile: stampedFile,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stamp signature: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 100% Offline compositing using package:image
  Future<File> _compositeSignatureOntoDocument({
    required File baseImageFile,
    required Uint8List signatureBytes,
    required double relX,
    required double relY,
    required double widthRatio,
  }) async {
    final docBytes = await baseImageFile.readAsBytes();
    final docImage = img.decodeImage(docBytes);
    if (docImage == null) {
      throw Exception('Unable to decode document image.');
    }

    final sigImage = img.decodeImage(signatureBytes);
    if (sigImage == null) {
      throw Exception('Unable to decode signature PNG bytes.');
    }

    // Proportional resize of signature
    final targetWidth =
        (docImage.width * widthRatio).toInt().clamp(50, docImage.width);
    final targetHeight = ((targetWidth / sigImage.width) * sigImage.height)
        .toInt()
        .clamp(20, docImage.height);

    final resizedSig = img.copyResize(
      sigImage,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // Compute pixel coordinates
    final posX = (docImage.width * relX).toInt().clamp(
          0,
          docImage.width - targetWidth,
        );
    final posY = (docImage.height * relY).toInt().clamp(
          0,
          docImage.height - targetHeight,
        );

    // Composite signature onto document image
    final composited = img.compositeImage(
      docImage,
      resizedSig,
      dstX: posX,
      dstY: posY,
    );

    final encodedJpg = Uint8List.fromList(img.encodeJpg(composited, quality: 92));

    final tempDir = await getTemporaryDirectory();
    final stampedFile = File(
      '${tempDir.path}/stamped_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await stampedFile.writeAsBytes(encodedJpg);

    return stampedFile;
  }

  @override
  Widget build(BuildContext context) {
    if (_isStampingMode) {
      return _buildStampingOverlayUI();
    }
    return _buildDrawingCanvasUI();
  }

  /// Canvas drawing UI
  Widget _buildDrawingCanvasUI() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.documentImage != null
            ? 'Sign Document'
            : 'Digital E-Signature'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: 'Undo stroke',
            icon: const Icon(Icons.undo),
            onPressed: () {
              if (_controller.isNotEmpty) {
                final points = List<Point>.from(_controller.points);
                if (points.isNotEmpty) {
                  // Remove points from last stroke
                  points.removeLast();
                  _controller.dispose();
                  setState(() {
                    _controller = SignatureController(
                      penStrokeWidth: _strokeWidth,
                      penColor: _penColor,
                      exportBackgroundColor: Colors.transparent,
                      points: points,
                    );
                  });
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Clear canvas',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _controller.clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Draw your signature below on the transparent canvas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Signature drawing area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Subtle watermark guide line
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 40,
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Positioned(
                        left: 24,
                        bottom: 18,
                        child: Text(
                          'Sign above line (Transparent background)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      Signature(
                        controller: _controller,
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Controls toolbar (Colors & Stroke widths)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color selection row
                  Row(
                    children: [
                      const Text(
                        'Ink Color:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ..._availableColors.map((color) {
                        final isSelected = _penColor == color;
                        return GestureDetector(
                          onTap: () => _setPenColor(color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Stroke width selector
                      DropdownButton<double>(
                        value: _strokeWidth,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.line_weight, size: 20),
                        items: const [
                          DropdownMenuItem(value: 2.0, child: Text('Fine (2px)')),
                          DropdownMenuItem(value: 3.5, child: Text('Medium (3.5px)')),
                          DropdownMenuItem(value: 5.5, child: Text('Thick (5.5px)')),
                        ],
                        onChanged: (val) {
                          if (val != null) _setStrokeWidth(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052D4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            widget.documentImage != null
                                ? 'Next: Position on Doc'
                                : 'Save Signature',
                          ),
                          onPressed: _handleConfirmSignature,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stamping & Placement Overlay UI
  Widget _buildStampingOverlayUI() {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        title: const Text('Position Signature Stamp'),
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _isStampingMode = false);
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: _isProcessing ? null : _applyStampAndFinish,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Apply',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: const Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.amber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag signature to position on document.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Document preview
                        Image.file(
                          widget.documentImage!,
                          fit: BoxFit.contain,
                        ),

                        // Interactive Draggable Signature
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (ctx, overlayConstraints) {
                              final left =
                                  overlayConstraints.maxWidth * _stampPosition.dx;
                              final top =
                                  overlayConstraints.maxHeight * _stampPosition.dy;
                              final sigWidth =
                                  overlayConstraints.maxWidth * _stampScale;

                              return Stack(
                                children: [
                                  Positioned(
                                    left: left,
                                    top: top,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          final newX = (left + details.delta.dx) /
                                              overlayConstraints.maxWidth;
                                          final newY = (top + details.delta.dy) /
                                              overlayConstraints.maxHeight;
                                          _stampPosition = Offset(
                                            newX.clamp(0.0, 0.8),
                                            newY.clamp(0.0, 0.85),
                                          );
                                        });
                                      },
                                      child: Container(
                                        width: sigWidth,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.blueAccent,
                                            width: 1.5,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                        child: Image.memory(
                                          _exportedSignature!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom quick position controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () {
                    setState(() => _stampPosition = const Offset(0.08, 0.80));
                  },
                  child: const Text('Bottom Left'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () {
                    setState(() => _stampPosition = const Offset(0.35, 0.80));
                  },
                  child: const Text('Bottom Center'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: () {
                    setState(() => _stampPosition = const Offset(0.60, 0.80));
                  },
                  child: const Text('Bottom Right'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
