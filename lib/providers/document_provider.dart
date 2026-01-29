import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/document_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../services/scan_quota_service.dart';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class DocumentProvider extends ChangeNotifier {
  List<DocumentModel> _documents = [];
  List<DocumentModel> get documents => _documents;

  // Current document being worked on
  DocumentModel? _currentDocument;
  DocumentModel? get currentDocument => _currentDocument;

  // Currently selected image path (for camera capture)
  String? _currentImagePath;
  String? get currentImagePath => _currentImagePath;

  // Multi-page scanning
  List<String> _currentPages = [];
  List<String> get currentPages => _currentPages;

  late CameraController _cameraController;
  bool _isCameraInitialized = false;

  DocumentProvider();

  // Helper method to safely call notifyListeners
  void _safeNotifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // We're in the build phase, defer the notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      // Safe to call immediately
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    await _openBox();
    await _loadDocuments();
  }

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen('documents')) {
      await Hive.openBox<DocumentModel>('documents');
    }
  }

  Future<void> _loadDocuments() async {
    final box = Hive.box<DocumentModel>('documents');
    _documents = box.values.toList();
    _safeNotifyListeners();
  }

  Future<void> loadDocuments() async {
    await _loadDocuments();
  }

  Future<void> setCurrentImagePath(String path) async {
    _currentImagePath = path;
    _safeNotifyListeners();
  }

  Future<void> addPage(String imagePath) async {
    _currentPages.add(imagePath);
    _safeNotifyListeners();
  }

  Future<void> removePage(int index) async {
    if (index >= 0 && index < _currentPages.length) {
      final path = _currentPages.removeAt(index);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _safeNotifyListeners();
    }
  }

  Future<DocumentModel> createDocument({
    required String name,
    required String imagePath,
    String? pdfPath,
    String? extractedText,
    List<String>? pageImagePaths,
    DocumentType? type,
  }) async {
    final quota = ScanQuotaService();
    final allowed = await quota.canCreateDocument();
    if (!allowed) {
      throw StateError('Free scan limit reached. Please subscribe to continue scanning.');
    }

    final id = const Uuid().v4();
    final document = DocumentModel(
      id: id,
      name: name,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      type: type ?? (pdfPath != null ? DocumentType.pdf : DocumentType.image),
      pdfPath: pdfPath,
      extractedText: extractedText,
      pageImagePaths: pageImagePaths ?? _currentPages,
    );

    final box = Hive.box<DocumentModel>('documents');
    await box.put(id, document);

    _documents.add(document);
    _currentDocument = document;
    _currentPages = [];
    _safeNotifyListeners();

    // Increment scan count after successful creation
    await quota.incrementScanCount();

    return document;
  }

  Future<void> updateDocument(DocumentModel document) async {
    final box = Hive.box<DocumentModel>('documents');
    await box.put(document.id, document);

    final index = _documents.indexWhere((d) => d.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      _safeNotifyListeners();
    }
  }

  Future<void> deleteDocument(String id) async {
    final box = Hive.box<DocumentModel>('documents');
    final document = box.get(id);

    if (document != null) {
      // Delete the image file
      final imageFile = File(document.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      // Delete PDF if exists
      if (document.pdfPath != null) {
        final pdfFile = File(document.pdfPath!);
        if (await pdfFile.exists()) {
          await pdfFile.delete();
        }
      }

      // Delete additional pages if any
      if (document.pageImagePaths != null) {
        for (final pagePath in document.pageImagePaths!) {
          final pageFile = File(pagePath);
          if (await pageFile.exists()) {
            await pageFile.delete();
          }
        }
      }

      // Remove from Hive
      await box.delete(id);

      // Remove from list
      _documents.removeWhere((d) => d.id == id);
      _safeNotifyListeners();
    }
  }

  void setCurrentDocument(DocumentModel document) {
    _currentDocument = document;
    _safeNotifyListeners();
  }

  void clearCurrentDocument() {
    _currentDocument = null;
    _currentImagePath = null;
    _currentPages = [];
    _safeNotifyListeners();
  }

  // Get documents sorted by date
  List<DocumentModel> getDocumentsSorted({bool descending = true}) {
    final sorted = List<DocumentModel>.from(_documents);
    sorted.sort((a, b) => descending
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // Search documents by name
  List<DocumentModel> searchDocuments(String query) {
    if (query.isEmpty) return _documents;

    return _documents
        .where((doc) =>
            doc.name.toLowerCase().contains(query.toLowerCase()) ||
            (doc.extractedText != null &&
                doc.extractedText!.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  Future<void> _scanFile(String path) async {
    const MethodChannel _channel =
        MethodChannel('document_scanner/media_scanner');
    try {
      await _channel.invokeMethod('scanFile', {'path': path});
    } catch (e) {
      print('Error scanning file: $e');
    }
  }

  Future<bool> saveToGallery(File file) async {
    try {
      print('saveToGallery: Attempting to save file: ${file.path}');
      if (!await file.exists()) {
        print('saveToGallery: Source file does not exist!');
        return false;
      }

      // Request permission
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        print('saveToGallery: Permission status: $status');
        if (!status.isGranted) {
          print(
              'Storage permission is required to save images to the gallery.');
          return false;
        }
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
      }

      // Get Pictures directory
      String newPath = '/storage/emulated/0/Pictures/DocumentScanner';
      Directory galleryDir = Directory(newPath);
      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
        print('saveToGallery: Created directory $newPath');
      }

      // Copy file
      String fileName = file.path.split('/').last;
      String savedPath = '${galleryDir.path}/$fileName';
      print('saveToGallery: Copying to $savedPath');
      File copied = await file.copy(savedPath);

      print('saveToGallery: File copied, exists: ${await copied.exists()}');

      // Notify media scanner
      const MethodChannel _channel =
          MethodChannel('document_scanner/media_scanner');
      await _channel.invokeMethod('scanFile', {'path': savedPath});
      print('saveToGallery: Media scanner notified for $savedPath');

      return true;
    } catch (e) {
      print('Error saving to gallery: $e');
      return false;
    }
  }

  Future<bool> saveToDownloads(File file) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) return false;
      }
      String newPath = '/storage/emulated/0/Download/DocumentScanner';
      Directory downloadsDir = Directory(newPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      String fileName = file.path.split('/').last;
      String savedPath = '${downloadsDir.path}/$fileName';
      await file.copy(savedPath);

      // Optionally notify media scanner
      const MethodChannel _channel =
          MethodChannel('document_scanner/media_scanner');
      await _channel.invokeMethod('scanFile', {'path': savedPath});

      return true;
    } catch (e) {
      print('Error saving to downloads: $e');
      return false;
    }
  }

  // Future<void> showDownloadNotification(String fileName) async {
  //   final AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails(
  //     'download_channel', // id
  //     'Downloads', // title
  //     channelDescription: 'Notification channel for downloads',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     showWhen: true,
  //   );
  //   final NotificationDetails platformChannelSpecifics =
  //       NotificationDetails(android: androidPlatformChannelSpecifics);
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     'Download Complete',
  //     '$fileName has been saved.',
  //     platformChannelSpecifics,
  //     payload: fileName,
  //   );
  // }

  void testSave() async {
    File file =
        File('/path/to/your/temp/image.jpg'); // Use a real, existing file path
    bool result = await saveToDownloads(file);
    print('Save result: $result');
    print(
        'Expected saved path: /storage/emulated/0/Download/DocumentScanner/${file.path.split('/').last}');
  }

  Future<void> addToRecentDownloads(String path) async {
    // Implementation of addToRecentDownloads method
  }

  /// Save an image to the Pictures/DocumentScanner folder, notify media scanner, and add to recent documents
  Future<bool> saveImageAndRegister(File file) async {
    try {
      if (!await file.exists()) {
        print('saveImageAndRegister: Source file does not exist!');
        return false;
      }
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) return false;
        if (status.isPermanentlyDenied) {
          // Optionally prompt user to open settings
          return false;
        }
      }
      String newPath = '/storage/emulated/0/Pictures/DocumentScanner';
      Directory galleryDir = Directory(newPath);
      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
      }
      String fileName = file.path.split('/').last;
      String savedPath = '${galleryDir.path}/$fileName';
      File copied = await file.copy(savedPath);
      // Notify media scanner
      const MethodChannel _channel =
          MethodChannel('document_scanner/media_scanner');
      await _channel.invokeMethod('scanFile', {'path': savedPath});
      // Add to recent documents
      await addToRecentDownloads(savedPath);
      print('saveImageAndRegister: Image saved and registered at $savedPath');
      return true;
    } catch (e) {
      print('Error in saveImageAndRegister: $e');
      return false;
    }
  }

  /// Save a PDF to the Download/DocumentScanner folder, notify media scanner, and add to recent documents
  Future<bool> savePdfAndRegister(File file) async {
    try {
      if (!await file.exists()) {
        print('savePdfAndRegister: Source file does not exist!');
        return false;
      }
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) return false;
        if (status.isPermanentlyDenied) {
          // Optionally prompt user to open settings
          return false;
        }
      }
      String newPath = '/storage/emulated/0/Download/DocumentScanner';
      Directory downloadsDir = Directory(newPath);
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      String fileName = file.path.split('/').last;
      String savedPath = '${downloadsDir.path}/$fileName';
      File copied = await file.copy(savedPath);
      // Notify media scanner
      const MethodChannel _channel =
          MethodChannel('document_scanner/media_scanner');
      await _channel.invokeMethod('scanFile', {'path': savedPath});
      // Add to recent documents
      await addToRecentDownloads(savedPath);
      print('savePdfAndRegister: PDF saved and registered at $savedPath');
      return true;
    } catch (e) {
      print('Error in savePdfAndRegister: $e');
      return false;
    }
  }

  Future<bool> saveImageWithSaverGallery(File file) async {
    try {
      if (!await file.exists()) return false;
      final result = await SaverGallery.saveImage(
        file.readAsBytesSync(),
        fileName:
            'DocumentScanner_${DateTime.now().millisecondsSinceEpoch}.jpg',
        skipIfExists: false,
      );
      print('SaverGallery result: $result');
      // Optionally add to recent documents here
      return result.isSuccess;
    } catch (e) {
      print('Error saving with SaverGallery: $e');
      return false;
    }
  }
}
