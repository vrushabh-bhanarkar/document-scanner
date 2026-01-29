import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import '../core/utils.dart';

class FileService {
  // Get the application documents directory
  Future<Directory> getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  // Save an image file from a temporary path to application documents directory
  Future<String> saveImageToDocuments(String tempPath,
      {String? customName}) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final fileName = customName ?? Utils.generateImageFileName();
    final targetPath = path.join(documentsDir.path, fileName);

    // Copy the file
    final tempFile = File(tempPath);
    final savedFile = await tempFile.copy(targetPath);

    // Delete the temporary file if it still exists
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    return savedFile.path;
  }

  // Save image to the app documents directory
  Future<String> saveImage(File imageFile) async {
    try {
      final directory = await getAppDirectory();
      final fileName = Utils.generateImageFileName();
      final savedFile = await imageFile.copy('${directory.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }

  // Create a new directory in the documents folder
  Future<Directory> createDirectory(String directoryName) async {
    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final newDir = Directory(path.join(documentsDir.path, directoryName));

      if (!await newDir.exists()) {
        await newDir.create(recursive: true);
      }

      return newDir;
    } catch (e) {
      throw Exception('Failed to create directory: $e');
    }
  }

  // Create a temporary file for processing
  Future<File> createTempFile(Uint8List bytes,
      {String extension = 'jpg'}) async {
    try {
      final directory = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      throw Exception('Failed to create temporary file: $e');
    }
  }

  // List all files in a directory
  Future<List<FileSystemEntity>> listFiles(Directory directory) async {
    final entities = await directory.list().toList();
    return entities.where((entity) => entity is File).toList();
  }

  // Move a file to a different directory
  Future<File> moveFile(String sourcePath, Directory targetDir) async {
    final sourceFile = File(sourcePath);
    final fileName = path.basename(sourcePath);
    final targetPath = path.join(targetDir.path, fileName);

    // Copy and delete source (move)
    final newFile = await sourceFile.copy(targetPath);
    await sourceFile.delete();

    return newFile;
  }

  // Delete a file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Share a file
  Future<void> shareFile(String filePath, {String? text}) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: text);
  }

  // Get file size in a human-readable format
  Future<String> getFileSize(String filePath, {int decimals = 1}) async {
    final file = File(filePath);
    final bytes = await file.length();

    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor();

    return '${(bytes / math.pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // Get file size in KB
  Future<double> getFileSizeKB(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / 1024; // Convert to KB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
