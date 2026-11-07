import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
// ignore: depend_on_referenced_packages
import 'package:qr/qr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plakado/controllers/scanner_controller.dart';
import 'package:plakado/models/user_profile.dart';
import 'package:plakado/models/vehicle_registration.dart';
import 'package:plakado/services/image_processing_service.dart';
import 'package:plakado/services/ocr_recognition_service.dart';
import 'package:plakado/services/storage_service.dart';
import 'package:plakado/utils/plate_formatter.dart';

Uint8List _generateQrImageBytes(String payload) {
  final qrCode = QrCode.fromData(
    data: payload,
    errorCorrectLevel: QrErrorCorrectLevel.M,
  );
  final qrImage = QrImage(qrCode);

  const scale = 8;
  const margin = 24;
  final imgWidth = qrImage.moduleCount * scale + margin * 2;
  final imgHeight = qrImage.moduleCount * scale + margin * 2;

  final image = img.Image(width: imgWidth, height: imgHeight);
  img.fill(image, color: img.ColorRgb8(255, 255, 255)); // white background

  for (int r = 0; r < qrImage.moduleCount; r++) {
    for (int c = 0; c < qrImage.moduleCount; c++) {
      if (qrImage.isDark(r, c)) {
        final px = margin + c * scale;
        final py = margin + r * scale;
        img.fillRect(image,
            x1: px,
            y1: py,
            x2: px + scale - 1,
            y2: py + scale - 1,
            color: img.ColorRgb8(0, 0, 0));
      }
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Student QR & Plate Verification Tests', () {
    late StorageService storageService;
    late ScannerController scannerController;

    const studentQrJson =
        '{"plate":"574BSK","owner":"Lejon Osial","role":"student","id":"2023-10492","status":"approved"}';

    final registeredStudent = VehicleRegistration(
      id: 'veh-student-1',
      plateNumber: '574 BSK',
      normalizedPlate: '574BSK',
      ownerId: 'user-student-1',
      ownerName: 'Lejon Osial',
      ownerEmail: 'lejon.osial@isufst.edu.ph',
      ownerRole: UserRole.student,
      department: 'College of Computer Studies',
      idNumber: '2023-10492',
      vehicleType: 'Motorcycle',
      make: 'Rusi',
      model: '515',
      color: 'Red/Black',
      status: RegistrationStatus.approved,
      registeredAt: DateTime.now(),
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'plakado_vehicles': [jsonEncode(registeredStudent.toJson())],
      });
      final prefs = await SharedPreferences.getInstance();
      storageService = StorageService(prefs);
      final ocrService = OcrRecognitionService();
      scannerController = ScannerController(storageService, ocrService);
    });

    test('1. QrGatePassData parses student pass JSON correctly', () {
      final parsed = QrGatePassData.tryParse(studentQrJson);
      expect(parsed, isNotNull);
      expect(parsed!.plate, equals('574BSK'));
      expect(parsed.owner, equals('Lejon Osial'));
      expect(parsed.role, equals('student'));
      expect(parsed.idNumber, equals('2023-10492'));
      expect(parsed.status, equals('approved'));
      expect(parsed.isApproved, isTrue);
    });

    test('2. PlateFormatter.extractPlateCandidate parses student pass JSON', () {
      final candidate = PlateFormatter.extractPlateCandidate(studentQrJson);
      expect(candidate, equals('574 BSK'));
    });

    test('3. ImageProcessingService decodes QR from synthesized pass image bytes', () {
      final imageBytes = _generateQrImageBytes(studentQrJson);
      final decodedText = ImageProcessingService.decodeQrFromBytes(imageBytes);
      expect(decodedText, equals(studentQrJson));
    });

    test('4. ScannerController.processImage on student QR authorizes student without visitor flag', () async {
      final imageBytes = _generateQrImageBytes(studentQrJson);

      await scannerController.processImage(
        'blob:http://localhost:8080/temp-gatepass.png',
        bytes: imageBytes,
      );

      expect(scannerController.state, equals(ScannerState.resultReady));
      expect(scannerController.isAuthorized, isTrue);
      expect(scannerController.recognizedPlate, equals('574 BSK'));
      expect(scannerController.matchedVehicle, isNotNull);
      expect(scannerController.matchedVehicle!.ownerName, equals('Lejon Osial'));
      expect(scannerController.matchedVehicle!.ownerRole, equals(UserRole.student));
      expect(scannerController.matchedVehicle!.idNumber, equals('2023-10492'));
      expect(scannerController.statusMessage, contains('Authorized'));
      expect(scannerController.statusMessage, contains('STUDENT'));
    });

    test('5. ScannerController.verifyPlate on registered plate number authorizes student', () async {
      await scannerController.verifyPlate('574 BSK');

      expect(scannerController.state, equals(ScannerState.resultReady));
      expect(scannerController.isAuthorized, isTrue);
      expect(scannerController.recognizedPlate, equals('574 BSK'));
      expect(scannerController.matchedVehicle, isNotNull);
      expect(scannerController.matchedVehicle!.ownerName, equals('Lejon Osial'));
      expect(scannerController.statusMessage, contains('Authorized'));
    });

    test('6. ScannerController.verifyPlate on unregistered plate flags as Visitor', () async {
      await scannerController.verifyPlate('XYZ 9999');

      expect(scannerController.state, equals(ScannerState.resultReady));
      expect(scannerController.isAuthorized, isFalse);
      expect(scannerController.recognizedPlate, equals('XYZ 9999'));
      expect(scannerController.matchedVehicle, isNull);
      expect(scannerController.statusMessage, equals('Unregistered / Visitor Vehicle'));
    });

    test('7. QR gate pass fallback authorizes student even if not pre-seeded in storage', () async {
      // Create empty storage
      SharedPreferences.setMockInitialValues({'plakado_vehicles': <String>[]});
      final emptyPrefs = await SharedPreferences.getInstance();
      final freshStorage = StorageService(emptyPrefs);
      final freshScanner = ScannerController(freshStorage, OcrRecognitionService());

      final imageBytes = _generateQrImageBytes(studentQrJson);

      await freshScanner.processImage('blob:http://localhost:8080/qr.png', bytes: imageBytes);

      expect(freshScanner.isAuthorized, isTrue);
      expect(freshScanner.recognizedPlate, equals('574 BSK'));
      expect(freshScanner.matchedVehicle, isNotNull);
      expect(freshScanner.matchedVehicle!.ownerName, equals('Lejon Osial'));
      expect(freshScanner.matchedVehicle!.ownerRole, equals(UserRole.student));
    });
  });
}
