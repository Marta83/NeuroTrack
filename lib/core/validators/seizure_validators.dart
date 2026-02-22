import 'validation_exception.dart';
import '../../models/rescue_medication.dart';
import '../../models/seizure_trigger.dart';

class SeizureValidators {
  static const int maxPostictalRecoveryMinutes = 1440;

  static String validateType(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 50) {
      throw const ValidationException('type invalido.');
    }
    return normalized;
  }

  static int validateIntensity(int value) {
    if (value < 1 || value > 5) {
      throw const ValidationException('intensity fuera de rango (1-5).');
    }
    return value;
  }

  static String intensityLabel(int value) {
    switch (validateIntensity(value)) {
      case 1:
        return 'Leve';
      case 2:
        return 'Leve-moderada';
      case 3:
        return 'Moderada';
      case 4:
        return 'Intensa';
      case 5:
        return 'Muy intensa';
      default:
        throw const ValidationException('intensity fuera de rango (1-5).');
    }
  }

  static int? validateDurationSeconds(int? value) {
    if (value == null) {
      return null;
    }
    if (value <= 0 || value > 86400) {
      throw const ValidationException('durationSeconds fuera de rango.');
    }
    return value;
  }

  static int? validatePostictalRecoveryMinutes(int? value) {
    if (value == null) {
      return null;
    }
    if (value <= 0 || value > maxPostictalRecoveryMinutes) {
      throw const ValidationException('postictalRecoveryMinutes fuera de rango.');
    }
    return value;
  }

  static List<String> normalizeTriggers(List<String>? values) {
    if (values == null || values.isEmpty) {
      return const <String>[];
    }
    final uniqueCodes = <String>{};
    for (final raw in values) {
      final code = raw.trim();
      if (SeizureTrigger.fromCode(code) == null) {
        throw const ValidationException('trigger invalido.');
      }
      uniqueCodes.add(code);
    }
    final normalized = uniqueCodes.toList(growable: false)..sort();
    return normalized;
  }

  static String? validateRescueMedicationCode(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (RescueMedication.fromCode(normalized) == null) {
      throw const ValidationException('rescueMedicationCode invalido.');
    }
    return normalized;
  }

  static String? normalizeRescueMedicationOther({
    required String? rescueMedicationCode,
    required String? rescueMedicationOther,
  }) {
    if (rescueMedicationCode != RescueMedication.otherCode) {
      return null;
    }

    final normalized = rescueMedicationOther?.trim() ?? '';
    if (normalized.isEmpty) {
      throw const ValidationException('rescueMedicationOther es obligatorio.');
    }
    if (normalized.length > 500) {
      throw const ValidationException(
        'rescueMedicationOther supera el maximo permitido.',
      );
    }
    return normalized;
  }

  static String? normalizeNotes(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length > 2000) {
      throw const ValidationException('notes supera el maximo permitido.');
    }
    return normalized;
  }
}
