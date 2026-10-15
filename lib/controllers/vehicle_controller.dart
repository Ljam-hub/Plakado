import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/vehicle_registration.dart';
import '../services/storage_service.dart';
import '../utils/plate_formatter.dart';

class VehicleController extends ChangeNotifier {
  final StorageService _storageService;
  List<VehicleRegistration> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  VehicleController(this._storageService) {
    loadVehicles();
  }

  List<VehicleRegistration> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void loadVehicles() {
    _vehicles = _storageService.getVehicles();
    notifyListeners();
  }

  List<VehicleRegistration> getVehiclesForUser(String userEmail) {
    return _storageService.getVehiclesByOwner(userEmail);
  }

  /// Registers a new vehicle for a student or faculty member
  Future<bool> registerNewVehicle({
    required String plateNumber,
    required UserProfile owner,
    required String vehicleType,
    required String make,
    required String model,
    required String color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanPlate = PlateFormatter.normalize(plateNumber);

      if (!PlateFormatter.isValidPlate(cleanPlate)) {
        _errorMessage = 'Invalid plate format. (e.g. ABC 1234 or 123 ABC)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if already registered
      final existing = _storageService.findVehicleByPlate(cleanPlate);
      if (existing != null) {
        _errorMessage = 'Plate number $cleanPlate is already registered to ${existing.ownerName}.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newVehicle = VehicleRegistration(
        id: const Uuid().v4(),
        plateNumber: PlateFormatter.formatDisplay(cleanPlate),
        normalizedPlate: cleanPlate,
        ownerId: owner.id,
        ownerName: owner.name,
        ownerEmail: owner.email,
        ownerRole: owner.role,
        department: owner.department,
        idNumber: owner.idNumber,
        vehicleType: vehicleType,
        make: make.trim(),
        model: model.trim(),
        color: color.trim(),
        status: RegistrationStatus.approved,
        registeredAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 365)), // 1-year pass
      );

      await _storageService.saveVehicle(newVehicle);
      loadVehicles();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to register vehicle: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
