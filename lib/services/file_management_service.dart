import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../models/document_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class FileManagementService {
  static const String _documentsBoxName = 'documents';
  static const String _foldersBoxName = 'folders';
  static const String _recentDownloadsBoxName = 'recent_downloads';
  static const _uuid = Uuid();

  late Box<DocumentModel> _documentsBox;
  late Box<String> _foldersBox;
  late Box<String> _recentDownloadsBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Hive is already initialized in main.dart

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(DocumentModelAdapter());
    }

    _documentsBox = await Hive.openBox<DocumentModel>(_documentsBoxName);
    _foldersBox = await Hive.openBox<String>(_foldersBoxName);
    _recentDownloadsBox = await Hive.openBox<String>(_recentDownloadsBoxName);

    _isInitialized = true;
  }

  /// Save a document to the app's documents directory
  Future<DocumentModel?> saveDocument({
    required File sourceFile,
    required String title,
    required DocumentType type,
    String? folderId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await initialize();

      final directory = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${directory.path}/documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Create unique filename
      final extension = _getFileExtension(sourceFile.path);
      final fileName = '${_sanitizeFileName(title)}_${_uuid.v4()}$extension';
      final destinationPath = '${documentsDir.path}/$fileName';

      // Copy file to documents directory
      final savedFile = await sourceFile.copy(destinationPath);

      // Create document model
      final document = DocumentModel(
        id: _uuid.v4(),
        name: title,
        imagePath: savedFile.path,
        type: type,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        folderId: folderId,
        metadata: metadata ?? {},
      );

      // Save to database
      await _documentsBox.put(document.id, document);

      return document;
    } catch (e) {
      print('Error saving document: $e');
      return null;
    }
  }

  /// Save a PDF document with multiple image paths
  Future<DocumentModel?> savePDFDocument({
    required String name,
    required String pdfPath,
    required List<String> imagePaths,
    String? folderId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await initialize();

      // Create document model
      final document = DocumentModel(
        id: _uuid.v4(),
        name: name,
        imagePath: imagePaths.isNotEmpty ? imagePaths.first : '',
        pdfPath: pdfPath,
        type: DocumentType.pdf,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        folderId: folderId,
        metadata: {
          ...metadata ?? {},
          'imagePaths': imagePaths,
          'pageCount': imagePaths.length,
        },
      );

      // Save to database
      await _documentsBox.put(document.id, document);

      return document;
    } catch (e) {
      print('Error saving PDF document: $e');
      return null;
    }
  }

  /// Get all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    await initialize();
    return _documentsBox.values.toList();
  }

  /// Get documents by folder
  Future<List<DocumentModel>> getDocumentsByFolder(String? folderId) async {
    await initialize();
    return _documentsBox.values
        .where((doc) => doc.folderId == folderId)
        .toList();
  }

  /// Get recent documents
  Future<List<DocumentModel>> getRecentDocuments({int limit = 10}) async {
    await initialize();
    final documents = _documentsBox.values.toList();
    documents.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return documents.take(limit).toList();
  }

  /// Search documents
  Future<List<DocumentModel>> searchDocuments(String query) async {
    await initialize();
    final lowercaseQuery = query.toLowerCase();
    return _documentsBox.values
        .where((doc) =>
            doc.name.toLowerCase().contains(lowercaseQuery) ||
            (doc.metadata['description']
                    ?.toString()
                    .toLowerCase()
                    .contains(lowercaseQuery) ??
                false))
        .toList();
  }

  /// Create a new folder
  Future<String> createFolder(String name, {String? parentId}) async {
    await initialize();
    final folderId = _uuid.v4();
    final folderData = json.encode({
      'id': folderId,
      'name': name,
      'parentId': parentId,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await _foldersBox.put(folderId, folderData);
    return folderId;
  }

  /// Get all folders
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    await initialize();
    return _foldersBox.values
        .map((folderJson) => json.decode(folderJson) as Map<String, dynamic>)
        .toList();
  }

  /// Rename document
  Future<bool> renameDocument(String documentId, String newTitle) async {
    try {
      await initialize();
      final document = _documentsBox.get(documentId);
      if (document == null) return false;

      final updatedDocument = document.copyWith(
        name: newTitle,
        modifiedAt: DateTime.now(),
      );

      await _documentsBox.put(documentId, updatedDocument);
      return true;
    } catch (e) {
      print('Error renaming document: $e');
      return false;
    }
  }

  /// Move document to folder
  Future<bool> moveDocumentToFolder(String documentId, String? folderId) async {
    try {
      await initialize();
      final document = _documentsBox.get(documentId);
      if (document == null) return false;

      final updatedDocument = document.copyWith(
        folderId: folderId,
        modifiedAt: DateTime.now(),
      );

      await _documentsBox.put(documentId, updatedDocument);
      return true;
    } catch (e) {
      print('Error moving document: $e');
      return false;
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String documentId) async {
    try {
      await initialize();
      final document = _documentsBox.get(documentId);
      if (document == null) return false;

      // Delete physical file
      final file = File(document.imagePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from database
      await _documentsBox.delete(documentId);
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  /// Share document
  Future<bool> shareDocument(DocumentModel document, {String? subject}) async {
    try {
      final file = File(document.filePath);
      if (!await file.exists()) return false;

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject ?? document.title,
        text: 'Sharing document: ${document.title}',
      );
      return true;
    } catch (e) {
      print('Error sharing document: $e');
      return false;
    }
  }

  /// Export document to external storage
  Future<String?> exportDocument(
      DocumentModel document, String destinationPath) async {
    try {
      final sourceFile = File(document.filePath);
      if (!await sourceFile.exists()) return null;

      final extension = _getFileExtension(document.filePath);
      final fileName = '${_sanitizeFileName(document.title)}$extension';
      final fullDestinationPath = '$destinationPath/$fileName';

      await sourceFile.copy(fullDestinationPath);
      return fullDestinationPath;
    } catch (e) {
      print('Error exporting document: $e');
      return null;
    }
  }

  /// Get document file size
  Future<int> getDocumentSize(DocumentModel document) async {
    try {
      final file = File(document.filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    await initialize();

    int totalFiles = 0;
    int totalSize = 0;
    int imageFiles = 0;
    int pdfFiles = 0;

    for (final document in _documentsBox.values) {
      totalFiles++;
      totalSize += await getDocumentSize(document);

      switch (document.type) {
        case DocumentType.image:
          imageFiles++;
          break;
        case DocumentType.pdf:
          pdfFiles++;
          break;
        case DocumentType.text:
          break;
      }
    }

    return {
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'imageFiles': imageFiles,
      'pdfFiles': pdfFiles,
      'folders': _foldersBox.length,
    };
  }

  /// Clean up orphaned files
  Future<int> cleanupOrphanedFiles() async {
    try {
      await initialize();
      final directory = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${directory.path}/documents');

      if (!await documentsDir.exists()) return 0;

      final allFiles = await documentsDir.list().toList();
      final documentPaths =
          _documentsBox.values.map((doc) => doc.filePath).toSet();

      int deletedCount = 0;
      for (final fileEntity in allFiles) {
        if (fileEntity is File && !documentPaths.contains(fileEntity.path)) {
          try {
            await fileEntity.delete();
            deletedCount++;
          } catch (e) {
            print('Error deleting orphaned file: $e');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up orphaned files: $e');
      return 0;
    }
  }

  /// Backup documents metadata
  Future<String?> exportDocumentsMetadata() async {
    try {
      await initialize();
      final documents = _documentsBox.values.toList();
      final folders = await getAllFolders();

      final backup = {
        'documents': documents.map((doc) => doc.toJson()).toList(),
        'folders': folders,
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File(
          '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(json.encode(backup));

      return backupFile.path;
    } catch (e) {
      print('Error exporting metadata: $e');
      return null;
    }
  }

  /// Get documents by type
  Future<List<DocumentModel>> getDocumentsByType(DocumentType type) async {
    await initialize();
    return _documentsBox.values.where((doc) => doc.type == type).toList();
  }

  /// Update document metadata
  Future<bool> updateDocumentMetadata(
      String documentId, Map<String, dynamic> metadata) async {
    try {
      await initialize();
      final document = _documentsBox.get(documentId);
      if (document == null) return false;

      final updatedDocument = document.copyWith(
        metadata: {...document.metadata, ...metadata},
        modifiedAt: DateTime.now(),
      );

      await _documentsBox.put(documentId, updatedDocument);
      return true;
    } catch (e) {
      print('Error updating document metadata: $e');
      return false;
    }
  }

  /// Check if document exists
  Future<bool> documentExists(String documentId) async {
    await initialize();
    final document = _documentsBox.get(documentId);
    if (document == null) return false;

    final file = File(document.filePath);
    return await file.exists();
  }

  /// Get file extension from path
  String _getFileExtension(String filePath) {
    return filePath.substring(filePath.lastIndexOf('.'));
  }

  /// Sanitize filename for safe storage
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _documentsBox.close();
      await _foldersBox.close();
      await _recentDownloadsBox.close();
      _isInitialized = false;
    }
  }

  /// Save file to gallery (images only)
  Future<bool> saveToGallery(File file) async {
    try {
      print('[saveToGallery] Called with file: ${file.path}');
      if (Platform.isAndroid) {
        const MethodChannel _channel =
            MethodChannel('com.sleekscan.documentscanner/files');
        final fileName = file.path.split('/').last;
        final bool? result = await _channel.invokeMethod('saveImageToGallery', {
          'filePath': file.path,
          'fileName': fileName,
        });
        if (result == true) {
          await addToRecentDownloads(fileName);
          return true;
        } else {
          print('MediaStore gallery save failed');
          return false;
        }
      } else {
        // For iOS and others, fallback to app directory
        final directory = await getApplicationDocumentsDirectory();
        final galleryDir = Directory('${directory.path}/gallery');
        if (!await galleryDir.exists()) {
          await galleryDir.create(recursive: true);
        }
        final fileName = file.path.split('/').last;
        final newPath = '${galleryDir.path}/$fileName';
        final copied = await file.copy(newPath);
        print(
            '[saveToGallery] Copied to: $newPath, exists: ${await copied.exists()}');
        await addToRecentDownloads(newPath);
        return true;
      }
    } catch (e) {
      print('Error saving to gallery: $e');
      return false;
    }
  }

  /// Save file to Downloads (images or PDFs)
  Future<bool> saveToDownloads(File file) async {
    try {
      print('[saveToDownloads] Called with file: ${file.path}');
      if (Platform.isAndroid) {
        const MethodChannel _channel =
            MethodChannel('com.sleekscan.documentscanner/files');
        final fileName = file.path.split('/').last;
        final String mimeType = fileName.toLowerCase().endsWith('.pdf')
            ? 'application/pdf'
            : 'image/jpeg';
        final bool? result =
            await _channel.invokeMethod('saveFileToDownloads', {
          'filePath': file.path,
          'fileName': fileName,
          'mimeType': mimeType,
        });
        if (result == true) {
          await addToRecentDownloads(fileName);
          return true;
        } else {
          print('MediaStore save failed');
          return false;
        }
      } else {
        // For iOS and others, fallback to app directory
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        final fileName = file.path.split('/').last;
        final newPath = '${downloadsDir.path}/$fileName';
        final copied = await file.copy(newPath);
        print(
            '[saveToDownloads] Copied to: $newPath, exists: ${await copied.exists()}');
        await addToRecentDownloads(newPath);
        return true;
      }
    } catch (e) {
      print('Error saving to downloads: $e');
      return false;
    }
  }

  /// Add file path to recent downloads
  Future<void> addToRecentDownloads(String filePath) async {
    await initialize();
    final now = DateTime.now().toIso8601String();
    print('[addToRecentDownloads] Adding: $filePath at $now');
    await _recentDownloadsBox.put(filePath, now);
    print(
        '[addToRecentDownloads] Current keys: \'${_recentDownloadsBox.keys}\'');
  }

  /// Get recent downloads (sorted by last modified date desc)
  Future<List<Map<String, dynamic>>> getRecentDownloads(
      {int limit = 20}) async {
    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      return [];
    }
    final files = downloadsDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files
        .take(limit)
        .map((file) => {
              'path': file.path,
              'modified': file.lastModifiedSync(),
            })
        .toList();
  }

  /// Delete a recent download (removes file and from list)
  Future<bool> deleteRecentDownload(String filePath) async {
    try {
      await initialize();
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _recentDownloadsBox.delete(filePath);
      return true;
    } catch (e) {
      print('Error deleting recent download: $e');
      return false;
    }
  }
}
