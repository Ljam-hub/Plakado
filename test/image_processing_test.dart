import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plakado/services/image_processing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Plakado Flutter - ImageProcessingService Tests', () {
    late img.Image testImage;
    late Uint8List testImageBytes;

    setUp(() {
      // Create a 200x100 synthetic test image (representing a vehicle license plate)
      testImage = img.Image(width: 200, height: 100);
      for (int y = 0; y < testImage.height; y++) {
        for (int x = 0; x < testImage.width; x++) {
          // White background with dark simulated characters
          if (x > 40 && x < 160 && y > 30 && y < 70) {
            testImage.setPixelRgb(x, y, 20, 20, 20); // dark text
          } else {
            testImage.setPixelRgb(x, y, 240, 240, 240); // bright plate
          }
        }
      }
      testImageBytes = Uint8List.fromList(img.encodeJpg(testImage));
    });

    test('cropRoi correctly crops Region of Interest according to YOLO bounding box', () {
      final box = YoloBoundingBox(
        x: 0.2, // 40px
        y: 0.3, // 30px
        width: 0.6, // 120px
        height: 0.4, // 40px
        confidence: 0.95,
      );

      final cropped = ImageProcessingService.cropRoi(testImage, box);

      expect(cropped.width, 120);
      expect(cropped.height, 40);
    });

    test('toGrayscale converts RGB image to grayscale luminance', () {
      final gray = ImageProcessingService.toGrayscale(testImage);
      expect(gray.width, testImage.width);
      expect(gray.height, testImage.height);
      // In Dart image package, grayscale sets R=G=B to luminance
      for (int y = 0; y < gray.height; y += 15) {
        for (int x = 0; x < gray.width; x += 15) {
          final p = gray.getPixel(x, y);
          expect(p.r, equals(p.g));
          expect(p.g, equals(p.b));
        }
      }
    });

    test('adjustContrast enhances image contrast without corrupting dimensions', () {
      final enhanced = ImageProcessingService.adjustContrast(testImage, contrast: 1.5);
      expect(enhanced.width, testImage.width);
      expect(enhanced.height, testImage.height);
    });

    test('applyBinarization segments image into strict binary black/white (0 or 255)', () {
      final binary = ImageProcessingService.applyBinarization(testImage, threshold: 128);
      expect(binary.width, testImage.width);
      expect(binary.height, testImage.height);

      // Verify that every pixel is strictly 0 or 255
      for (int y = 0; y < binary.height; y += 10) {
        for (int x = 0; x < binary.width; x += 10) {
          final p = binary.getPixel(x, y);
          final r = p.r.toInt();
          expect(r == 0 || r == 255, isTrue, reason: 'Pixel at ($x, $y) value was $r');
        }
      }
    });

    test('processPlateImageForOcr executes end-to-end DIP pipeline and returns valid encoded bytes', () {
      final box = YoloBoundingBox(
        x: 0.1,
        y: 0.1,
        width: 0.8,
        height: 0.8,
        confidence: 0.98,
      );

      final processedBytes = ImageProcessingService.processPlateImageForOcr(testImageBytes, box);
      expect(processedBytes.isNotEmpty, isTrue);

      final decodedProcessed = img.decodeImage(processedBytes);
      expect(decodedProcessed, isNotNull);
      expect(decodedProcessed!.width, closeTo(160, 2));
      expect(decodedProcessed.height, closeTo(80, 2));
    });

    test('detectPlateYolo produces valid bounding box coordinates and high confidence score', () async {
      final box = await ImageProcessingService.detectPlateYolo(testImageBytes, imageWidth: 200, imageHeight: 100);

      expect(box.confidence, greaterThanOrEqualTo(0.90));
      expect(box.width, greaterThan(0.0));
      expect(box.height, greaterThan(0.0));
      expect(box.x, greaterThanOrEqualTo(0.0));
      expect(box.y, greaterThanOrEqualTo(0.0));
      expect(box.label, 'license_plate');
    });
  });
}
