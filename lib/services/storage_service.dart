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
    await service.syncFromCloud();
    return service;
  }

  /// Cleans out old sample vehicles without deleting user-entered tests
  Future<void> _seedInitialDataIfEmpty() async {
    final existingVehicles = getVehicles();
    final filteredVehicles = existingVehicles.where((v) {
      final isDemoId = v.id.startsWith('demo-') || v.id.startsWith('seed-') || v.id.startsWith('sample-');
      final isDemoEmail = v.ownerEmail.contains('example.com') || v.ownerEmail.contains('test.invalid');
      return !isDemoId && !isDemoEmail;
    }).toList();
    if (filteredVehicles.length != existingVehicles.length) {
      final list = filteredVehicles.map((v) => jsonEncode(v.toJson())).toList();
      await _prefs.setStringList(_keyVehicles, list);
    }

    final existingLogs = getGateLogs();
    final demoLogIds = {'log-1', 'log-2'};
    final filteredLogs = existingLogs.where((l) => !demoLogIds.contains(l.id)).toList();
    if (filteredLogs.length != existingLogs.length) {
      final list = filteredLogs.map((l) => jsonEncode(l.toJson())).toList();
      await _prefs.setStringList(_keyLogs, list);
    }

    // Auto-migrate any existing cached local records from university.edu.ph to isufst.edu.ph
    bool needsUpdate = false;
    final updatedVehicles = filteredVehicles.map((v) {
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
    // Cloud sync - directly await Firestore write
    if (_firestoreService != null) {
      await _firestoreService.saveVehicle(vehicle);
    }
  }

  /// Pulls registered vehicles from Cloud Firestore into local storage
  Future<void> syncFromCloud() async {
    final fs = _firestoreService;
    if (fs == null) return;
    try {
      final cloudVehicles = await fs.fetchVehicles();
      if (cloudVehicles.isNotEmpty) {
        final localVehicles = getVehicles();
        bool changed = false;
        for (final cv in cloudVehicles) {
          final index = localVehicles.indexWhere(
            (v) => v.normalizedPlate == cv.normalizedPlate || v.id == cv.id,
          );
          if (index < 0) {
            localVehicles.add(cv);
            changed = true;
          } else {
            localVehicles[index] = cv;
            changed = true;
          }
        }
        if (changed) {
          final rawList = localVehicles.map((v) => jsonEncode(v.toJson())).toList();
          await _prefs.setStringList(_keyVehicles, rawList);
        }
      }
    } catch (_) {}
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
    final seenIds = <String>{};
    final seenKeys = <String>{};
    final logs = <ScanLogModel>[];

    for (final jsonStr in list) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final log = ScanLogModel.fromJson(map);

        // Deduplicate by ID
        if (!seenIds.add(log.id)) continue;

        // Deduplicate accidental double submissions (same plate + log type within 5 seconds)
        final timeBucket = log.timestamp.millisecondsSinceEpoch ~/ 5000;
        final dupeKey = '${log.normalizedPlate}_${log.logType.name}_$timeBucket';
        if (!seenKeys.add(dupeKey)) continue;

        logs.add(log);
      } catch (_) {}
    }

    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    return logs;
  }

  Future<void> saveGateLog(ScanLogModel log) async {
    final logs = getGateLogs();
    // Guard against duplicates
    logs.removeWhere((l) => l.id == log.id);
    logs.insert(0, log);
    final rawList = logs.map((l) => jsonEncode(l.toJson())).toList();
    await _prefs.setStringList(_keyLogs, rawList);
    // Cloud sync
    if (_firestoreService != null) {
      await _firestoreService.saveGateLog(log);
    }
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
    if (_firestoreService != null) {
      await _firestoreService.saveVisitor(visitor);
    }
  }

  // --- CURRENT USER & REGISTERED ACCOUNTS ---
  static const String _keyKnownAccounts = 'plakado_known_accounts';

  static final Map<String, UserProfile> defaultKnownAccounts = {
    'student@isufst.edu.ph': UserProfile(
      id: 'test-student-id',
      name: 'Student Test User',
      email: 'student@isufst.edu.ph',
      role: UserRole.student,
      department: 'College of Informatics and Computing Innovations',
      idNumber: '2024-00101',
    ),
    'faculty@isufst.edu.ph': UserProfile(
      id: 'test-faculty-id',
      name: 'Prof. Faculty User',
      email: 'faculty@isufst.edu.ph',
      role: UserRole.faculty,
      department: 'College of Industrial Technology',
      idNumber: 'FAC-2024-001',
    ),
    'security@isufst.edu.ph': UserProfile(
      id: 'test-security-id',
      name: 'Officer Security Guard',
      email: 'security@isufst.edu.ph',
      role: UserRole.security,
      department: 'Campus Security Office',
      idNumber: 'SEC-2024-001',
    ),
  };

  List<UserProfile> getKnownAccounts() {
    final list = _prefs.getStringList(_keyKnownAccounts) ?? [];
    final accounts = <String, UserProfile>{};
    for (final entry in defaultKnownAccounts.entries) {
      accounts[entry.key] = entry.value;
    }
    for (final jsonStr in list) {
      try {
        final profile = UserProfile.fromJson(jsonDecode(jsonStr));
        accounts[profile.email.toLowerCase()] = profile;
      } catch (_) {}
    }
    return accounts.values.toList();
  }

  UserProfile? getAccountByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (defaultKnownAccounts.containsKey(normalized)) {
      return defaultKnownAccounts[normalized];
    }
    final all = getKnownAccounts();
    try {
      return all.firstWhere((a) => a.email.toLowerCase() == normalized);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveKnownAccount(UserProfile user) async {
    final accounts = getKnownAccounts();
    final index = accounts.indexWhere((a) => a.email.toLowerCase() == user.email.toLowerCase());
    if (index >= 0) {
      accounts[index] = user;
    } else {
      accounts.add(user);
    }
    final rawList = accounts.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_keyKnownAccounts, rawList);
    if (_firestoreService != null) {
      await _firestoreService.saveUser(user);
    }
  }

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
      await saveKnownAccount(user);
      await _prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
      if (_firestoreService != null) {
        await _firestoreService.saveUser(user);
      }
    }
  }
}
