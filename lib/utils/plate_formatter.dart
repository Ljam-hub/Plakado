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

  /// Extracts the most likely license plate string from raw OCR text
  static String? extractPlateCandidate(String rawOcrText) {
    if (rawOcrText.trim().isEmpty) return null;

    final lines = rawOcrText
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
    final tokens = rawOcrText
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
