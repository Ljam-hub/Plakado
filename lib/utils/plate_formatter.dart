import 'dart:convert';

/// Represents parsed Digital Gate Pass metadata from QR Code
class QrGatePassData {
  final String plate;
  final String owner;
  final String role;
  final String idNumber;
  final String status;
  final String? department;
  final String? vehicleType;
  final String? make;
  final String? model;
  final String? color;

  QrGatePassData({
    required this.plate,
    required this.owner,
    required this.role,
    required this.idNumber,
    required this.status,
    this.department,
    this.vehicleType,
    this.make,
    this.model,
    this.color,
  });

  bool get isApproved => status.toLowerCase() == 'approved';

  static QrGatePassData? tryParse(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return null;

    // Check if JSON format (e.g., {"plate":"574BSK","owner":"Lejon Osial","role":"student","id":"2023-10492","status":"approved"})
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.contains('{') && trimmed.contains('}'))) {
      try {
        final startIndex = trimmed.indexOf('{');
        final endIndex = trimmed.lastIndexOf('}') + 1;
        final jsonSub = trimmed.substring(startIndex, endIndex);
        final map = jsonDecode(jsonSub);
        if (map is Map<String, dynamic> || map is Map) {
          final plate = map['plate'] ?? map['plateNumber'] ?? map['plate_number'];
          if (plate != null && plate.toString().trim().isNotEmpty) {
            return QrGatePassData(
              plate: PlateFormatter.normalize(plate.toString()),
              owner: map['owner']?.toString() ?? map['ownerName']?.toString() ?? 'Student Pass Holder',
              role: map['role']?.toString() ?? map['ownerRole']?.toString() ?? 'student',
              idNumber: map['id']?.toString() ?? map['idNumber']?.toString() ?? '',
              status: map['status']?.toString() ?? 'approved',
              department: map['department']?.toString(),
              vehicleType: map['vehicleType']?.toString(),
              make: map['make']?.toString(),
              model: map['model']?.toString(),
              color: map['color']?.toString(),
            );
          }
        }
      } catch (_) {}
    }

    // Check if URL or query parameter format (e.g. ?plate=574BSK&owner=Lejon...)
    if (trimmed.contains('plate=')) {
      try {
        final uri = Uri.tryParse(trimmed);
        if (uri != null && uri.queryParameters.containsKey('plate')) {
          final q = uri.queryParameters;
          return QrGatePassData(
            plate: PlateFormatter.normalize(q['plate']!),
            owner: q['owner'] ?? 'Student Pass Holder',
            role: q['role'] ?? 'student',
            idNumber: q['id'] ?? '',
            status: q['status'] ?? 'approved',
            department: q['department'],
            vehicleType: q['vehicleType'],
            make: q['make'],
            model: q['model'],
            color: q['color'],
          );
        }
      } catch (_) {}
    }

    return null;
  }
}

class PlateFormatter {
  /// Cleans raw text into a normalized alphanumeric plate string
  static String normalize(String raw) {
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase().trim();
  }

  /// Formats plate nicely for display (e.g., 'ABC1234' -> 'ABC 1234')
  static String formatDisplay(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.isEmpty) return '';

    // Standard 3 letters + 4 numbers: ABC 1234
    final standard4Wheel = RegExp(r'^([A-Z]{3})(\d{3,4})$');
    if (standard4Wheel.hasMatch(cleaned)) {
      final match = standard4Wheel.firstMatch(cleaned)!;
      return '${match.group(1)} ${match.group(2)}';
    }

    // Motorcycle standard 3 numbers + 3 letters: 123 ABC
    final mcType1 = RegExp(r'^(\d{3})([A-Z]{3})$');
    if (mcType1.hasMatch(cleaned)) {
      final match = mcType1.firstMatch(cleaned)!;
      return '${match.group(1)} ${match.group(2)}';
    }

    // Motorcycle standard 2 letters + 5 numbers: NA 12345
    final mcType2 = RegExp(r'^([A-Z]{2})(\d{4,5})$');
    if (mcType2.hasMatch(cleaned)) {
      final match = mcType2.firstMatch(cleaned)!;
      return '${match.group(1)} ${match.group(2)}';
    }

    // Older 3 letters + 3 numbers: ABC 123
    final older3Wheel = RegExp(r'^([A-Z]{3})(\d{3})$');
    if (older3Wheel.hasMatch(cleaned)) {
      final match = older3Wheel.firstMatch(cleaned)!;
      return '${match.group(1)} ${match.group(2)}';
    }

    return cleaned;
  }

  /// Checks if plate matches standard vehicle plate format
  static bool isValidPlate(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.length < 5 || cleaned.length > 8) return false;

    // Checks combinations of letters and digits
    final hasLetters = RegExp(r'[A-Z]').hasMatch(cleaned);
    final hasDigits = RegExp(r'[0-9]').hasMatch(cleaned);

    return hasLetters && hasDigits;
  }

  /// Extracts the most likely license plate string from raw OCR text or QR code payload
  static String? extractPlateCandidate(String rawOcrText) {
    final trimmed = rawOcrText.trim();
    if (trimmed.isEmpty) return null;

    // Priority 0: Check if input is a Digital Gate Pass QR payload
    final qrData = QrGatePassData.tryParse(trimmed);
    if (qrData != null && qrData.plate.isNotEmpty) {
      return formatDisplay(qrData.plate);
    }

    final lines = trimmed
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Priority 1: Check for exact plate regex patterns line-by-line
    final platePatterns = [
      RegExp(r'\b[A-Z]{3}\s*[-]?\s*\d{4}\b', caseSensitive: false), // ABC 1234
      RegExp(r'\b[A-Z]{3}\s*[-]?\s*\d{3}\b', caseSensitive: false), // ABC 123
      RegExp(r'\b\d{3}\s*[-]?\s*[A-Z]{3}\b', caseSensitive: false), // 123 ABC
      RegExp(r'\b[A-Z]{2}\s*[-]?\s*\d{4,5}\b', caseSensitive: false), // NA 12345
    ];

    for (final line in lines) {
      for (final pattern in platePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final candidate = match.group(0)!;
          return formatDisplay(candidate);
        }
      }
    }

    // Priority 2: Clean tokens and evaluate candidates
    final tokens = trimmed
        .replaceAll(RegExp(r'[^A-Za-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 5 && t.length <= 8)
        .toList();

    for (final token in tokens) {
      if (isValidPlate(token)) {
        return formatDisplay(token);
      }
    }

    return null;
  }

  /// Fixes common OCR optical illusions (e.g. O instead of 0 in digit position)
  static String disambiguate(String text, bool isLetterPosition) {
    if (isLetterPosition) {
      return text
          .replaceAll('0', 'O')
          .replaceAll('1', 'I')
          .replaceAll('8', 'B')
          .replaceAll('5', 'S');
    } else {
      return text
          .replaceAll('O', '0')
          .replaceAll('I', '1')
          .replaceAll('B', '8')
          .replaceAll('S', '5')
          .replaceAll('Z', '2');
    }
  }
}
