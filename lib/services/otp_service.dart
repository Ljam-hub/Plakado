import 'dart:math';

class OtpRecord {
  final String email;
  final String code;
  final DateTime expiresAt;
  int attemptsLeft;

  OtpRecord({
    required this.email,
    required this.code,
    required this.expiresAt,
    this.attemptsLeft = 3,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class OtpService {
  final Map<String, OtpRecord> _activeCodes = {};

  /// Generates a secure 6-digit verification code valid for 60 seconds
  String generateOtp(String email) {
    final normalized = email.trim().toLowerCase();
    // Cryptographically random 6-digit code
    final random = Random.secure();
    final code = (100000 + random.nextInt(900000)).toString();

    _activeCodes[normalized] = OtpRecord(
      email: normalized,
      code: code,
      expiresAt: DateTime.now().add(const Duration(seconds: 60)),
      attemptsLeft: 3,
    );

    return code;
  }

  /// Verifies the entered 6-digit code for the specified email
  OtpVerificationResult verifyOtp(String email, String enteredCode) {
    final normalized = email.trim().toLowerCase();
    final record = _activeCodes[normalized];

    if (record == null) {
      return OtpVerificationResult(
        isValid: false,
        message: 'No verification code was requested for this email. Please request a new code.',
      );
    }

    if (record.isExpired) {
      _activeCodes.remove(normalized);
      return OtpVerificationResult(
        isValid: false,
        message: 'Verification code has expired. Please request a fresh code.',
      );
    }

    if (record.attemptsLeft <= 0) {
      _activeCodes.remove(normalized);
      return OtpVerificationResult(
        isValid: false,
        message: 'Maximum verification attempts exceeded. Please request a new code.',
      );
    }

    if (record.code.trim() != enteredCode.trim()) {
      record.attemptsLeft--;
      return OtpVerificationResult(
        isValid: false,
        message: 'Invalid verification code. ${record.attemptsLeft} attempts remaining.',
      );
    }

    // Success: code verified, remove one-time token
    _activeCodes.remove(normalized);
    return OtpVerificationResult(
      isValid: true,
      message: 'Code verified successfully.',
    );
  }
}

class OtpVerificationResult {
  final bool isValid;
  final String message;

  OtpVerificationResult({
    required this.isValid,
    required this.message,
  });
}
