import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class Utils {
  // Date formatting
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Time formatting
  static String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  // Get document directory
  static Future<Directory> getDocumentDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  // Generate file path for saving images
  static Future<String> generateImagePath(String prefix) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$prefix-$timestamp.jpg';
  }

  // Generate a random filename for a document
  static String generateDocumentName() {
    final now = DateTime.now();
    return 'Document_${DateFormat('yyyyMMdd_HHmmss').format(now)}';
  }

  // Generate a file name for PDF
  static String generatePdfFileName(String documentName) {
    final sanitizedName = documentName.replaceAll(RegExp(r'[^\w\s-]'), '');
    return '${sanitizedName.trim().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  // Generate a file name for image
  static String generateImageFileName() {
    return 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  // Get directory for app documents
  static String getAppDirectoryPath(String path) {
    return path;
  }

  // Apply grayscale filter to an image
  static Future<File> applyGrayscaleFilter(String imagePath) async {
    final imageFile = File(imagePath);
    final originalImage = img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    final grayscaleImage = img.grayscale(originalImage);

    final outputPath = imagePath.replaceFirst('.jpg', '_gray.jpg');
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(grayscaleImage));

    return outputFile;
  }

  // Apply black and white filter to an image
  static Future<File> applyBlackAndWhiteFilter(String imagePath) async {
    final imageFile = File(imagePath);
    final originalImage = img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    // Apply grayscale first, then adjust contrast to create black and white effect
    final grayscaleImage = img.grayscale(originalImage);
    final bwImage = img.adjustColor(
      grayscaleImage,
      contrast: 2.0,
      brightness: 0.0,
    );

    final outputPath = imagePath.replaceFirst('.jpg', '_bw.jpg');
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(bwImage));

    return outputFile;
  }

  // Adjust image brightness and contrast
  static Future<File> adjustBrightnessContrast(
    String imagePath,
    double brightness, // Range: -1.0 to 1.0
    double contrast, // Range: -1.0 to 1.0
  ) async {
    final imageFile = File(imagePath);
    final originalImage = img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) {
      throw Exception('Failed to decode image');
    }

    final adjustedImage = img.adjustColor(
      originalImage,
      brightness: brightness * 100, // Convert to percentage
      contrast: contrast * 100, // Convert to percentage
    );

    final outputPath = imagePath.replaceFirst('.jpg', '_adjusted.jpg');
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(adjustedImage));

    return outputFile;
  }

  // Show a custom snackbar
  static void showSnackBar(BuildContext context, String message,
      {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show an error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  // Show a success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Show a loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Show a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(phone);
  }

  // Extract domain from URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  // Sanitize filename by removing invalid characters
  static String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^\w\s-.]'), '').trim();
  }

  // Generate a random string
  static String generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) => chars[random % chars.length])
        .join();
  }

  static Future<void> openFile(String filePath) async {
    await OpenFile.open(filePath);
  }
}
