import 'validation_exception.dart';

class SeizureValidators {
  static String validateType(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 50) {
      throw ValidationException('type invalido.');
    }
    return normalized;
  }

  static int validateIntensity(int value) {
    if (value < 1 || value > 5) {
      throw ValidationException('intensity fuera de rango (1-5).');
    }
    return value;
  }

  static int validateDurationSeconds(int value) {
    if (value < 0 || value > 86400) {
      throw ValidationException('durationSeconds fuera de rango.');
    }
    return value;
  }

  static String normalizeMedicationUsed(String value) {
    final normalized = value.trim();
    if (normalized.length > 500) {
      throw ValidationException('medicationUsed supera el maximo permitido.');
    }
    return normalized;
  }

  static String normalizeNotes(String value) {
    final normalized = value.trim();
    if (normalized.length > 2000) {
      throw ValidationException('notes supera el maximo permitido.');
    }
    return normalized;
  }
}
