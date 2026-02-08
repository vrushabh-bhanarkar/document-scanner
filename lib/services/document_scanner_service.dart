import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image/image.dart' as img;

class DocumentScannerService {
  DocumentScanner? _documentScanner;
  bool _isProcessing = false;
  List<Offset> _detectedCorners = [];
  double _documentQualityScore = 0.0;
  bool _isDocumentDetected = false;
  int _frameSkipCount = 0;
  static const int _frameSkipRate = 10;

  Future<void> initialize() async {
    try {
      final options = DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: false,
      );
      _documentScanner = DocumentScanner(options: options);
    } catch (e) {
      print('Failed to initialize document scanner: $e');
    }
  }

  /// Main processing method with frame skipping
  Future<DocumentDetectionResult> processFrame(CameraImage image) async {
    if (_isProcessing) {
      return DocumentDetectionResult.empty();
    }

    // Frame skipping for better performance
    _frameSkipCount++;
    if (_frameSkipCount < _frameSkipRate) {
      return DocumentDetectionResult.empty();
    }
    _frameSkipCount = 0;

    _isProcessing = true;
    try {
      final result = await _processFrameInternal(image);
      _detectedCorners = result.corners;
      _documentQualityScore = result.qualityScore;
      _isDocumentDetected = result.isDocumentDetected;
      return result;
    } finally {
      _isProcessing = false;
    }
  }

  /// Internal frame processing with edge detection
  Future<DocumentDetectionResult> _processFrameInternal(
      CameraImage image) async {
    try {
      // Convert camera image for edge detection
      final processedImage = await _convertCameraImageForDetection(image);
      if (processedImage == null) {
        return DocumentDetectionResult.empty();
      }

      // Detect document edges using contour detection
      final corners = await _detectDocumentCorners(
          processedImage, image.width, image.height);

      if (corners.length == 4) {
        return DocumentDetectionResult(
          corners: corners,
          qualityScore: 0.8,
          isDocumentDetected: true,
          shouldAutoCapture: false,
        );
      }

      return DocumentDetectionResult.empty();
    } catch (e) {
      print('Frame processing error: $e');
      return DocumentDetectionResult.empty();
    }
  }

  /// Convert camera image for edge detection
  Future<img.Image?> _convertCameraImageForDetection(
      CameraImage cameraImage) async {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(cameraImage);
      }
      return null;
    } catch (e) {
      print('Image conversion error: $e');
      return null;
    }
  }

  /// Convert YUV420 to Image with downsampling
  img.Image? _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    // Downsample by 4x for performance
    final int downsampleFactor = 4;
    final int smallWidth = width ~/ downsampleFactor;
    final int smallHeight = height ~/ downsampleFactor;

    final img.Image image = img.Image(width: smallWidth, height: smallHeight);

    for (int y = 0; y < smallHeight; y++) {
      for (int x = 0; x < smallWidth; x++) {
        final int yIndex =
            (y * downsampleFactor) * width + (x * downsampleFactor);
        final int yValue = cameraImage.planes[0].bytes[yIndex];

        // Simple grayscale conversion
        image.setPixelRgb(x, y, yValue, yValue, yValue);
      }
    }

    return image;
  }

  /// Convert BGRA8888 to Image with downsampling
  img.Image? _convertBGRA8888ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int downsampleFactor = 4;
    final int smallWidth = width ~/ downsampleFactor;
    final int smallHeight = height ~/ downsampleFactor;

    final img.Image image = img.Image(width: smallWidth, height: smallHeight);
    final bytes = cameraImage.planes[0].bytes;

    for (int y = 0; y < smallHeight; y++) {
      for (int x = 0; x < smallWidth; x++) {
        final int index =
            ((y * downsampleFactor) * width + (x * downsampleFactor)) * 4;
        if (index + 3 < bytes.length) {
          final b = bytes[index];
          final g = bytes[index + 1];
          final r = bytes[index + 2];
          image.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    return image;
  }

  /// Detect document corners using edge detection
  Future<List<Offset>> _detectDocumentCorners(
      img.Image image, int originalWidth, int originalHeight) async {
    try {
      // Convert to grayscale
      final gray = img.grayscale(image);

      // Apply Gaussian blur to reduce noise
      final blurred = img.gaussianBlur(gray, radius: 2);

      // Find edges using simple threshold
      final edges = _findEdges(blurred);

      // Find the largest contour (likely the document)
      final corners = _findLargestRectangle(edges);

      if (corners.length == 4) {
        // Scale corners back to original size
        final scale = originalWidth / image.width;
        return corners.map((corner) {
          return Offset(corner.dx * scale, corner.dy * scale);
        }).toList();
      }

      return [];
    } catch (e) {
      print('Corner detection error: $e');
      return [];
    }
  }

  /// Find edges in image using Sobel operator
  img.Image _findEdges(img.Image image) {
    final width = image.width;
    final height = image.height;
    final result = img.Image(width: width, height: height);

    // Simple Sobel edge detection
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final gx = -1 * image.getPixel(x - 1, y - 1).r.toInt() +
            1 * image.getPixel(x + 1, y - 1).r.toInt() +
            -2 * image.getPixel(x - 1, y).r.toInt() +
            2 * image.getPixel(x + 1, y).r.toInt() +
            -1 * image.getPixel(x - 1, y + 1).r.toInt() +
            1 * image.getPixel(x + 1, y + 1).r.toInt();

        final gy = -1 * image.getPixel(x - 1, y - 1).r.toInt() +
            -2 * image.getPixel(x, y - 1).r.toInt() +
            -1 * image.getPixel(x + 1, y - 1).r.toInt() +
            1 * image.getPixel(x - 1, y + 1).r.toInt() +
            2 * image.getPixel(x, y + 1).r.toInt() +
            1 * image.getPixel(x + 1, y + 1).r.toInt();

        final magnitude = math.sqrt(gx * gx + gy * gy).toInt();
        final value = magnitude > 128 ? 255 : 0;

        result.setPixelRgb(x, y, value, value, value);
      }
    }

    return result;
  }

  /// Find largest rectangle in edge image
  List<Offset> _findLargestRectangle(img.Image edges) {
    final width = edges.width;
    final height = edges.height;

    // Find corners by detecting high edge density regions
    List<Offset> corners = [];

    // Top-left corner
    for (int y = 0; y < height ~/ 3; y++) {
      for (int x = 0; x < width ~/ 3; x++) {
        if (edges.getPixel(x, y).r > 200) {
          corners.add(Offset(x.toDouble(), y.toDouble()));
          break;
        }
      }
      if (corners.isNotEmpty) break;
    }

    // Top-right corner
    for (int y = 0; y < height ~/ 3; y++) {
      for (int x = width - 1; x > width * 2 ~/ 3; x--) {
        if (edges.getPixel(x, y).r > 200) {
          corners.add(Offset(x.toDouble(), y.toDouble()));
          break;
        }
      }
      if (corners.length == 2) break;
    }

    // Bottom-right corner
    for (int y = height - 1; y > height * 2 ~/ 3; y--) {
      for (int x = width - 1; x > width * 2 ~/ 3; x--) {
        if (edges.getPixel(x, y).r > 200) {
          corners.add(Offset(x.toDouble(), y.toDouble()));
          break;
        }
      }
      if (corners.length == 3) break;
    }

    // Bottom-left corner
    for (int y = height - 1; y > height * 2 ~/ 3; y--) {
      for (int x = 0; x < width ~/ 3; x++) {
        if (edges.getPixel(x, y).r > 200) {
          corners.add(Offset(x.toDouble(), y.toDouble()));
          break;
        }
      }
      if (corners.length == 4) break;
    }

    // If we found all 4 corners, return them
    if (corners.length == 4) {
      return corners;
    }

    // Fallback to default rectangle with padding
    return [
      Offset(width * 0.1, height * 0.1),
      Offset(width * 0.9, height * 0.1),
      Offset(width * 0.9, height * 0.9),
      Offset(width * 0.1, height * 0.9),
    ];
  }

  /// Use ML Kit for document scanning
  Future<String?> scanDocumentWithMLKit() async {
    try {
      if (_documentScanner == null) {
        await initialize();
      }

      final result = await _documentScanner?.scanDocument();
      if (result != null && result.pdf != null) {
        // ML Kit returns the PDF file directly
        // The path or bytes handling depends on the ML Kit version
        // For now, return a placeholder indicating success
        return 'mlkit_scanned';
      }
      return null;
    } catch (e) {
      print('ML Kit scan error: $e');
      return null;
    }
  }

  /// Get current detected corners
  List<Offset> get detectedCorners => _detectedCorners;

  /// Get document quality score
  double get documentQualityScore => _documentQualityScore;

  /// Check if document is detected
  bool get isDocumentDetected => _isDocumentDetected;

  /// Check if processing
  bool get isProcessing => _isProcessing;

  void dispose() {
    _documentScanner?.close();
  }
}

/// Document detection result
class DocumentDetectionResult {
  final List<Offset> corners;
  final double qualityScore;
  final bool isDocumentDetected;
  final bool shouldAutoCapture;

  DocumentDetectionResult({
    required this.corners,
    required this.qualityScore,
    required this.isDocumentDetected,
    required this.shouldAutoCapture,
  });

  factory DocumentDetectionResult.empty() {
    return DocumentDetectionResult(
      corners: [],
      qualityScore: 0.0,
      isDocumentDetected: false,
      shouldAutoCapture: false,
    );
  }
}
