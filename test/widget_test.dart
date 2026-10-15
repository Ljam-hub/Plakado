import 'package:flutter_test/flutter_test.dart';
import 'package:plakado/utils/plate_formatter.dart';
import 'package:plakado/services/otp_service.dart';

void main() {
  group('PlateFormatter & ALPR Tests', () {
    test('Normalizes plate characters', () {
      expect(PlateFormatter.normalize('abc-1234'), 'ABC1234');
      expect(PlateFormatter.normalize('  xyz 8888  '), 'XYZ8888');
    });

    test('Formats 4-wheel plate for display', () {
      expect(PlateFormatter.formatDisplay('ABC1234'), 'ABC 1234');
      expect(PlateFormatter.formatDisplay('abc-1234'), 'ABC 1234');
    });

    test('Formats motorcycle plate for display', () {
      expect(PlateFormatter.formatDisplay('123ABC'), '123 ABC');
      expect(PlateFormatter.formatDisplay('NA12345'), 'NA 12345');
    });

    test('Extracts plate candidate from noisy OCR text', () {
      const noisyOcr = 'CAMPUS GATE 1\nSPEED LIMIT 15\nABC 1234\nNCR PHILIPPINES';
      final candidate = PlateFormatter.extractPlateCandidate(noisyOcr);
      expect(candidate, 'ABC 1234');
    });

    test('Validates plate format structure', () {
      expect(PlateFormatter.isValidPlate('ABC 1234'), isTrue);
      expect(PlateFormatter.isValidPlate('123 ABC'), isTrue);
      expect(PlateFormatter.isValidPlate('INVALID'), isFalse);
    });
  });

  group('OtpService Verification & Security Tests', () {
    final otpService = OtpService();
    const testEmail = 'student@isufst.edu.ph';

    test('Generates a 6-digit cryptographic OTP code', () {
      final code = otpService.generateOtp(testEmail);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('Rejects invalid or mismatched OTP code', () {
      otpService.generateOtp(testEmail);
      final result = otpService.verifyOtp(testEmail, '000000');
      expect(result.isValid, isFalse);
    });

    test('Successfully verifies correct OTP code', () {
      final code = otpService.generateOtp(testEmail);
      final result = otpService.verifyOtp(testEmail, code);
      expect(result.isValid, isTrue);
      expect(result.message, contains('successful'));
    });

    test('Prevents replay attack by invalidating code after successful verification', () {
      final code = otpService.generateOtp(testEmail);
      final firstCheck = otpService.verifyOtp(testEmail, code);
      expect(firstCheck.isValid, isTrue);

      final secondCheck = otpService.verifyOtp(testEmail, code);
      expect(secondCheck.isValid, isFalse);
    });

    test('Enforces attempt limits and decrements remaining tries on failure', () {
      otpService.generateOtp(testEmail);
      final failed1 = otpService.verifyOtp(testEmail, '111111');
      expect(failed1.isValid, isFalse);
      expect(failed1.message, contains('2 attempts remaining'));
    });
  });

  group('ISUFST Domain Security Restriction Tests', () {
    bool isIsufstEmail(String email) {
      final clean = email.trim().toLowerCase();
      return clean.contains('@') && clean.endsWith('isufst.edu.ph');
    }

    test('Permits official ISUFST faculty and administration emails', () {
      expect(isIsufstEmail('juan.delacruz@isufst.edu.ph'), isTrue);
      expect(isIsufstEmail('admin@isufst.edu.ph'), isTrue);
      expect(isIsufstEmail('security@isufst.edu.ph'), isTrue);
    });

    test('Permits official ISUFST student portal emails', () {
      expect(isIsufstEmail('maria.santos@student.isufst.edu.ph'), isTrue);
      expect(isIsufstEmail('2023-10492@student.isufst.edu.ph'), isTrue);
    });

    test('Strictly rejects non-ISUFST and public emails', () {
      expect(isIsufstEmail('someone@gmail.com'), isFalse);
      expect(isIsufstEmail('student@up.edu.ph'), isFalse);
      expect(isIsufstEmail('faculty@pup.edu.ph'), isFalse);
      expect(isIsufstEmail('intruder@yahoo.com'), isFalse);
    });
  });
}

