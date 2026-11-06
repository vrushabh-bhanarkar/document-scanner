import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SleekScanApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator/macOS, or machine IP for physical devices
  static const String baseUrl = "http://10.0.2.2:8000/api/v1";

  /// Pro AI Feature: Ask questions or summarize PDF
  static Future<String> chatWithPdf({
    required File file,
    required String prompt,
  }) async {
    final uri = Uri.parse('$baseUrl/ai/chat-pdf');
    final request = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = prompt
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['answer'] ?? "No answer returned.";
    } else {
      throw Exception("AI Chat failed: ${response.body}");
    }
  }

  /// Pro Conversion: PDF to Word DOCX
  static Future<File> convertPdfToDocx({
    required File inputFile,
    required String targetPath,
  }) async {
    final uri = Uri.parse('$baseUrl/convert/to-docx');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', inputFile.path));

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode == 200) {
      final bytes = await streamedResponse.stream.toBytes();
      final outputFile = File(targetPath);
      return await outputFile.writeAsBytes(bytes);
    } else {
      throw Exception("Conversion failed: ${streamedResponse.statusCode}");
    }
  }

  /// Compression: High-Ratio Server Compression
  static Future<File> compressPdf({
    required File inputFile,
    required String targetPath,
    String level = "medium",
  }) async {
    final uri = Uri.parse('$baseUrl/pdf/compress?level=$level');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', inputFile.path));

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode == 200) {
      final bytes = await streamedResponse.stream.toBytes();
      final outputFile = File(targetPath);
      return await outputFile.writeAsBytes(bytes);
    } else {
      throw Exception("Compression failed: ${streamedResponse.statusCode}");
    }
  }
}
