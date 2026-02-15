import 'validation_exception.dart';

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
}
