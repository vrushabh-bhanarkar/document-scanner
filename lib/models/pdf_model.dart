class PdfDocumentModel {
  final String id;
  final String filePath;
  final String title;
  final DateTime createdAt;
  final List<String> pageImagePaths;

  PdfDocumentModel({
    required this.id,
    required this.filePath,
    required this.title,
    required this.createdAt,
    required this.pageImagePaths,
  });
}
