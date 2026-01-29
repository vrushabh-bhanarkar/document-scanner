/// App Configuration for PDF ScanPro
/// This file contains all app-wide constants and configuration

class AppConfig {
  // App Info
  static const String appName = 'PDF ScanPro';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Storage Paths
  static const String pdfStorageFolder = 'PDF_ScanPro';
  static const String tempFolder = 'temp';
  static const String imagesFolder = 'images';

  // Feature Flags
  static const bool enableIDCardMode = true;
  static const bool enableSmartNaming = true;
  static const bool enableNoWatermarkFriday = true;
  static const bool enableOfflineOCR = true;
  static const bool enableBatchScanning = true;

  // PDF Settings
  static const int maxPdfPages = 500;
  static const int pdfCompressionQuality = 85;
  static const List<int> supportedPdfQualities = [50, 75, 100];

  // Camera Settings
  static const String cameraResolutionPreset = 'high';
  static const bool enableAutoCapture = true;
  static const int autoCaptureSensitivity = 100; // 0-100

  // UI Settings
  static const bool enableDarkMode = false; // Always white background
  static const bool enableAnimations = true;

  // API Keys (for future use)
  static const String googleAdMobAppId = '';

  // Permissions
  static const List<String> requiredPermissions = [
    'camera',
    'storage',
    'files',
  ];

  // OCR Languages
  static const List<String> supportedOCRLanguages = [
    'en', // English
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'pt', // Portuguese
    'ru', // Russian
    'zh', // Chinese
    'ja', // Japanese
    'ko', // Korean
  ];
}

/// Material 3 Design System Constants
class DesignSystem {
  // Primary Colors - Material 3 (PDF ScanPro Spec)
  static const int primaryBlueValue = 0xFF0052D4; // Deep Blue
  static const int secondaryTealValue = 0xFF00B4DB; // Teal
  static const int backgroundWhiteValue = 0xFFFFFFFF; // White
  static const int lightGrayValue = 0xFFF7F7F7; // Light Gray

  // Border Radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusExtraLarge = 24;
  static const double radiusCircle = 999;

  // Spacing (8px baseline)
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Typography Sizes
  static const double textDisplayLarge = 32;
  static const double textDisplayMedium = 28;
  static const double textHeadlineLarge = 24;
  static const double textHeadlineMedium = 20;
  static const double textTitleLarge = 18;
  static const double textTitleMedium = 16;
  static const double textBodyLarge = 16;
  static const double textBodyMedium = 14;
  static const double textBodySmall = 12;

  // Elevation (Shadow depth)
  static const double elevationNone = 0;
  static const double elevationSmall = 2;
  static const double elevationMedium = 4;
  static const double elevationLarge = 8;
  static const double elevationXLarge = 12;

  // Animation Durations
  static const int durationFast = 200; // ms
  static const int durationNormal = 300; // ms
  static const int durationSlow = 500; // ms
  static const int durationVerySlow = 800; // ms
}

/// Feature-specific configurations
class FeatureConfig {
  // ID Card Mode - Automatic merging front & back to A4
  static const bool idCardAutoMerge = true;
  static const double idCardPageWidth = 210; // mm (A4)
  static const double idCardPageHeight = 297; // mm (A4)
  static const double idCardImageSpacing = 5; // mm between front and back

  // No-Watermark Friday
  static const bool enableWatermarkRemoval = true;
  static const int watermarkFreeFriday = DateTime.friday;

  // Smart File Naming
  static const bool autoSuggestNames = true;
  static const List<String> defaultCategories = [
    'Invoice',
    'Medical_Report',
    'Receipt',
    'Contract',
    'Agreement',
    'ID_Card',
  ];

  // Batch Scanning
  static const int maxBatchPages = 100;
  static const bool enableBatchPreview = true;

  // OCR (Offline)
  static const bool enableLocalOCR = true;
  static const int ocrTimeout = 30000; // ms
}

/// Error Messages
class ErrorMessages {
  static const String cameraNotAvailable =
      'Camera is not available on this device';
  static const String permissionDenied =
      'Permission denied. Please enable in settings.';
  static const String fileReadError = 'Failed to read file. Please try again.';
  static const String fileWriteError = 'Failed to save file. Please try again.';
  static const String pdfGenerationError =
      'Failed to generate PDF. Please try again.';
  static const String ocrError = 'Failed to extract text. Please try again.';
  static const String networkError =
      'Network error. Please check your connection.';
}

/// Success Messages
class SuccessMessages {
  static const String documentSaved = 'Document saved successfully';
  static const String documentShared = 'Document shared successfully';
  static const String documentDeleted = 'Document deleted successfully';
  static const String pdfCreated = 'PDF created successfully';
  static const String textExtracted = 'Text extracted successfully';
}
