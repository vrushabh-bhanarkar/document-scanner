import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRResult {
  final String text;
  final List<TextBlock> blocks;
  final double confidence;

  OCRResult({
    required this.text,
    required this.blocks,
    required this.confidence,
  });
}

class TextBlock {
  final String text;
  final Rect boundingBox;
  final List<TextLine> lines;

  TextBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}

class TextLine {
  final String text;
  final Rect boundingBox;
  final List<TextElement> elements;

  TextLine({
    required this.text,
    required this.boundingBox,
    required this.elements,
  });
}

class TextElement {
  final String text;
  final Rect boundingBox;

  TextElement({
    required this.text,
    required this.boundingBox,
  });
}

class OCRService {
  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  OCRService() {
    _initializeRecognizer();
  }

  void _initializeRecognizer() {
    _textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    _isInitialized = true;
  }

  /// Extract text from image file
  Future<OCRResult?> extractTextFromImage(File imageFile) async {
    if (!_isInitialized) {
      _initializeRecognizer();
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return null;
      }

      // Convert ML Kit results to our custom format
      final blocks = recognizedText.blocks.map((block) {
        final lines = block.lines.map((line) {
          final elements = line.elements.map((element) {
            return TextElement(
              text: element.text,
              boundingBox: element.boundingBox,
            );
          }).toList();

          return TextLine(
            text: line.text,
            boundingBox: line.boundingBox,
            elements: elements,
          );
        }).toList();

        return TextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          lines: lines,
        );
      }).toList();

      // Calculate average confidence (simplified)
      final confidence = _calculateConfidence(recognizedText);

      return OCRResult(
        text: recognizedText.text,
        blocks: blocks,
        confidence: confidence,
      );
    } catch (e) {
      print('OCR Error: $e');
      return null;
    }
  }

  /// Extract text from multiple images
  Future<List<OCRResult>> extractTextFromImages(List<File> imageFiles) async {
    final results = <OCRResult>[];

    for (final imageFile in imageFiles) {
      final result = await extractTextFromImage(imageFile);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  /// Get text with formatting preserved
  String getFormattedText(OCRResult result) {
    final buffer = StringBuffer();

    for (int i = 0; i < result.blocks.length; i++) {
      final block = result.blocks[i];
      buffer.write(block.text);

      // Add spacing between blocks
      if (i < result.blocks.length - 1) {
        buffer.write('\n\n');
      }
    }

    return buffer.toString();
  }

  /// Get text with line breaks preserved
  String getTextWithLineBreaks(OCRResult result) {
    final buffer = StringBuffer();

    for (final block in result.blocks) {
      for (int i = 0; i < block.lines.length; i++) {
        final line = block.lines[i];
        buffer.write(line.text);

        // Add line break except for the last line in the last block
        if (i < block.lines.length - 1) {
          buffer.write('\n');
        }
      }
      buffer.write('\n');
    }

    return buffer.toString().trim();
  }

  /// Get plain text without formatting
  String getPlainText(OCRResult result) {
    return result.text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Search for specific text in OCR result
  List<TextElement> searchText(OCRResult result, String query) {
    final matches = <TextElement>[];
    final lowerQuery = query.toLowerCase();

    for (final block in result.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (element.text.toLowerCase().contains(lowerQuery)) {
            matches.add(element);
          }
        }
      }
    }

    return matches;
  }

  /// Get text statistics
  Map<String, dynamic> getTextStatistics(OCRResult result) {
    final words = result.text.split(RegExp(r'\s+'));
    final characters = result.text.length;
    final charactersNoSpaces =
        result.text.replaceAll(RegExp(r'\s+'), '').length;
    final lines =
        result.blocks.fold<int>(0, (sum, block) => sum + block.lines.length);
    final paragraphs = result.blocks.length;

    return {
      'words': words.length,
      'characters': characters,
      'charactersNoSpaces': charactersNoSpaces,
      'lines': lines,
      'paragraphs': paragraphs,
      'confidence': result.confidence,
    };
  }

  /// Extract emails from text
  List<String> extractEmails(OCRResult result) {
    final emailRegex =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    return emailRegex
        .allMatches(result.text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extract phone numbers from text
  List<String> extractPhoneNumbers(OCRResult result) {
    final phoneRegex =
        RegExp(r'(\+?1[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}');
    return phoneRegex
        .allMatches(result.text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extract URLs from text
  List<String> extractUrls(OCRResult result) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex
        .allMatches(result.text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Extract dates from text (basic pattern)
  List<String> extractDates(OCRResult result) {
    final dateRegex = RegExp(
        r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b|\b\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b',
        caseSensitive: false);
    return dateRegex
        .allMatches(result.text)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Clean up text (remove extra spaces, fix common OCR errors)
  String cleanText(String text) {
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    // Fix common OCR errors
    text = text.replaceAll(RegExp(r'\b0\b'), 'O'); // Zero to O
    text =
        text.replaceAll(RegExp(r'\b1\b'), 'I'); // One to I (context dependent)
    text =
        text.replaceAll(RegExp(r'\b5\b'), 'S'); // Five to S (context dependent)

    // Remove leading/trailing whitespace
    text = text.trim();

    return text;
  }

  /// Calculate confidence score (simplified)
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    // This is a simplified confidence calculation
    // In a real implementation, you might use ML Kit's confidence scores if available
    final totalElements = recognizedText.blocks
        .expand((block) => block.lines)
        .expand((line) => line.elements)
        .length;

    if (totalElements == 0) return 0.0;

    // Base confidence on text length and structure
    final textLength = recognizedText.text.length;
    final hasStructure = recognizedText.blocks.length > 1;

    double confidence = 0.5; // Base confidence

    if (textLength > 50) confidence += 0.2;
    if (textLength > 200) confidence += 0.1;
    if (hasStructure) confidence += 0.1;
    if (totalElements > 10) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  /// Process image with custom settings
  Future<OCRResult?> extractTextWithSettings({
    required File imageFile,
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) async {
    try {
      // Create recognizer with specific script
      final recognizer = TextRecognizer(script: script);

      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await recognizer.processImage(inputImage);

      // Clean up
      await recognizer.close();

      if (recognizedText.text.isEmpty) {
        return null;
      }

      // Convert to our format
      final blocks = recognizedText.blocks.map((block) {
        final lines = block.lines.map((line) {
          final elements = line.elements.map((element) {
            return TextElement(
              text: element.text,
              boundingBox: element.boundingBox,
            );
          }).toList();

          return TextLine(
            text: line.text,
            boundingBox: line.boundingBox,
            elements: elements,
          );
        }).toList();

        return TextBlock(
          text: block.text,
          boundingBox: block.boundingBox,
          lines: lines,
        );
      }).toList();

      final confidence = _calculateConfidence(recognizedText);

      return OCRResult(
        text: recognizedText.text,
        blocks: blocks,
        confidence: confidence,
      );
    } catch (e) {
      print('OCR Error with settings: $e');
      return null;
    }
  }

  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}
