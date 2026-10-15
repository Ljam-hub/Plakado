enum UserRole {
  student,
  faculty,
  security,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.faculty:
        return 'Faculty / Staff';
      case UserRole.security:
        return 'Security Officer';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get idLabel {
    switch (this) {
      case UserRole.student:
        return 'Student ID';
      case UserRole.faculty:
        return 'Employee ID';
      case UserRole.security:
        return 'Badge ID';
      case UserRole.admin:
        return 'Admin ID';
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String department;
  final String idNumber;
  final String? contactNumber;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.idNumber,
    this.contactNumber,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'department': department,
        'idNumber': idNumber,
        'contactNumber': contactNumber,
        'photoUrl': photoUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      department: json['department'] as String? ?? 'General',
      idNumber: json['idNumber'] as String? ?? '',
      contactNumber: json['contactNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
