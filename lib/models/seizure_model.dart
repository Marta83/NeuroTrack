import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/validators/seizure_validators.dart';

/// Documento Firestore: seizures/{seizureId}
///
/// Este modelo solo referencia al paciente mediante `patientId`.
/// No contiene datos personales identificables.
class SeizureModel {
  SeizureModel({
    required this.id,
    required this.patientId,
    required this.dateTime,
    required this.durationSeconds,
    required this.type,
    required this.intensity,
    required this.medicationUsed,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final DateTime dateTime;
  final int durationSeconds;
  final String type;
  final int intensity;
  final String medicationUsed;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const Uuid _uuid = Uuid();

  /// Crea una crisis con `seizureId` aleatorio UUID v4.
  factory SeizureModel.create({
    required String patientId,
    required DateTime dateTime,
    required int durationSeconds,
    required String type,
    required int intensity,
    required String medicationUsed,
    required String notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    final normalizedType = SeizureValidators.validateType(type);
    final normalizedIntensity = SeizureValidators.validateIntensity(intensity);
    final normalizedDuration =
        SeizureValidators.validateDurationSeconds(durationSeconds);
    final normalizedMedication =
        SeizureValidators.normalizeMedicationUsed(medicationUsed);
    final normalizedNotes = SeizureValidators.normalizeNotes(notes);

    return SeizureModel(
      id: _uuid.v4(),
      patientId: patientId,
      dateTime: dateTime,
      durationSeconds: normalizedDuration,
      type: normalizedType,
      intensity: normalizedIntensity,
      medicationUsed: normalizedMedication,
      notes: normalizedNotes,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  factory SeizureModel.fromMap(Map<String, dynamic> map) {
    final durationSeconds = (map['durationSeconds'] as num?)?.toInt() ?? 0;
    final type = (map['type'] as String?) ?? '';
    final intensity = (map['intensity'] as num?)?.toInt() ?? 1;
    final medicationUsed = (map['medicationUsed'] as String?) ?? '';
    final notes = (map['notes'] as String?) ?? '';

    final normalizedType = SeizureValidators.validateType(type);
    final normalizedIntensity = SeizureValidators.validateIntensity(intensity);
    final normalizedDuration =
        SeizureValidators.validateDurationSeconds(durationSeconds);
    final normalizedMedication =
        SeizureValidators.normalizeMedicationUsed(medicationUsed);
    final normalizedNotes = SeizureValidators.normalizeNotes(notes);

    return SeizureModel(
      id: (map['id'] as String?) ?? '',
      patientId: (map['patientId'] as String?) ?? '',
      dateTime: _dateTimeFromAny(map['dateTime']),
      durationSeconds: normalizedDuration,
      type: normalizedType,
      intensity: normalizedIntensity,
      medicationUsed: normalizedMedication,
      notes: normalizedNotes,
      createdAt: _dateTimeFromAny(map['createdAt']),
      updatedAt: _dateTimeFromAny(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'patientId': patientId,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationSeconds': durationSeconds,
      'type': type,
      'intensity': intensity,
      'medicationUsed': medicationUsed,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SeizureModel copyWith({
    String? id,
    String? patientId,
    DateTime? dateTime,
    int? durationSeconds,
    String? type,
    int? intensity,
    String? medicationUsed,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeizureModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      medicationUsed: medicationUsed ?? this.medicationUsed,
      notes: notes ?? this.notes,
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
