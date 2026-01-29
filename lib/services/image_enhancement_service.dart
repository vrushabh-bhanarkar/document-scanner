import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ImageFilter {
  none,
  blackAndWhite,
  grayscale,
  enhance,
  magicColor,
  sepia,
  vintage,
  cool,
  warm,
}

class ImageEnhancementService {
  static const _uuid = Uuid();

  /// Crop image using image_cropper package
  Future<File?> cropImage(File imageFile, {double? aspectRatio}) async {
    try {
      final shouldLockAspect = aspectRatio != null && aspectRatio > 0;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: shouldLockAspect
            ? CropAspectRatio(ratioX: aspectRatio, ratioY: 1.0)
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Document',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: shouldLockAspect,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Document',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  /// Crop image using custom corner points (polygon crop)
  Future<File?> cropImageWithCorners(
      File imageFile, List<Offset> corners) async {
    try {
      if (corners.length < 3) {
        print('Need at least 3 corners for cropping');
        return null;
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Convert corners to image coordinates
      final imageCorners = corners.map((corner) {
        return img.Point(
          corner.dx.round(),
          corner.dy.round(),
        );
      }).toList();

      // Calculate bounding box
      double minX = imageCorners[0].x.toDouble();
      double maxX = imageCorners[0].x.toDouble();
      double minY = imageCorners[0].y.toDouble();
      double maxY = imageCorners[0].y.toDouble();

      for (final corner in imageCorners) {
        minX = math.min(minX, corner.x.toDouble());
        maxX = math.max(maxX, corner.x.toDouble());
        minY = math.min(minY, corner.y.toDouble());
        maxY = math.max(maxY, corner.y.toDouble());
      }

      // Ensure bounds are within image
      minX = math.max(0, minX);
      maxX = math.min(image.width - 1, maxX);
      minY = math.max(0, minY);
      maxY = math.min(image.height - 1, maxY);

      // Crop the image using the bounding box
      final croppedImage = img.copyCrop(
        image,
        x: minX.round(),
        y: minY.round(),
        width: (maxX - minX).round(),
        height: (maxY - minY).round(),
      );

      return await _saveImage(croppedImage, 'polygon_cropped');
    } catch (e) {
      print('Error cropping image with corners: $e');
      return null;
    }
  }

  /// Rotate image by specified degrees
  Future<File?> rotateImage(File imageFile, int degrees) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image rotatedImage;
      switch (degrees) {
        case 90:
          rotatedImage = img.copyRotate(image, angle: 90);
          break;
        case 180:
          rotatedImage = img.copyRotate(image, angle: 180);
          break;
        case 270:
          rotatedImage = img.copyRotate(image, angle: 270);
          break;
        default:
          rotatedImage = img.copyRotate(image, angle: degrees.toDouble());
      }

      return await _saveImage(rotatedImage, 'rotated');
    } catch (e) {
      print('Error rotating image: $e');
      return null;
    }
  }

  /// Flip image horizontally or vertically
  Future<File?> flipImage(File imageFile, {bool horizontal = true}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final flippedImage =
          horizontal ? img.flipHorizontal(image) : img.flipVertical(image);

      return await _saveImage(
        flippedImage,
        horizontal ? 'flipped_h' : 'flipped_v',
      );
    } catch (e) {
      print('Error flipping image: $e');
      return null;
    }
  }

  /// Apply various filters to the image
  Future<File?> applyFilter(File imageFile, ImageFilter filter) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image filteredImage;

      switch (filter) {
        case ImageFilter.none:
          filteredImage = image;
          break;
        case ImageFilter.blackAndWhite:
          filteredImage = _applyBlackAndWhiteFilter(image);
          break;
        case ImageFilter.grayscale:
          filteredImage = img.grayscale(image);
          break;
        case ImageFilter.enhance:
          filteredImage = _applyEnhanceFilter(image);
          break;
        case ImageFilter.magicColor:
          filteredImage = _applyMagicColorFilter(image);
          break;
        case ImageFilter.sepia:
          filteredImage = img.sepia(image);
          break;
        case ImageFilter.vintage:
          filteredImage = _applyVintageFilter(image);
          break;
        case ImageFilter.cool:
          filteredImage = _applyCoolFilter(image);
          break;
        case ImageFilter.warm:
          filteredImage = _applyWarmFilter(image);
          break;
      }

