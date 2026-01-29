class UserSettings {
  // Scanner settings
  final bool autoCapture;
  final bool showEdgeDetection;
  final bool flashByDefault;

  // Image processing
  final String defaultImageQuality;
  final String autoEnhance;
  final bool autoRotate;

  // OCR settings
  final bool autoOCR;
  final String ocrLanguage;

  // Storage & Privacy
  final bool saveToCloud;
  final bool encryptDocuments;
  final String storageLocation;

  // App preferences
  final String theme;
  final String language;
  final bool showTutorials;

  // Legacy properties for compatibility
  final bool isDarkMode;
  final String languageCode;

  UserSettings({
    this.autoCapture = true,
    this.showEdgeDetection = true,
    this.flashByDefault = false,
    this.defaultImageQuality = 'High',
    this.autoEnhance = 'Basic',
    this.autoRotate = true,
    this.autoOCR = false,
    this.ocrLanguage = 'English',
    this.saveToCloud = false,
    this.encryptDocuments = false,
    this.storageLocation = 'Internal Storage',
    this.theme = 'System',
    this.language = 'English',
    this.showTutorials = true,
    bool? isDarkMode,
    String? languageCode,
  })  : isDarkMode = isDarkMode ?? false,
        languageCode = languageCode ?? 'en';

  UserSettings copyWith({
    bool? autoCapture,
    bool? showEdgeDetection,
    bool? flashByDefault,
    String? defaultImageQuality,
    String? autoEnhance,
    bool? autoRotate,
    bool? autoOCR,
    String? ocrLanguage,
    bool? saveToCloud,
    bool? encryptDocuments,
    String? storageLocation,
    String? theme,
    String? language,
    bool? showTutorials,
    bool? isDarkMode,
    String? languageCode,
  }) {
    return UserSettings(
      autoCapture: autoCapture ?? this.autoCapture,
      showEdgeDetection: showEdgeDetection ?? this.showEdgeDetection,
      flashByDefault: flashByDefault ?? this.flashByDefault,
      defaultImageQuality: defaultImageQuality ?? this.defaultImageQuality,
      autoEnhance: autoEnhance ?? this.autoEnhance,
      autoRotate: autoRotate ?? this.autoRotate,
      autoOCR: autoOCR ?? this.autoOCR,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
      saveToCloud: saveToCloud ?? this.saveToCloud,
      encryptDocuments: encryptDocuments ?? this.encryptDocuments,
      storageLocation: storageLocation ?? this.storageLocation,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      showTutorials: showTutorials ?? this.showTutorials,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoCapture': autoCapture,
      'showEdgeDetection': showEdgeDetection,
      'flashByDefault': flashByDefault,
      'defaultImageQuality': defaultImageQuality,
      'autoEnhance': autoEnhance,
      'autoRotate': autoRotate,
      'autoOCR': autoOCR,
      'ocrLanguage': ocrLanguage,
      'saveToCloud': saveToCloud,
      'encryptDocuments': encryptDocuments,
      'storageLocation': storageLocation,
      'theme': theme,
      'language': language,
      'showTutorials': showTutorials,
      'isDarkMode': isDarkMode,
      'languageCode': languageCode,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      autoCapture: json['autoCapture'] ?? true,
      showEdgeDetection: json['showEdgeDetection'] ?? true,
      flashByDefault: json['flashByDefault'] ?? false,
      defaultImageQuality: json['defaultImageQuality'] ?? 'High',
      autoEnhance: json['autoEnhance'] ?? 'Basic',
      autoRotate: json['autoRotate'] ?? true,
      autoOCR: json['autoOCR'] ?? false,
      ocrLanguage: json['ocrLanguage'] ?? 'English',
      saveToCloud: json['saveToCloud'] ?? false,
      encryptDocuments: json['encryptDocuments'] ?? false,
      storageLocation: json['storageLocation'] ?? 'Internal Storage',
      theme: json['theme'] ?? 'System',
      language: json['language'] ?? 'English',
      showTutorials: json['showTutorials'] ?? true,
      isDarkMode: json['isDarkMode'] ?? false,
      languageCode: json['languageCode'] ?? 'en',
    );
  }
}
