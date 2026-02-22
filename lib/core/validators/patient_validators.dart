import 'validation_exception.dart';
import '../../models/patient_clinical_catalog.dart';

class PatientValidators {
  static final RegExp _genePattern = RegExp(r'^[A-Z0-9-]+$');

  static void validateBirthYear(int year) {
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) {
      throw const ValidationException('birthYear fuera de rango.');
    }
  }

  static String validateSex(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 30) {
      throw const ValidationException('sex invalido.');
    }
    return normalized;
  }

  static String validateCountry(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 100) {
      throw const ValidationException('country invalido.');
    }
    return normalized;
  }

  static String validateConsentVersion(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 40) {
      throw const ValidationException('consentVersion invalido.');
    }
    return normalized;
  }

  static String normalizeAlias(String value) {
    final normalized = value.trim();
    if (normalized.length > 80) {
      throw const ValidationException('alias supera el maximo permitido.');
    }
    return normalized;
  }

  static List<String> normalizeGeneSummary(List<String> genes) {
    if (genes.length > 100) {
      throw const ValidationException('geneSummary supera el maximo permitido.');
    }

    final result = <String>{};
    for (final raw in genes) {
      final gene = raw.trim().toUpperCase();
      if (gene.isEmpty) {
        continue;
      }
      if (gene.length > 20 || !_genePattern.hasMatch(gene)) {
        throw const ValidationException('geneSummary contiene genes invalidos.');
      }
      result.add(gene);
    }
    return result.toList(growable: false);
  }

  static String? normalizeOptionalText(
    String? value, {
    required int maxLength,
    required String fieldName,
  }) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.length > maxLength) {
      throw ValidationException('$fieldName supera el maximo permitido.');
    }
    return normalized;
  }

  static int? validateEpilepsyOnsetAgeMonths(int? value) {
    if (value == null) {
      return null;
    }
    if (value < 0 || value > 1200) {
      throw const ValidationException('epilepsyOnsetAgeMonths fuera de rango.');
    }
    return value;
  }

  static String? validateSeizureFrequencyBaseline(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (!PatientClinicalCatalog.isValidSeizureFrequencyBaseline(normalized)) {
      throw const ValidationException('seizureFrequencyBaseline invalido.');
    }
    return normalized;
  }

  static List<String> normalizeComorbidities(List<String>? values) {
    return _normalizeCodeList(
      values,
      validator: PatientClinicalCatalog.isValidComorbidity,
      fieldName: 'comorbidities',
    );
  }

  static List<String> normalizeTherapies(List<String>? values) {
    return _normalizeCodeList(
      values,
      validator: PatientClinicalCatalog.isValidTherapy,
      fieldName: 'therapies',
    );
  }

  static List<String> normalizeDevices(List<String>? values) {
    return _normalizeCodeList(
      values,
      validator: PatientClinicalCatalog.isValidDevice,
      fieldName: 'devices',
    );
  }

  static List<Map<String, dynamic>> normalizeCurrentMedications(
    List<Map<String, dynamic>>? values,
  ) {
    if (values == null || values.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final normalized = <Map<String, dynamic>>[];
    for (final item in values) {
      final name = normalizeOptionalText(
        item['name'] as String?,
        maxLength: 120,
        fieldName: 'currentMedications.name',
      );
      if (name == null) {
        throw const ValidationException(
          'currentMedications.name es obligatorio.',
        );
      }

      normalized.add(<String, dynamic>{
        'name': name,
        'dose': normalizeOptionalText(
          item['dose'] as String?,
          maxLength: 120,
          fieldName: 'currentMedications.dose',
        ),
        'schedule': normalizeOptionalText(
          item['schedule'] as String?,
          maxLength: 120,
          fieldName: 'currentMedications.schedule',
        ),
        'notes': normalizeOptionalText(
          item['notes'] as String?,
          maxLength: 500,
          fieldName: 'currentMedications.notes',
        ),
      });
    }
    return normalized;
  }

  static List<String> _normalizeCodeList(
    List<String>? values, {
    required bool Function(String code) validator,
    required String fieldName,
  }) {
    if (values == null || values.isEmpty) {
      return const <String>[];
    }
    final unique = <String>{};
    for (final raw in values) {
      final code = raw.trim();
      if (code.isEmpty) {
        continue;
      }
      if (!validator(code)) {
        throw ValidationException('$fieldName contiene codigos invalidos.');
      }
      unique.add(code);
    }
    final result = unique.toList(growable: false)..sort();
    return result;
  }
}
