import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/otp_service.dart';
import '../services/email_service.dart';

class AuthController extends ChangeNotifier {
  final StorageService _storageService;
  final OtpService _otpService;
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastGeneratedOtp;

  AuthController(this._storageService, [OtpService? otpService])
      : _otpService = otpService ?? OtpService() {
    _currentUser = _storageService.getCurrentUser();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastGeneratedOtp => _lastGeneratedOtp;

  UserRole get currentRole => _currentUser?.role ?? UserRole.student;

  /// Requests a 6-digit email OTP verification code and dispatches to inbox via Resend API
  String requestVerificationCode(String email) {
    final code = _otpService.generateOtp(email);
    debugPrint('ISUFST Gate Security OTP generated for $email: $code');
    // Dispatch real email via Resend API in the background
    EmailService.sendVerificationOtp(recipientEmail: email, code: code);
    notifyListeners();
    return code;
  }

  /// Verifies the 6-digit OTP code and signs in with ISUFST School Gmail credentials.
  Future<bool> verifyOtpAndSignIn({
    required String email,
    required String code,
    required String name,
    required UserRole role,
    String? idNumber,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Network simulation

      final normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail.contains('@') || !normalizedEmail.endsWith('isufst.edu.ph')) {
        _errorMessage = 'Access restricted: Please use your official ISUFST account (@isufst.edu.ph)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final verification = _otpService.verifyOtp(email, code);
      if (!verification.isValid) {
        _errorMessage = verification.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = UserProfile(
        id: const Uuid().v4(),
        name: name.trim().isEmpty ? 'ISUFST Campus User' : name.trim(),
        email: normalizedEmail,
        role: role,
        department: department?.trim() ?? (role == UserRole.security ? 'Campus Security' : 'General'),
        idNumber: idNumber?.trim() ?? (role == UserRole.student ? '2024-0001' : 'FAC-1001'),
      );

      _currentUser = profile;
      await _storageService.setCurrentUser(profile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Authentication error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Signs in with ISUFST School Gmail credentials (@isufst.edu.ph).
  Future<bool> signInWithSchoolGoogle({
    required String email,
    required String name,
    required UserRole role,
    String? idNumber,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Network simulation

      final normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail.contains('@') || !normalizedEmail.endsWith('isufst.edu.ph')) {
        _errorMessage = 'Access restricted: Please use your official ISUFST email address (@isufst.edu.ph)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = UserProfile(
        id: const Uuid().v4(),
        name: name.trim().isEmpty ? 'Campus User' : name.trim(),
        email: normalizedEmail,
        role: role,
        department: department?.trim() ?? (role == UserRole.security ? 'Campus Security' : 'General'),
        idNumber: idNumber?.trim() ?? (role == UserRole.student ? '2024-0001' : 'FAC-1001'),
      );

      _currentUser = profile;
      await _storageService.setCurrentUser(profile);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Authentication failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Switch roles for demo and multi-user testing
  Future<void> switchRole(UserRole newRole) async {
    if (_currentUser == null) return;

    final updated = UserProfile(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: newRole,
      department: newRole == UserRole.security ? 'Campus Security Office' : _currentUser!.department,
      idNumber: _currentUser!.idNumber,
      contactNumber: _currentUser!.contactNumber,
      photoUrl: _currentUser!.photoUrl,
    );

    _currentUser = updated;
    await _storageService.setCurrentUser(updated);
    notifyListeners();
  }

  /// Updates user profile credentials (name, email, id, department, phone)
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String idNumber,
    required String department,
    String? contactNumber,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail.contains('@') || !normalizedEmail.endsWith('isufst.edu.ph')) {
        _errorMessage = 'Please enter a valid ISUFST email address (@isufst.edu.ph)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updated = UserProfile(
        id: _currentUser!.id,
        name: name.trim().isEmpty ? _currentUser!.name : name.trim(),
        email: normalizedEmail,
        role: _currentUser!.role,
        department: department.trim(),
        idNumber: idNumber.trim(),
        contactNumber: contactNumber?.trim(),
        photoUrl: _currentUser!.photoUrl,
      );

      _currentUser = updated;
      await _storageService.setCurrentUser(updated);
      await _storageService.updateOwnerVehicles(updated);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update credentials: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    await _storageService.setCurrentUser(null);
    notifyListeners();
  }
}