      return await _saveImage(filteredImage, 'filtered_${filter.name}');
    } catch (e) {
      print('Error applying filter: $e');
      return null;
    }
  }

  /// Apply black and white filter with threshold
  img.Image _applyBlackAndWhiteFilter(img.Image image) {
    final grayscale = img.grayscale(image);
    const threshold = 128;

    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final gray = pixel.r;
        final newValue = gray > threshold ? 255 : 0;
        grayscale.setPixelRgb(x, y, newValue, newValue, newValue);
      }
    }

    return grayscale;
  }

  /// Enhance image contrast and brightness
  img.Image _applyEnhanceFilter(img.Image image) {
    // Increase contrast and adjust brightness
    final enhanced = img.adjustColor(
      image,
      contrast: 1.2,
      brightness: 1.1,
      saturation: 1.1,
    );

    // Apply sharpening filter
    return _applySharpeningFilter(enhanced);
  }

  /// Apply sharpening filter manually
  img.Image _applySharpeningFilter(img.Image image) {
    final sharpened = img.Image.from(image);
    final kernel = [
      0,
      -1,
      0,
      -1,
      5,
      -1,
      0,
      -1,
      0,
    ];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double r = 0, g = 0, b = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final weight = kernel[(ky + 1) * 3 + (kx + 1)];
            r += pixel.r * weight;
            g += pixel.g * weight;
            b += pixel.b * weight;
          }
        }

        sharpened.setPixelRgb(
          x,
          y,
          r.clamp(0, 255).toInt(),
          g.clamp(0, 255).toInt(),
          b.clamp(0, 255).toInt(),
        );
      }
    }

    return sharpened;
  }

  /// Apply magic color enhancement
  img.Image _applyMagicColorFilter(img.Image image) {
    return img.adjustColor(
      image,
      contrast: 1.3,
      brightness: 1.05,
      saturation: 1.4,
      gamma: 0.9,
      hue: 5,
    );
  }

  /// Apply vintage filter
  img.Image _applyVintageFilter(img.Image image) {
    // Apply sepia tone
    final sepia = img.sepia(image);

    // Add vintage color adjustments
    return img.adjustColor(
      sepia,
      contrast: 0.9,
      brightness: 0.95,
      saturation: 0.8,
    );
  }

  /// Apply cool filter (blue tint)
  img.Image _applyCoolFilter(img.Image image) {
    final cool = img.Image.from(image);

    for (int y = 0; y < cool.height; y++) {
      for (int x = 0; x < cool.width; x++) {
        final pixel = cool.getPixel(x, y);
        final r = (pixel.r * 0.8).round().clamp(0, 255);
        final g = (pixel.g * 0.9).round().clamp(0, 255);
        final b = (pixel.b * 1.2).round().clamp(0, 255);
        cool.setPixelRgb(x, y, r, g, b);
      }
    }

    return cool;
  }

  /// Apply warm filter (orange tint)
  img.Image _applyWarmFilter(img.Image image) {
    final warm = img.Image.from(image);

    for (int y = 0; y < warm.height; y++) {
      for (int x = 0; x < warm.width; x++) {
        final pixel = warm.getPixel(x, y);
        final r = (pixel.r * 1.2).round().clamp(0, 255);
        final g = (pixel.g * 1.1).round().clamp(0, 255);
        final b = (pixel.b * 0.8).round().clamp(0, 255);
        warm.setPixelRgb(x, y, r, g, b);
      }
    }

    return warm;
  }

  /// Adjust image brightness
  Future<File?> adjustBrightness(File imageFile, double brightness) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final adjustedImage = img.adjustColor(image, brightness: brightness);
      return await _saveImage(adjustedImage, 'brightness_adjusted');
    } catch (e) {
      print('Error adjusting brightness: $e');
      return null;
    }
  }

  /// Adjust image contrast
  Future<File?> adjustContrast(File imageFile, double contrast) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final adjustedImage = img.adjustColor(image, contrast: contrast);
      return await _saveImage(adjustedImage, 'contrast_adjusted');
    } catch (e) {
      print('Error adjusting contrast: $e');
      return null;
    }
  }

  /// Adjust image saturation
  Future<File?> adjustSaturation(File imageFile, double saturation) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final adjustedImage = img.adjustColor(image, saturation: saturation);
      return await _saveImage(adjustedImage, 'saturation_adjusted');
    } catch (e) {
      print('Error adjusting saturation: $e');
      return null;
    }
  }

  /// Compress image to reduce file size
  Future<File?> compressImage(
    File imageFile, {
    int quality = 85,
    int? minWidth,
    int? minHeight,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final targetPath = '${directory.path}/compressed_${_uuid.v4()}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth ?? 1024,
        minHeight: minHeight ?? 1024,
      );

      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  /// Apply multiple enhancements in sequence
  Future<File?> applyEnhancements(
    File imageFile, {
    int? rotation,
    bool? flipHorizontal,
    bool? flipVertical,
    ImageFilter? filter,
    double? brightness,
    double? contrast,
    double? saturation,
    bool compress = true,
  }) async {
    File currentFile = imageFile;

    try {
      // Apply rotation
      if (rotation != null && rotation != 0) {
        final rotated = await rotateImage(currentFile, rotation);
        if (rotated != null) currentFile = rotated;
      }

      // Apply horizontal flip
      if (flipHorizontal == true) {
        final flipped = await flipImage(currentFile, horizontal: true);
        if (flipped != null) currentFile = flipped;
      }

      // Apply vertical flip
      if (flipVertical == true) {
        final flipped = await flipImage(currentFile, horizontal: false);
        if (flipped != null) currentFile = flipped;
      }

      // Apply filter
      if (filter != null && filter != ImageFilter.none) {
        final filtered = await applyFilter(currentFile, filter);
        if (filtered != null) currentFile = filtered;
      }

      // Apply brightness adjustment
      if (brightness != null && brightness != 1.0) {
        final adjusted = await adjustBrightness(currentFile, brightness);
        if (adjusted != null) currentFile = adjusted;
      }

      // Apply contrast adjustment
      if (contrast != null && contrast != 1.0) {
        final adjusted = await adjustContrast(currentFile, contrast);
        if (adjusted != null) currentFile = adjusted;
      }

      // Apply saturation adjustment
      if (saturation != null && saturation != 1.0) {
        final adjusted = await adjustSaturation(currentFile, saturation);
        if (adjusted != null) currentFile = adjusted;
      }

      // Compress if requested
      if (compress) {
        final compressed = await compressImage(currentFile);
        if (compressed != null) currentFile = compressed;
      }

      return currentFile;
    } catch (e) {
      print('Error applying enhancements: $e');
      return null;
    }
  }

  /// Save image to temporary directory
  Future<File> _saveImage(img.Image image, String prefix) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${prefix}_${_uuid.v4()}.jpg');
    final bytes = img.encodeJpg(image, quality: 90);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Get filter preview (smaller image for UI)
  Future<Uint8List?> getFilterPreview(
    File imageFile,
    ImageFilter filter, {
    int maxSize = 200,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize for preview
      final resized = img.copyResize(
        image,
        width: maxSize,
        height: maxSize,
        maintainAspect: true,
      );

      // Apply filter
      img.Image filtered;
      switch (filter) {
        case ImageFilter.none:
          filtered = resized;
          break;
        case ImageFilter.blackAndWhite:
          filtered = _applyBlackAndWhiteFilter(resized);
          break;
        case ImageFilter.grayscale:
          filtered = img.grayscale(resized);
          break;
        case ImageFilter.enhance:
          filtered = _applyEnhanceFilter(resized);
          break;
        case ImageFilter.magicColor:
          filtered = _applyMagicColorFilter(resized);
          break;
        case ImageFilter.sepia:
          filtered = img.sepia(resized);
          break;
        case ImageFilter.vintage:
          filtered = _applyVintageFilter(resized);
          break;
        case ImageFilter.cool:
          filtered = _applyCoolFilter(resized);
          break;
        case ImageFilter.warm:
          filtered = _applyWarmFilter(resized);
          break;
      }

      return Uint8List.fromList(img.encodeJpg(filtered, quality: 80));
    } catch (e) {
      print('Error generating filter preview: $e');
      return null;
    }
  }
}
