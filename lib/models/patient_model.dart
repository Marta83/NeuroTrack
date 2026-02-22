import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/validators/patient_validators.dart';

/// Documento Firestore: patients/{patientId}
///
/// Este modelo es anonimo por diseno: no contiene nombre, email u otros datos
/// identificables.
class PatientModel {
  PatientModel({
    required this.id,
    required this.ownerUserId,
    required this.alias,
    required this.birthYear,
    required this.sex,
    required this.country,
    required this.geneSummary,
    this.city,
    this.referenceHospital,
    this.epilepsyOnsetAgeMonths,
    this.seizureFrequencyBaseline,
    required this.comorbidities,
    required this.therapies,
    required this.devices,
    required this.currentMedications,
    required this.consentForResearch,
    required this.consentAcceptedAt,
    required this.consentVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final String alias;
  final int birthYear;
  final String sex;
  final String country;
  final List<String> geneSummary;
  final String? city;
  final String? referenceHospital;
  final int? epilepsyOnsetAgeMonths;
  final String? seizureFrequencyBaseline;
  final List<String> comorbidities;
  final List<String> therapies;
  final List<String> devices;
  final List<Map<String, dynamic>> currentMedications;
  final bool consentForResearch;
  final DateTime consentAcceptedAt;
  final String consentVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const Uuid _uuid = Uuid();

  /// Crea un paciente con `patientId` aleatorio UUID v4.
  factory PatientModel.create({
    required String ownerUserId,
    String alias = '',
    required int birthYear,
    required String sex,
    required String country,
    required List<String> geneSummary,
    String? city,
    String? referenceHospital,
    int? epilepsyOnsetAgeMonths,
    String? seizureFrequencyBaseline,
    List<String> comorbidities = const <String>[],
    List<String> therapies = const <String>[],
    List<String> devices = const <String>[],
    List<Map<String, dynamic>> currentMedications = const <Map<String, dynamic>>[],
    required bool consentForResearch,
    required DateTime consentAcceptedAt,
    required String consentVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    PatientValidators.validateBirthYear(birthYear);
    final normalizedSex = PatientValidators.validateSex(sex);
    final normalizedCountry = PatientValidators.validateCountry(country);
    final normalizedGenes = PatientValidators.normalizeGeneSummary(geneSummary);
    final normalizedCity = PatientValidators.normalizeOptionalText(
      city,
      maxLength: 120,
      fieldName: 'city',
    );
    final normalizedReferenceHospital = PatientValidators.normalizeOptionalText(
      referenceHospital,
      maxLength: 160,
      fieldName: 'referenceHospital',
    );
    final normalizedOnsetMonths =
        PatientValidators.validateEpilepsyOnsetAgeMonths(epilepsyOnsetAgeMonths);
    final normalizedFrequency = PatientValidators.validateSeizureFrequencyBaseline(
      seizureFrequencyBaseline,
    );
    final normalizedComorbidities =
        PatientValidators.normalizeComorbidities(comorbidities);
    final normalizedTherapies = PatientValidators.normalizeTherapies(therapies);
    final normalizedDevices = PatientValidators.normalizeDevices(devices);
    final normalizedMedications = PatientValidators.normalizeCurrentMedications(
      currentMedications,
    );
    final normalizedConsentVersion =
        PatientValidators.validateConsentVersion(consentVersion);
    final normalizedAlias = PatientValidators.normalizeAlias(alias);

    return PatientModel(
      id: _uuid.v4(),
      ownerUserId: ownerUserId,
      alias: normalizedAlias,
      birthYear: birthYear,
      sex: normalizedSex,
      country: normalizedCountry,
      geneSummary: normalizedGenes,
      city: normalizedCity,
      referenceHospital: normalizedReferenceHospital,
      epilepsyOnsetAgeMonths: normalizedOnsetMonths,
      seizureFrequencyBaseline: normalizedFrequency,
      comorbidities: normalizedComorbidities,
      therapies: normalizedTherapies,
      devices: normalizedDevices,
      currentMedications: normalizedMedications,
      consentForResearch: consentForResearch,
      consentAcceptedAt: consentAcceptedAt,
      consentVersion: normalizedConsentVersion,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    final alias = (map['alias'] as String?) ?? '';
    final birthYear = (map['birthYear'] as num?)?.toInt() ?? 0;
    final sex = (map['sex'] as String?) ?? '';
    final country = (map['country'] as String?) ?? '';
    final geneSummary =
        List<String>.from(map['geneSummary'] as List<dynamic>? ?? const <String>[]);
    final city = map['city'] as String?;
    final referenceHospital = map['referenceHospital'] as String?;
    final epilepsyOnsetAgeMonths = (map['epilepsyOnsetAgeMonths'] as num?)?.toInt();
    final seizureFrequencyBaseline = map['seizureFrequencyBaseline'] as String?;
    final comorbidities = List<String>.from(
      map['comorbidities'] as List<dynamic>? ?? const <String>[],
    );
    final therapies =
        List<String>.from(map['therapies'] as List<dynamic>? ?? const <String>[]);
    final devices =
        List<String>.from(map['devices'] as List<dynamic>? ?? const <String>[]);
    final currentMedications = List<Map<String, dynamic>>.from(
      map['currentMedications'] as List<dynamic>? ?? const <Map<String, dynamic>>[],
    );
    final consentVersion = (map['consentVersion'] as String?) ?? '';

    PatientValidators.validateBirthYear(birthYear);
    final normalizedSex = PatientValidators.validateSex(sex);
    final normalizedCountry = PatientValidators.validateCountry(country);
    final normalizedGenes = PatientValidators.normalizeGeneSummary(geneSummary);
    final normalizedCity = PatientValidators.normalizeOptionalText(
      city,
      maxLength: 120,
      fieldName: 'city',
    );
    final normalizedReferenceHospital = PatientValidators.normalizeOptionalText(
      referenceHospital,
      maxLength: 160,
      fieldName: 'referenceHospital',
    );
    final normalizedOnsetMonths =
        PatientValidators.validateEpilepsyOnsetAgeMonths(epilepsyOnsetAgeMonths);
    final normalizedFrequency = PatientValidators.validateSeizureFrequencyBaseline(
      seizureFrequencyBaseline,
    );
    final normalizedComorbidities =
        PatientValidators.normalizeComorbidities(comorbidities);
    final normalizedTherapies = PatientValidators.normalizeTherapies(therapies);
    final normalizedDevices = PatientValidators.normalizeDevices(devices);
    final normalizedMedications = PatientValidators.normalizeCurrentMedications(
      currentMedications,
    );
    final normalizedConsentVersion =
        PatientValidators.validateConsentVersion(consentVersion);
    final normalizedAlias = PatientValidators.normalizeAlias(alias);

    return PatientModel(
      id: (map['id'] as String?) ?? '',
      ownerUserId: (map['ownerUserId'] as String?) ?? '',
      alias: normalizedAlias,
      birthYear: birthYear,
      sex: normalizedSex,
      country: normalizedCountry,
      geneSummary: normalizedGenes,
      city: normalizedCity,
      referenceHospital: normalizedReferenceHospital,
      epilepsyOnsetAgeMonths: normalizedOnsetMonths,
      seizureFrequencyBaseline: normalizedFrequency,
      comorbidities: normalizedComorbidities,
      therapies: normalizedTherapies,
      devices: normalizedDevices,
      currentMedications: normalizedMedications,
      consentForResearch: (map['consentForResearch'] as bool?) ?? false,
      consentAcceptedAt: _dateTimeFromAny(map['consentAcceptedAt']),
      consentVersion: normalizedConsentVersion,
      createdAt: _dateTimeFromAny(map['createdAt']),
      updatedAt: _dateTimeFromAny(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ownerUserId': ownerUserId,
      'alias': alias,
      'birthYear': birthYear,
      'sex': sex,
      'country': country,
      'geneSummary': geneSummary,
      'city': city,
      'referenceHospital': referenceHospital,
      'epilepsyOnsetAgeMonths': epilepsyOnsetAgeMonths,
      'seizureFrequencyBaseline': seizureFrequencyBaseline,
      'comorbidities': comorbidities,
      'therapies': therapies,
      'devices': devices,
      'currentMedications': currentMedications,
      'consentForResearch': consentForResearch,
      'consentAcceptedAt': Timestamp.fromDate(consentAcceptedAt),
      'consentVersion': consentVersion,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PatientModel copyWith({
    String? id,
    String? ownerUserId,
    String? alias,
    int? birthYear,
    String? sex,
    String? country,
    List<String>? geneSummary,
    String? city,
    String? referenceHospital,
    int? epilepsyOnsetAgeMonths,
    String? seizureFrequencyBaseline,
    List<String>? comorbidities,
    List<String>? therapies,
    List<String>? devices,
    List<Map<String, dynamic>>? currentMedications,
    bool? consentForResearch,
    DateTime? consentAcceptedAt,
    String? consentVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      alias: alias ?? this.alias,
      birthYear: birthYear ?? this.birthYear,
      sex: sex ?? this.sex,
      country: country ?? this.country,
      geneSummary: geneSummary ?? this.geneSummary,
      city: city ?? this.city,
      referenceHospital: referenceHospital ?? this.referenceHospital,
      epilepsyOnsetAgeMonths:
          epilepsyOnsetAgeMonths ?? this.epilepsyOnsetAgeMonths,
      seizureFrequencyBaseline:
          seizureFrequencyBaseline ?? this.seizureFrequencyBaseline,
      comorbidities: comorbidities ?? this.comorbidities,
      therapies: therapies ?? this.therapies,
      devices: devices ?? this.devices,
      currentMedications: currentMedications ?? this.currentMedications,
      consentForResearch: consentForResearch ?? this.consentForResearch,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      consentVersion: consentVersion ?? this.consentVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _dateTimeFromAny(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
