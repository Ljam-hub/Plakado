import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/vehicle_registration.dart';
import '../models/scan_log_model.dart';
import '../models/visitor_model.dart';
import '../utils/plate_formatter.dart';
import 'firestore_service.dart';

class StorageService {
  static const String _keyVehicles = 'plakado_vehicles';
  static const String _keyLogs = 'plakado_gate_logs';
  static const String _keyVisitors = 'plakado_visitors';
  static const String _keyCurrentUser = 'plakado_current_user';

  final SharedPreferences _prefs;
  final FirestoreService? _firestoreService;

  StorageService(this._prefs, [this._firestoreService]);

  static Future<StorageService> init([FirestoreService? firestoreService]) async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs, firestoreService);
    await service._seedInitialDataIfEmpty();
    return service;
  }

  /// Seeds realistic initial data so the app is immediately testable upon launch
  Future<void> _seedInitialDataIfEmpty() async {
    final existingVehicles = getVehicles();
    if (existingVehicles.isEmpty) {
      final seedVehicles = [
        VehicleRegistration(
          id: 'v-101',
          plateNumber: 'ABC 1234',
          normalizedPlate: 'ABC1234',
          ownerId: 'u-1',
          ownerName: 'Prof. Juan Dela Cruz',
          ownerEmail: 'juan.delacruz@isufst.edu.ph',
          ownerRole: UserRole.faculty,
          department: 'College of Computer Studies',
          idNumber: 'FAC-2018-042',
          vehicleType: 'Car (Sedan)',
          make: 'Toyota',
          model: 'Vios 1.5G',
          color: 'Pearl White',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 90)),
        ),
        VehicleRegistration(
          id: 'v-102',
          plateNumber: 'XYZ 8888',
          normalizedPlate: 'XYZ8888',
          ownerId: 'u-2',
          ownerName: 'Maria Santos',
          ownerEmail: 'maria.santos@student.isufst.edu.ph',
          ownerRole: UserRole.student,
          department: 'College of Engineering',
          idNumber: '2023-10492-MN-0',
          vehicleType: 'SUV',
          make: 'Mitsubishi',
          model: 'Montero Sport',
          color: 'Titanium Gray',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 45)),
        ),
        VehicleRegistration(
          id: 'v-103',
          plateNumber: 'ND 45912',
          normalizedPlate: 'ND45912',
          ownerId: 'u-3',
          ownerName: 'Carlo Mendoza',
          ownerEmail: 'carlo.mendoza@student.isufst.edu.ph',
          ownerRole: UserRole.student,
          department: 'College of Business Administration',
          idNumber: '2024-00122-TG-0',
          vehicleType: 'Motorcycle',
          make: 'Honda',
          model: 'Click 125i',
          color: 'Matte Blue',
          status: RegistrationStatus.approved,
          registeredAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

      for (final v in seedVehicles) {
        await saveVehicle(v);
      }

      // Initial gate scan logs
      final seedLogs = [
        ScanLogModel(
          id: 'log-1',
          plateNumber: 'ABC 1234',
          normalizedPlate: 'ABC1234',
          timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
          logType: GateLogType.entry,
          accessStatus: AccessStatus.authorized,
          driverName: 'Prof. Juan Dela Cruz',
          userRole: UserRole.faculty,
          department: 'College of Computer Studies',
          vehicleInfo: 'Toyota Vios (Pearl White)',
          officerNotes: 'Scanned via ALPR Gate 1',
        ),
        ScanLogModel(
          id: 'log-2',
          plateNumber: 'XYZ 8888',
          normalizedPlate: 'XYZ8888',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          logType: GateLogType.entry,
          accessStatus: AccessStatus.authorized,
          driverName: 'Maria Santos',
          userRole: UserRole.student,
          department: 'College of Engineering',
          vehicleInfo: 'Mitsubishi Montero Sport',
          officerNotes: 'Scanned via ALPR Gate 2',
        ),
      ];

      for (final l in seedLogs) {
        await saveGateLog(l);
      }
    } else {
      // Auto-migrate any existing cached local records from university.edu.ph to isufst.edu.ph
      bool needsUpdate = false;
      final updatedVehicles = existingVehicles.map((v) {
        if (v.ownerEmail.contains('university.edu.ph')) {
          needsUpdate = true;
          return VehicleRegistration(
            id: v.id,
            plateNumber: v.plateNumber,
            normalizedPlate: v.normalizedPlate,
            ownerId: v.ownerId,
            ownerName: v.ownerName,
            ownerEmail: v.ownerEmail.replaceAll('university.edu.ph', 'isufst.edu.ph'),
            ownerRole: v.ownerRole,
            department: v.department,
            idNumber: v.idNumber,
            vehicleType: v.vehicleType,
            make: v.make,
            model: v.model,
            color: v.color,
            status: v.status,
            registeredAt: v.registeredAt,
          );
        }
        return v;
      }).toList();

      if (needsUpdate) {
        final list = updatedVehicles.map((v) => jsonEncode(v.toJson())).toList();
        await _prefs.setStringList(_keyVehicles, list);
      }

      final currentUser = getCurrentUser();
      if (currentUser != null && currentUser.email.contains('university.edu.ph')) {
        final migratedUser = UserProfile(
          id: currentUser.id,
          name: currentUser.name,
          email: currentUser.email.replaceAll('university.edu.ph', 'isufst.edu.ph'),
          role: currentUser.role,
          department: currentUser.department,
          idNumber: currentUser.idNumber,
          contactNumber: currentUser.contactNumber,
          photoUrl: currentUser.photoUrl,
        );
        await setCurrentUser(migratedUser);
      }
    }
  }

  // --- VEHICLES ---
  List<VehicleRegistration> getVehicles() {
    final list = _prefs.getStringList(_keyVehicles) ?? [];
    return list.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return VehicleRegistration.fromJson(map);
    }).toList();
  }

  Future<void> saveVehicle(VehicleRegistration vehicle) async {
    final vehicles = getVehicles();
    final index = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) {
      vehicles[index] = vehicle;
    } else {
      vehicles.insert(0, vehicle);
    }
    final rawList = vehicles.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyVehicles, rawList);
    // Cloud sync
    _firestoreService?.saveVehicle(vehicle);
  }

  VehicleRegistration? findVehicleByPlate(String plate) {
    final normalized = PlateFormatter.normalize(plate);
    if (normalized.isEmpty) return null;
    final vehicles = getVehicles();
    try {
      return vehicles.firstWhere(
        (v) => v.normalizedPlate == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  List<VehicleRegistration> getVehiclesByOwner(String ownerEmail) {
    return getVehicles()
        .where((v) => v.ownerEmail.toLowerCase() == ownerEmail.toLowerCase())
        .toList();
  }

  /// Updates owner info on all vehicles registered by this user
  Future<void> updateOwnerVehicles(UserProfile user) async {
    final vehicles = getVehicles();
    bool changed = false;
    for (int i = 0; i < vehicles.length; i++) {
      if (vehicles[i].ownerId == user.id ||
          vehicles[i].ownerEmail.toLowerCase() == user.email.toLowerCase()) {
        vehicles[i] = VehicleRegistration(
          id: vehicles[i].id,
          plateNumber: vehicles[i].plateNumber,
          normalizedPlate: vehicles[i].normalizedPlate,
          ownerId: user.id,
          ownerName: user.name,
          ownerEmail: user.email,
          ownerRole: user.role,
          department: user.department,
          idNumber: user.idNumber,
          vehicleType: vehicles[i].vehicleType,
          make: vehicles[i].make,
          model: vehicles[i].model,
          color: vehicles[i].color,
          status: vehicles[i].status,
          registeredAt: vehicles[i].registeredAt,
          expiresAt: vehicles[i].expiresAt,
          rfidTag: vehicles[i].rfidTag,
        );
        _firestoreService?.saveVehicle(vehicles[i]);
        changed = true;
      }
    }
    if (changed) {
      final rawList = vehicles.map((v) => jsonEncode(v.toJson())).toList();
      await _prefs.setStringList(_keyVehicles, rawList);
    }
  }

  // --- GATE LOGS ---
  List<ScanLogModel> getGateLogs() {
    final list = _prefs.getStringList(_keyLogs) ?? [];
    final logs = list.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ScanLogModel.fromJson(map);
    }).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    return logs;
  }

  Future<void> saveGateLog(ScanLogModel log) async {
    final logs = getGateLogs();
    logs.insert(0, log);
    final rawList = logs.map((l) => jsonEncode(l.toJson())).toList();
    await _prefs.setStringList(_keyLogs, rawList);
    // Cloud sync
    _firestoreService?.saveGateLog(log);
  }

  // --- VISITORS ---
  List<VisitorModel> getVisitors() {
    final list = _prefs.getStringList(_keyVisitors) ?? [];
    return list.map((jsonStr) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return VisitorModel.fromJson(map);
    }).toList();
  }

  Future<void> saveVisitor(VisitorModel visitor) async {
    final visitors = getVisitors();
    visitors.insert(0, visitor);
    final rawList = visitors.map((v) => jsonEncode(v.toJson())).toList();
    await _prefs.setStringList(_keyVisitors, rawList);
    // Cloud sync
    _firestoreService?.saveVisitor(visitor);
  }

  // --- CURRENT USER ---
  UserProfile? getCurrentUser() {
    final jsonStr = _prefs.getString(_keyCurrentUser);
    if (jsonStr == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentUser(UserProfile? user) async {
    if (user == null) {
      await _prefs.remove(_keyCurrentUser);
    } else {
      await _prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
      _firestoreService?.saveUser(user);
    }
  }
}
