import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import '../models/user_profile.dart';
import '../models/vehicle_registration.dart';
import '../services/image_processing_service.dart';
import '../services/ocr_recognition_service.dart';
import '../services/storage_service.dart';
import '../utils/plate_formatter.dart';

enum ScannerState {
  idle,
  processingYolo,
  processingDip,
  processingOcr,
  resultReady,
  error,
}

class ScannerController extends ChangeNotifier {
  final StorageService _storageService;
  final OcrRecognitionService _ocrService;

  ScannerState _state = ScannerState.idle;
  String? _selectedImagePath;
  Uint8List? _processedImageBytes;
  YoloBoundingBox? _detectedBox;
  String? _recognizedPlate;
  VehicleRegistration? _matchedVehicle;
  bool _isAuthorized = false;
  String? _statusMessage;

  ScannerController(this._storageService, this._ocrService);

  ScannerState get state => _state;
  bool get isProcessing =>
      _state == ScannerState.processingYolo ||
      _state == ScannerState.processingDip ||
      _state == ScannerState.processingOcr;

  String? get selectedImagePath => _selectedImagePath;
  Uint8List? get processedImageBytes => _processedImageBytes;
  YoloBoundingBox? get detectedBox => _detectedBox;
  String? get recognizedPlate => _recognizedPlate;
  VehicleRegistration? get matchedVehicle => _matchedVehicle;
  bool get isAuthorized => _isAuthorized;
  String? get statusMessage => _statusMessage;

  /// Runs the full ALPR and Gate Pass QR Pipeline:
  /// Camera/Image -> QR Code Check -> YOLO Bounding Box Detection -> DIP Image Enhancement -> OCR Extraction -> Cloud/Local Database Verification
  Future<void> processImage(String imagePath, {Uint8List? bytes}) async {
    _selectedImagePath = imagePath;
    _recognizedPlate = null;
    _matchedVehicle = null;
    _isAuthorized = false;

    try {
      _state = ScannerState.processingYolo;
      _statusMessage = 'Analyzing image...';
      notifyListeners();

      Uint8List imageBytes = bytes ?? Uint8List(0);
      if (imageBytes.isEmpty) {
        if (!kIsWeb && File(imagePath).existsSync()) {
          imageBytes = await File(imagePath).readAsBytes();
        } else if (kIsWeb) {
          try {
            final xFile = XFile(imagePath);
            imageBytes = await xFile.readAsBytes();
          } catch (_) {}
        }
      }

      // Priority 1: Check if this image contains a Student Digital Gate Pass QR Code
      if (imageBytes.isNotEmpty) {
        final qrText = ImageProcessingService.decodeQrFromBytes(imageBytes);
        if (qrText != null && qrText.isNotEmpty) {
          final qrData = QrGatePassData.tryParse(qrText);
          if (qrData != null && qrData.plate.isNotEmpty) {
            _recognizedPlate = PlateFormatter.formatDisplay(qrData.plate);
            _processedImageBytes = imageBytes;
            await verifyPlate(_recognizedPlate!, qrFallback: qrData);
            return;
          }
        }
      }

      // Priority 2: YOLO License Plate Detection & Bounding Box
      _statusMessage = 'Running YOLOv8 plate detector...';
      notifyListeners();

      final box = await ImageProcessingService.detectPlateYolo(imageBytes);
      _detectedBox = box;

      // Priority 3: Digital Image Processing (Grayscale, Contrast boost, Cropping)
      _state = ScannerState.processingDip;
      _statusMessage = 'Applying DIP enhancement & character filtering...';
      notifyListeners();

      if (imageBytes.isNotEmpty) {
        _processedImageBytes = ImageProcessingService.processPlateImageForOcr(imageBytes, box);
      }

      // Priority 4: Optical Character Recognition (OCR)
      _state = ScannerState.processingOcr;
      _statusMessage = 'Extracting license plate text via OCR...';
      notifyListeners();

      final ocrResult = await _ocrService.recognizeFromPath(imagePath);
      String? plate = ocrResult.detectedPlate;

      if (plate != null && plate.isNotEmpty) {
        _recognizedPlate = PlateFormatter.formatDisplay(plate);
        await verifyPlate(_recognizedPlate!);
      } else {
        _recognizedPlate = null;
        _state = ScannerState.error;
        _statusMessage = kIsWeb
            ? 'No valid plate or gate pass QR detected. Please position the camera directly in front of the student QR pass or vehicle plate, or enter the plate number manually.'
            : 'No license plate or gate pass QR detected. Please point directly at the vehicle plate or student QR pass.';
        notifyListeners();
      }
    } catch (e) {
      _state = ScannerState.error;
      _statusMessage = 'Detection failed: $e';
      notifyListeners();
    }
  }

