import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../utils/plate_formatter.dart';

class OcrRecognitionResult {
  final String rawText;
  final String? detectedPlate;
  final bool isSuccess;
  final String? errorMessage;

  OcrRecognitionResult({
    required this.rawText,
    this.detectedPlate,
    required this.isSuccess,
    this.errorMessage,
  });
}

class OcrRecognitionService {
  TextRecognizer? _textRecognizer;

  OcrRecognitionService() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      } catch (e) {
        debugPrint('ML Kit initialization warning: $e');
      }
    }
  }

  /// Extracts license plate text from an image file path
  Future<OcrRecognitionResult> recognizeFromPath(String imagePath) async {
    try {
      // 1. If on supported mobile device, run Google ML Kit
      if (_textRecognizer != null && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final inputImage = InputImage.fromFilePath(imagePath);
        final recognizedText = await _textRecognizer!.processImage(inputImage);
        final raw = recognizedText.text;
        final plate = PlateFormatter.extractPlateCandidate(raw);

        return OcrRecognitionResult(
          rawText: raw,
          detectedPlate: plate,
          isSuccess: plate != null,
        );
      }

      // 2. Desktop/Web fallback: extract plate candidate from filename if available
      final filename = imagePath.split(RegExp(r'[/\\]')).last.toUpperCase();
      String? fallbackPlate = PlateFormatter.extractPlateCandidate(filename);

      if (fallbackPlate != null) {
        return OcrRecognitionResult(
          rawText: 'DETECTED PLATE: $fallbackPlate',
          detectedPlate: fallbackPlate,
          isSuccess: true,
        );
      }

      return OcrRecognitionResult(
        rawText: '',
        detectedPlate: null,
        isSuccess: false,
      );
    } catch (e) {
      debugPrint('OCR Recognition Error: $e');
      return OcrRecognitionResult(
        rawText: '',
        detectedPlate: null,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
