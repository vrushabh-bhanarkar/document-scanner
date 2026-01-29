import 'package:intl/intl.dart';

class SmartFileNamingService {
  /// Generates smart file names based on date and optional context
  /// Examples: Invoice_2026_01_07.pdf, Medical_Report_2026_01_07.pdf
  static String generateSmartFileName({
    String? category,
    DateTime? dateTime,
  }) {
    final now = dateTime ?? DateTime.now();
    final formatter = DateFormat('yyyy_MM_dd');
    final dateString = formatter.format(now);

    if (category != null && category.isNotEmpty) {
      return '${_capitalize(category)}_$dateString.pdf';
    }

    return 'Document_$dateString.pdf';
  }

  /// Suggests file names based on common document types
  static List<String> suggestFileNames({required DateTime dateTime}) {
    final formatter = DateFormat('yyyy_MM_dd');
    final dateString = formatter.format(dateTime);

    return [
      'Invoice_$dateString.pdf',
      'Medical_Report_$dateString.pdf',
      'Receipt_$dateString.pdf',
      'Contract_$dateString.pdf',
      'Agreement_$dateString.pdf',
      'Document_$dateString.pdf',
    ];
  }

  /// Capitalizes the first letter of a string
  static String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1).toLowerCase();
  }

  /// Validates a filename (removes invalid characters)
  static String sanitizeFileName(String name) {
    // Remove invalid characters for filenames
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  /// Checks if a filename already exists and suggests alternatives
  static String getUniqueFileName(
    String baseName,
    List<String> existingFiles,
  ) {
    if (!existingFiles.contains(baseName)) {
      return baseName;
    }

    String nameWithoutExt = baseName.replaceAll('.pdf', '');
    int counter = 1;

    while (existingFiles.contains('${nameWithoutExt}_$counter.pdf')) {
      counter++;
    }

    return '${nameWithoutExt}_$counter.pdf';
  }
}
