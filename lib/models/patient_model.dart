import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Documento Firestore: patients/{patientId}
///
/// Este modelo es anonimo por diseno: no contiene nombre, email u otros datos
/// identificables.
class PatientModel {
  PatientModel({
    required this.id,
    required this.ownerUserId,
    required this.birthYear,
    required this.sex,
    required this.country,
    required this.geneSummary,
    required this.consentForResearch,
    required this.consentAcceptedAt,
    required this.consentVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final int birthYear;
  final String sex;
  final String country;
  final List<String> geneSummary;
  final bool consentForResearch;
  final DateTime consentAcceptedAt;
  final String consentVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const Uuid _uuid = Uuid();

  /// Crea un paciente con `patientId` aleatorio UUID v4.
  factory PatientModel.create({
    required String ownerUserId,
    required int birthYear,
    required String sex,
    required String country,
    required List<String> geneSummary,
    required bool consentForResearch,
    required DateTime consentAcceptedAt,
    required String consentVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return PatientModel(
      id: _uuid.v4(),
      ownerUserId: ownerUserId,
      birthYear: birthYear,
      sex: sex,
      country: country,
      geneSummary: List<String>.from(geneSummary),
      consentForResearch: consentForResearch,
      consentAcceptedAt: consentAcceptedAt,
      consentVersion: consentVersion,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      id: (map['id'] as String?) ?? '',
      ownerUserId: (map['ownerUserId'] as String?) ?? '',
      birthYear: (map['birthYear'] as num?)?.toInt() ?? 0,
      sex: (map['sex'] as String?) ?? '',
      country: (map['country'] as String?) ?? '',
      geneSummary: List<String>.from(map['geneSummary'] as List<dynamic>? ?? const <String>[]),
      consentForResearch: (map['consentForResearch'] as bool?) ?? false,
      consentAcceptedAt: _dateTimeFromAny(map['consentAcceptedAt']),
      consentVersion: (map['consentVersion'] as String?) ?? '',
      createdAt: _dateTimeFromAny(map['createdAt']),
      updatedAt: _dateTimeFromAny(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ownerUserId': ownerUserId,
      'birthYear': birthYear,
      'sex': sex,
      'country': country,
      'geneSummary': geneSummary,
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
    int? birthYear,
    String? sex,
    String? country,
    List<String>? geneSummary,
    bool? consentForResearch,
    DateTime? consentAcceptedAt,
    String? consentVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      birthYear: birthYear ?? this.birthYear,
      sex: sex ?? this.sex,
      country: country ?? this.country,
      geneSummary: geneSummary ?? this.geneSummary,
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
