import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_log_model.dart';
import '../models/visitor_model.dart';
import '../models/vehicle_registration.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../utils/plate_formatter.dart';

class GateLogController extends ChangeNotifier {
  final StorageService _storageService;
  List<ScanLogModel> _logs = [];
  List<VisitorModel> _visitors = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';

  GateLogController(this._storageService) {
    refreshLogs();
  }

  List<ScanLogModel> get allLogs => _logs;
  List<VisitorModel> get allVisitors => _visitors;
  String get searchQuery => _searchQuery;
  String get selectedRoleFilter => _selectedRoleFilter;

  void refreshLogs() {
    _logs = _storageService.getGateLogs();
    _visitors = _storageService.getVisitors();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setRoleFilter(String filter) {
    _selectedRoleFilter = filter;
    notifyListeners();
  }

  List<ScanLogModel> get filteredLogs {
    return _logs.where((log) {
      // Role filter
      if (_selectedRoleFilter != 'ALL') {
        if (_selectedRoleFilter == 'STUDENT' && log.userRole != UserRole.student) return false;
        if (_selectedRoleFilter == 'FACULTY' && log.userRole != UserRole.faculty) return false;
        if (_selectedRoleFilter == 'VISITOR' && log.accessStatus != AccessStatus.visitor) return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final matchesPlate = log.plateNumber.toLowerCase().contains(_searchQuery);
        final matchesDriver = log.driverName.toLowerCase().contains(_searchQuery);
        final matchesDept = (log.department ?? '').toLowerCase().contains(_searchQuery);
        return matchesPlate || matchesDriver || matchesDept;
      }

      return true;
    }).toList();
  }

  // --- Quick Stats ---
  int get totalEntriesToday {
    final now = DateTime.now();
    return _logs.where((l) =>
        l.timestamp.year == now.year &&
        l.timestamp.month == now.month &&
        l.timestamp.day == now.day &&
        l.logType == GateLogType.entry).length;
  }

  int get studentCountToday => _logs.where((l) => l.userRole == UserRole.student).length;
  int get facultyCountToday => _logs.where((l) => l.userRole == UserRole.faculty).length;
  int get visitorCountToday => _logs.where((l) => l.accessStatus == AccessStatus.visitor).length;

  /// Logs entry for an authorized vehicle
  Future<void> logAuthorizedEntry(VehicleRegistration vehicle, {String? notes}) async {
    final now = DateTime.now();

    // Guard against accidental double clicks / duplicate submissions within 5 seconds
    if (_logs.isNotEmpty) {
      final recent = _logs.first;
      if (recent.normalizedPlate == vehicle.normalizedPlate &&
          recent.logType == GateLogType.entry &&
          now.difference(recent.timestamp).inSeconds < 5) {
        debugPrint('Duplicate entry log suppressed for ${vehicle.plateNumber}');
        return;
      }
    }

    final log = ScanLogModel(
      id: const Uuid().v4(),
      plateNumber: vehicle.plateNumber,
      normalizedPlate: vehicle.normalizedPlate,
      timestamp: now,
      logType: GateLogType.entry,
      accessStatus: AccessStatus.authorized,
      driverName: vehicle.ownerName,
      userRole: vehicle.ownerRole,
      department: vehicle.department,
      vehicleInfo: '${vehicle.make} ${vehicle.model} (${vehicle.color})',
      officerNotes: notes ?? 'Authorized ALPR entry',
    );

    await _storageService.saveGateLog(log);
    refreshLogs();
  }

  /// Logs exit for an authorized vehicle
  Future<void> logAuthorizedExit(VehicleRegistration vehicle, {String? notes}) async {
    final now = DateTime.now();

    // Guard against accidental double clicks / duplicate submissions within 5 seconds
    if (_logs.isNotEmpty) {
      final recent = _logs.first;
      if (recent.normalizedPlate == vehicle.normalizedPlate &&
          recent.logType == GateLogType.exit &&
          now.difference(recent.timestamp).inSeconds < 5) {
        debugPrint('Duplicate exit log suppressed for ${vehicle.plateNumber}');
        return;
      }
    }

    final log = ScanLogModel(
      id: const Uuid().v4(),
      plateNumber: vehicle.plateNumber,
      normalizedPlate: vehicle.normalizedPlate,
      timestamp: now,
      logType: GateLogType.exit,
      accessStatus: AccessStatus.authorized,
      driverName: vehicle.ownerName,
      userRole: vehicle.ownerRole,
      department: vehicle.department,
      vehicleInfo: '${vehicle.make} ${vehicle.model} (${vehicle.color})',
      officerNotes: notes ?? 'ALPR exit logged',
    );

    await _storageService.saveGateLog(log);
    refreshLogs();
  }

  /// Registers a visitor and records their gate entry
  Future<void> registerVisitorEntry({
    required String plateNumber,
    required String visitorName,
    required String contactNumber,
    required String purpose,
    required String destinationBuilding,
    required String passNumber,
    String? idPresented,
  }) async {
    final formattedPlate = PlateFormatter.formatDisplay(plateNumber);
    final norm = PlateFormatter.normalize(formattedPlate);
    final now = DateTime.now();

    // Guard against accidental duplicate visitor submission within 5 seconds
    if (_logs.isNotEmpty) {
      final recent = _logs.first;
      if (recent.normalizedPlate == norm &&
          recent.logType == GateLogType.entry &&
          now.difference(recent.timestamp).inSeconds < 5) {
        debugPrint('Duplicate visitor entry log suppressed for $formattedPlate');
        return;
      }
    }

    final visitor = VisitorModel(
      id: const Uuid().v4(),
      plateNumber: formattedPlate,
      visitorName: visitorName.trim(),
      contactNumber: contactNumber.trim(),
      purpose: purpose.trim(),
      destinationBuilding: destinationBuilding.trim(),
      passNumber: passNumber.trim(),
      idPresented: idPresented,
      timeIn: now,
    );

    await _storageService.saveVisitor(visitor);

    // Also record in gate scan logs
    final log = ScanLogModel(
      id: const Uuid().v4(),
      plateNumber: formattedPlate,
      normalizedPlate: norm,
      timestamp: now,
      logType: GateLogType.entry,
      accessStatus: AccessStatus.visitor,
      driverName: visitorName.trim(),
      userRole: null,
      department: destinationBuilding.trim(),
      vehicleInfo: 'Visitor Pass #$passNumber',
      officerNotes: 'Purpose: $purpose | Contact: $contactNumber',
    );

    await _storageService.saveGateLog(log);
    refreshLogs();
  }
}
