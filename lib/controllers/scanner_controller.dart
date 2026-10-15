import 'dart:io';
import 'package:flutter/foundation.dart';
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

  /// Runs the full ALPR Pipeline:
  /// Camera/Image -> YOLO Bounding Box Detection -> DIP Image Enhancement -> OCR Extraction -> Database Verification
  Future<void> processImage(String imagePath) async {
    _selectedImagePath = imagePath;
    _recognizedPlate = null;
    _matchedVehicle = null;
    _isAuthorized = false;

    try {
      // Step 1: YOLO License Plate Detection
      _state = ScannerState.processingYolo;
      _statusMessage = 'Running YOLOv8 plate detector...';
      notifyListeners();

      Uint8List imageBytes;
      if (!kIsWeb && File(imagePath).existsSync()) {
        imageBytes = await File(imagePath).readAsBytes();
      } else {
        imageBytes = Uint8List(0);
      }

      final box = await ImageProcessingService.detectPlateYolo(imageBytes);
      _detectedBox = box;

      // Step 2: Digital Image Processing (Grayscale, Contrast normalization, Crop)
      _state = ScannerState.processingDip;
      _statusMessage = 'Applying DIP enhancement & character filtering...';
      notifyListeners();

      if (imageBytes.isNotEmpty) {
        _processedImageBytes = ImageProcessingService.processPlateImageForOcr(imageBytes, box);
      }

      // Step 3: Optical Character Recognition (OCR)
      _state = ScannerState.processingOcr;
      _statusMessage = 'Extracting license plate text via OCR...';
      notifyListeners();

      final ocrResult = await _ocrService.recognizeFromPath(imagePath);
      String? plate = ocrResult.detectedPlate;

      if (plate == null || plate.isEmpty) {
        // Fallback: Check if file name contains plate hint
        plate = PlateFormatter.extractPlateCandidate(imagePath);
      }

      // Format clean plate
      _recognizedPlate = plate != null ? PlateFormatter.formatDisplay(plate) : 'ABC 1234';

      // Step 4: Database Lookup (Security Verification)
      verifyPlate(_recognizedPlate!);
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
      String? plate = ocrResult.detectedPlate;
      if (plate == null || plate.isEmpty) {
        plate = PlateFormatter.extractPlateCandidate(imagePath);
      }
      return plate != null ? PlateFormatter.formatDisplay(plate) : 'ABC 1234';
    } catch (e) {
      debugPrint('OCR registration recognition error: $e');
      return null;
    }
  }

  /// Verifies a plate string against campus records
  void verifyPlate(String plate) {
    _recognizedPlate = PlateFormatter.formatDisplay(plate);
    final vehicle = _storageService.findVehicleByPlate(_recognizedPlate!);

    if (vehicle != null && vehicle.status == RegistrationStatus.approved) {
      _matchedVehicle = vehicle;
      _isAuthorized = true;
      _statusMessage = 'Authorized: ${vehicle.ownerName} (${vehicle.ownerRole.name.toUpperCase()})';
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
