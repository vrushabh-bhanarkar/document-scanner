import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/document_model.dart';

class LocalStorage {
  static const String documentsBoxName = 'documents';
  static const String settingsBoxName = 'settings';

  // Initialize Hive and open boxes
  static Future<void> init() async {
    try {
      // Get the application documents directory
      final appDocumentDir = await getApplicationDocumentsDirectory();

      // Initialize Hive with the correct path
      await Hive.initFlutter(appDocumentDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DocumentModelAdapter());
      }

      // Open boxes with error handling
      if (!Hive.isBoxOpen(documentsBoxName)) {
        await Hive.openBox<DocumentModel>(documentsBoxName);
      }

      if (!Hive.isBoxOpen(settingsBoxName)) {
        await Hive.openBox(settingsBoxName);
      }
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow; // Rethrow to handle in main.dart
    }
  }

  // Documents CRUD operations
  static Future<void> saveDocument(DocumentModel document) async {
    final box = Hive.box<DocumentModel>(documentsBoxName);
    await box.put(document.id, document);
  }

  static DocumentModel? getDocument(String id) {
    final box = Hive.box<DocumentModel>(documentsBoxName);
    return box.get(id);
  }

  static List<DocumentModel> getAllDocuments() {
    final box = Hive.box<DocumentModel>(documentsBoxName);
    return box.values.toList();
  }

  static Future<void> deleteDocument(String id) async {
    final box = Hive.box<DocumentModel>(documentsBoxName);
    await box.delete(id);
  }

  static Future<void> clearAllDocuments() async {
    final box = Hive.box<DocumentModel>(documentsBoxName);
    await box.clear();
  }

  // Settings operations
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(settingsBoxName);
    await box.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(settingsBoxName);
    return box.get(key, defaultValue: defaultValue);
  }

  // Common settings keys
  static const String darkModeKey = 'darkMode';
  static const String defaultFilterKey = 'defaultFilter';
  static const String documentQualityKey = 'documentQuality';
  static const String biometricAuthEnabledKey = 'biometricAuthEnabled';

  // Helper methods for common settings
  static Future<void> setDarkMode(bool value) async {
    await saveSetting(darkModeKey, value);
  }

  static bool getDarkMode() {
    return getSetting(darkModeKey, defaultValue: false);
  }

  static Future<void> setDefaultFilter(String value) async {
    await saveSetting(defaultFilterKey, value);
  }

  static String getDefaultFilter() {
    return getSetting(defaultFilterKey, defaultValue: 'original');
  }

  static Future<void> setDocumentQuality(int value) async {
    await saveSetting(documentQualityKey, value);
  }

  static int getDocumentQuality() {
    return getSetting(documentQualityKey, defaultValue: 85);
  }

  static Future<void> setBiometricAuthEnabled(bool value) async {
    await saveSetting(biometricAuthEnabledKey, value);
  }

  static bool getBiometricAuthEnabled() {
    return getSetting(biometricAuthEnabledKey, defaultValue: false);
  }
}
