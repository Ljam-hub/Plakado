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
  /// Prevents false positives from hex hashes (e.g. B2F9D27D), UUIDs, timestamps, or system filenames.
  static bool isValidPlate(String raw) {
    final cleaned = normalize(raw);
    if (cleaned.length < 5 || cleaned.length > 8) return false;

    // Reject obvious hex GUID segments / alternating hex patterns
    if (RegExp(r'^[A-F0-9]{8}$', caseSensitive: false).hasMatch(cleaned) &&
        !RegExp(r'^[A-Z]{3}\d{4}$|^[A-Z]{3}\d{3}$|^\d{3}[A-Z]{3}$').hasMatch(cleaned)) {
      // If it looks like an 8-char hex string that doesn't follow standard plate groupings, reject
      if (RegExp(r'\d[A-Z]\d|[A-Z]\d[A-Z]').hasMatch(cleaned)) return false;
    }

    // 1. Standard 4-wheel (3 letters + 4 digits): ABC 1234
    if (RegExp(r'^[A-Z]{3}\d{4}$').hasMatch(cleaned)) return true;

    // 2. Older 4-wheel (3 letters + 3 digits): ABC 123
    if (RegExp(r'^[A-Z]{3}\d{3}$').hasMatch(cleaned)) return true;

    // 3. Standard motorcycle (3 digits + 3 letters): 574 BSK or 123 ABC
    if (RegExp(r'^\d{3}[A-Z]{3}$').hasMatch(cleaned)) return true;

    // 4. Motorcycle 2-letter (2 letters + 4 or 5 digits): NA 12345 or NA 1234
    if (RegExp(r'^[A-Z]{2}\d{4,5}$').hasMatch(cleaned)) return true;

    // 5. Special / Trailer (1 letter + 4 or 5 digits): U 12345
    if (RegExp(r'^[A-Z]\d{4,5}$').hasMatch(cleaned)) return true;

    // 6. Legacy MV (4 digits + 2 letters): 1234 AB
    if (RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(cleaned)) return true;

    // 7. Temporary / virtual plate: 2 letters + 3 digits + 1 letter (e.g. MV123A)
    if (RegExp(r'^[A-Z]{2}\d{3}[A-Z]$').hasMatch(cleaned)) return true;

    // 8. Special Protocol (3 letters + 2 digits)
    if (RegExp(r'^[A-Z]{3}\d{2}$').hasMatch(cleaned)) return true;

    return false;
  }

  /// Extracts the most likely license plate string from raw OCR text or QR code payload
  static String? extractPlateCandidate(String rawOcrText) {
    final trimmed = rawOcrText.trim();
    if (trimmed.isEmpty) return null;

    // Reject URLs, file paths, blob URIs, and system filenames
    if (trimmed.startsWith('blob:') ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('file:') ||
        trimmed.contains('image_picker') ||
        trimmed.contains('/scaled_') ||
        trimmed.contains('\\scaled_') ||
        trimmed.contains('/camera_') ||
        trimmed.contains('\\camera_') ||
        trimmed.contains('.jpg') ||
        trimmed.contains('.png')) {
      return null;
    }

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
