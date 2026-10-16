import 'user_profile.dart';

enum GateLogType {
  entry,
  exit,
}

enum AccessStatus {
  authorized,
  visitor,
  denied,
}

extension AccessStatusExtension on AccessStatus {
  String get label {
    switch (this) {
      case AccessStatus.authorized:
        return 'Authorized (Student / Faculty)';
      case AccessStatus.visitor:
        return 'Visitor / Guest';
      case AccessStatus.denied:
        return 'Access Denied';
    }
  }
}

class ScanLogModel {
  final String id;
  final String plateNumber;
  final String normalizedPlate;
  final DateTime timestamp;
  final GateLogType logType;
  final AccessStatus accessStatus;
  final String driverName;
  final UserRole? userRole;
  final String? department;
  final String? vehicleInfo;
  final String? gateName;
  final String? officerNotes;

  ScanLogModel({
    required this.id,
    required this.plateNumber,
    required this.normalizedPlate,
    required this.timestamp,
    required this.logType,
    required this.accessStatus,
    required this.driverName,
    this.userRole,
    this.department,
    this.vehicleInfo,
    this.gateName = 'Main Entrance',
    this.officerNotes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'normalizedPlate': normalizedPlate,
        'timestamp': timestamp.toIso8601String(),
        'logType': logType.name,
        'accessStatus': accessStatus.name,
        'driverName': driverName,
        'userRole': userRole?.name,
        'department': department,
        'vehicleInfo': vehicleInfo,
        'gateName': gateName,
        'officerNotes': officerNotes,
      };

  factory ScanLogModel.fromJson(Map<String, dynamic> json) {
    return ScanLogModel(
      id: json['id'] as String,
      plateNumber: json['plateNumber'] as String,
      normalizedPlate: json['normalizedPlate'] as String? ??
          (json['plateNumber'] as String).replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      logType: GateLogType.values.firstWhere(
        (e) => e.name == json['logType'],
        orElse: () => GateLogType.entry,
      ),
      accessStatus: AccessStatus.values.firstWhere(
        (e) => e.name == json['accessStatus'],
        orElse: () => AccessStatus.authorized,
      ),
      driverName: json['driverName'] as String,
      userRole: json['userRole'] != null
          ? UserRole.values.firstWhere((e) => e.name == json['userRole'])
          : null,
      department: json['department'] as String?,
      vehicleInfo: json['vehicleInfo'] as String?,
      gateName: json['gateName'] as String? ?? 'Main Entrance',
      officerNotes: json['officerNotes'] as String?,
    );
  }
}
