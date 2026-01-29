import 'package:hive/hive.dart';

part 'document_model.g.dart';

@HiveType(typeId: 1)
enum DocumentType {
  @HiveField(0)
  image,
  @HiveField(1)
  pdf,
  @HiveField(2)
  text,
}

@HiveType(typeId: 0)
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String imagePath;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  String? pdfPath;

  @HiveField(5)
  String? extractedText;

  @HiveField(6)
  List<String>? pageImagePaths;

  @HiveField(7)
  DateTime modifiedAt;

  @HiveField(8)
  DocumentType type;

  @HiveField(9)
  String? folderId;

  @HiveField(10)
  Map<String, dynamic> metadata;

  DocumentModel({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    required this.type,
    this.pdfPath,
    this.extractedText,
    this.pageImagePaths,
    DateTime? modifiedAt,
    this.folderId,
    Map<String, dynamic>? metadata,
  })  : modifiedAt = modifiedAt ?? createdAt,
        metadata = metadata ?? {};

  // Helper getters
  String get title => name;
  String get filePath => pdfPath ?? imagePath;

  // Copy with method for updates
  DocumentModel copyWith({
    String? id,
    String? name,
    String? imagePath,
    DateTime? createdAt,
    String? pdfPath,
    String? extractedText,
    List<String>? pageImagePaths,
    DateTime? modifiedAt,
    DocumentType? type,
    String? folderId,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      pdfPath: pdfPath ?? this.pdfPath,
      extractedText: extractedText ?? this.extractedText,
      pageImagePaths: pageImagePaths ?? this.pageImagePaths,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      type: type ?? this.type,
      folderId: folderId ?? this.folderId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to JSON for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'pdfPath': pdfPath,
      'extractedText': extractedText,
      'pageImagePaths': pageImagePaths,
      'modifiedAt': modifiedAt.toIso8601String(),
      'type': type.toString(),
      'folderId': folderId,
      'metadata': metadata,
    };
  }

  // Create from JSON for backup/import
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      name: json['name'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      pdfPath: json['pdfPath'],
      extractedText: json['extractedText'],
      pageImagePaths: json['pageImagePaths']?.cast<String>(),
      modifiedAt: DateTime.parse(json['modifiedAt']),
      type: DocumentType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => DocumentType.image,
      ),
      folderId: json['folderId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