  /// Standalone OCR recognition for registration (extracts plate without gate pass check)
  Future<String?> recognizePlateOnly(String imagePath) async {
    try {
      final ocrResult = await _ocrService.recognizeFromPath(imagePath);
      final plate = ocrResult.detectedPlate;
      return plate != null && plate.isNotEmpty ? PlateFormatter.formatDisplay(plate) : null;
    } catch (e) {
      debugPrint('OCR registration recognition error: $e');
      return null;
    }
  }

  /// Verifies a plate string against campus records and Cloud Firestore
  Future<void> verifyPlate(String plateOrInput, {QrGatePassData? qrFallback}) async {
    final qrData = qrFallback ?? QrGatePassData.tryParse(plateOrInput);
    final targetPlate = qrData != null ? qrData.plate : PlateFormatter.normalize(plateOrInput);

    if (targetPlate.isEmpty) {
      _recognizedPlate = plateOrInput.trim();
      _matchedVehicle = null;
      _isAuthorized = false;
      _statusMessage = 'Invalid plate number';
      _state = ScannerState.resultReady;
      notifyListeners();
      return;
    }

    _recognizedPlate = PlateFormatter.formatDisplay(targetPlate);

    // 1. Search database asynchronously (checks local storage, pulls fresh records from Cloud Firestore if needed)
    VehicleRegistration? vehicle = await _storageService.findVehicleByPlateAsync(targetPlate);

    // 2. Fallback for valid approved QR gate pass if not found in database yet
    if (vehicle == null && qrData != null && qrData.isApproved) {
      vehicle = VehicleRegistration(
        id: 'qr-${qrData.plate}-${DateTime.now().millisecondsSinceEpoch}',
        plateNumber: PlateFormatter.formatDisplay(qrData.plate),
        normalizedPlate: qrData.plate,
        ownerId: qrData.idNumber.isNotEmpty ? qrData.idNumber : 'student-${qrData.plate}',
        ownerName: qrData.owner,
        ownerEmail: '${qrData.owner.toLowerCase().replaceAll(RegExp(r'\s+'), '.')}@isufst.edu.ph',
        ownerRole: UserRole.values.firstWhere(
          (r) => r.name.toLowerCase() == qrData.role.toLowerCase(),
          orElse: () => UserRole.student,
        ),
        department: qrData.department ?? 'College of Computer Studies',
        idNumber: qrData.idNumber.isNotEmpty ? qrData.idNumber : 'STUDENT-2026',
        vehicleType: qrData.vehicleType ?? 'Motorcycle',
        make: qrData.make ?? 'Registered',
        model: qrData.model ?? 'Vehicle',
        color: qrData.color ?? 'Standard',
        status: RegistrationStatus.approved,
        registeredAt: DateTime.now(),
      );
      // Auto-cache into storage so subsequent checks and logs link cleanly
      await _storageService.saveVehicle(vehicle);
    }

    if (vehicle != null && vehicle.status == RegistrationStatus.approved) {
      _matchedVehicle = vehicle;
      _isAuthorized = true;
      _statusMessage = 'Authorized: ${vehicle.ownerName} (${vehicle.ownerRole.displayName.toUpperCase()})';
    } else {
      _matchedVehicle = null;
      _isAuthorized = false;
      _statusMessage = 'Unregistered / Visitor Vehicle';
    }

    _state = ScannerState.resultReady;
    notifyListeners();
  }

  void reset() {
    _state = ScannerState.idle;
    _selectedImagePath = null;
    _processedImageBytes = null;
    _detectedBox = null;
    _recognizedPlate = null;
    _matchedVehicle = null;
    _isAuthorized = false;
    _statusMessage = null;
    notifyListeners();
  }
}
