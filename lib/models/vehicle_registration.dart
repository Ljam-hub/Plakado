import 'user_profile.dart';

enum RegistrationStatus {
  approved,
  pending,
  rejected,
  expired,
}

extension RegistrationStatusExtension on RegistrationStatus {
  String get label {
    switch (this) {
      case RegistrationStatus.approved:
        return 'Approved';
      case RegistrationStatus.pending:
        return 'Pending Verification';
      case RegistrationStatus.rejected:
        return 'Rejected';
      case RegistrationStatus.expired:
        return 'Expired Pass';
    }
  }
}

class VehicleRegistration {
  final String id;
  final String plateNumber;
  final String normalizedPlate;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final UserRole ownerRole;
  final String department;
  final String idNumber;
  final String vehicleType; // Car, Motorcycle, SUV, Van, E-Bike
  final String make; // Toyota, Honda, Yamaha
  final String model; // Vios, Click 125, Fortuner
  final String color;
  final RegistrationStatus status;
  final DateTime registeredAt;
  final DateTime? expiresAt;
  final String? rfidTag;

  VehicleRegistration({
    required this.id,
    required this.plateNumber,
    required this.normalizedPlate,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerRole,
    required this.department,
    required this.idNumber,
    required this.vehicleType,
    required this.make,
    required this.model,
    required this.color,
    this.status = RegistrationStatus.approved,
    required this.registeredAt,
    this.expiresAt,
    this.rfidTag,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'plateNumber': plateNumber,
        'normalizedPlate': normalizedPlate,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerRole': ownerRole.name,
        'department': department,
        'idNumber': idNumber,
        'vehicleType': vehicleType,
        'make': make,
        'model': model,
        'color': color,
        'status': status.name,
        'registeredAt': registeredAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'rfidTag': rfidTag,
      };

  factory VehicleRegistration.fromJson(Map<String, dynamic> json) {
    return VehicleRegistration(
      id: json['id'] as String,
      plateNumber: json['plateNumber'] as String,
      normalizedPlate: json['normalizedPlate'] as String? ??
          (json['plateNumber'] as String).replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase(),
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerEmail: json['ownerEmail'] as String,
      ownerRole: UserRole.values.firstWhere(
        (e) => e.name == json['ownerRole'],
        orElse: () => UserRole.student,
      ),
      department: json['department'] as String? ?? 'General',
      idNumber: json['idNumber'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? 'Car',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      color: json['color'] as String? ?? '',
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RegistrationStatus.approved,
      ),
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      rfidTag: json['rfidTag'] as String?,
    );
  }
}
