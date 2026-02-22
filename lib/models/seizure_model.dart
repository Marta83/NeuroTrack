import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/validators/seizure_validators.dart';
import '../core/validators/validation_exception.dart';

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
    required this.durationUnknown,
    required this.type,
    required this.intensity,
    this.postictalRecoveryMinutes,
    required this.triggers,
    required this.injury,
    required this.cyanosis,
    required this.emergencyCall,
    required this.emergencyVisit,
    this.rescueMedicationCode,
    this.rescueMedicationOther,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final DateTime dateTime;
  final int? durationSeconds;
  final bool durationUnknown;
  final String type;
  final int intensity;
  final int? postictalRecoveryMinutes;
  final List<String> triggers;
  final bool injury;
  final bool cyanosis;
  final bool emergencyCall;
  final bool emergencyVisit;
  final String? rescueMedicationCode;
  final String? rescueMedicationOther;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const Uuid _uuid = Uuid();
  static const Object _unset = Object();

  /// Crea una crisis con `seizureId` aleatorio UUID v4.
  factory SeizureModel.create({
    required String patientId,
    required DateTime dateTime,
    int? durationSeconds,
    bool durationUnknown = false,
    required String type,
    required int intensity,
    int? postictalRecoveryMinutes,
    List<String> triggers = const <String>[],
    bool injury = false,
    bool cyanosis = false,
    bool emergencyCall = false,
    bool emergencyVisit = false,
    String? rescueMedicationCode,
    String? rescueMedicationOther,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    final normalizedType = SeizureValidators.validateType(type);
    final normalizedIntensity = SeizureValidators.validateIntensity(intensity);
    final normalizedPostictalRecoveryMinutes =
        SeizureValidators.validatePostictalRecoveryMinutes(
      postictalRecoveryMinutes,
    );
    final normalizedTriggers = SeizureValidators.normalizeTriggers(triggers);
    final normalizedDuration =
        SeizureValidators.validateDurationSeconds(durationSeconds);
    final normalizedDurationUnknown = durationUnknown;
    if (normalizedDurationUnknown && normalizedDuration != null) {
      throw const ValidationException(
        'durationSeconds debe ser null cuando durationUnknown es true.',
      );
    }
    final normalizedMedicationCode =
        SeizureValidators.validateRescueMedicationCode(rescueMedicationCode);
    final normalizedMedicationOther = SeizureValidators
        .normalizeRescueMedicationOther(
          rescueMedicationCode: normalizedMedicationCode,
          rescueMedicationOther: rescueMedicationOther,
        );
    final normalizedNotes = SeizureValidators.normalizeNotes(notes);

    return SeizureModel(
      id: _uuid.v4(),
      patientId: patientId,
      dateTime: dateTime,
      durationSeconds: normalizedDuration,
      durationUnknown: normalizedDurationUnknown,
      type: normalizedType,
      intensity: normalizedIntensity,
      postictalRecoveryMinutes: normalizedPostictalRecoveryMinutes,
      triggers: normalizedTriggers,
      injury: injury,
      cyanosis: cyanosis,
      emergencyCall: emergencyCall,
      emergencyVisit: emergencyVisit,
      rescueMedicationCode: normalizedMedicationCode,
      rescueMedicationOther: normalizedMedicationOther,
      notes: normalizedNotes,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  factory SeizureModel.fromMap(Map<String, dynamic> map) {
    final rawDurationSeconds = map['durationSeconds'];
    int? durationSeconds;
    if (rawDurationSeconds is num) {
      durationSeconds = rawDurationSeconds.toInt();
    } else if (rawDurationSeconds is String) {
      durationSeconds = int.tryParse(rawDurationSeconds.trim());
    }
    final durationUnknown = (map['durationUnknown'] as bool?) ?? false;
    final type = (map['type'] as String?) ?? '';
    final intensity = (map['intensity'] as int?) ?? 1;
    final postictalRecoveryMinutes =
        (map['postictalRecoveryMinutes'] as int?);
    final triggersRaw = List<String>.from(
      map['triggers'] as List<dynamic>? ?? const <String>[],
    );
    final injury = (map['injury'] as bool?) ?? false;
    final cyanosis = (map['cyanosis'] as bool?) ?? false;
    final emergencyCall = (map['emergencyCall'] as bool?) ?? false;
    final emergencyVisit = (map['emergencyVisit'] as bool?) ?? false;
    final rescueMedicationCodeRaw = (map['rescueMedicationCode'] as String?);
    final rescueMedicationOtherRaw = (map['rescueMedicationOther'] as String?);
    final notes = (map['notes'] as String?);

    String? rescueMedicationCode = rescueMedicationCodeRaw;
    String? rescueMedicationOther = rescueMedicationOtherRaw;

    final normalizedType = SeizureValidators.validateType(type);
    final normalizedIntensity = SeizureValidators.validateIntensity(intensity);
    final normalizedPostictalRecoveryMinutes =
        SeizureValidators.validatePostictalRecoveryMinutes(
      postictalRecoveryMinutes,
    );
    final normalizedTriggers = SeizureValidators.normalizeTriggers(triggersRaw);
    final normalizedDurationUnknown = durationUnknown;
    final normalizedDuration = normalizedDurationUnknown
        ? null
        : SeizureValidators.validateDurationSeconds(durationSeconds);
    final normalizedMedicationCode =
        SeizureValidators.validateRescueMedicationCode(rescueMedicationCode);
    final normalizedMedicationOther = SeizureValidators
        .normalizeRescueMedicationOther(
          rescueMedicationCode: normalizedMedicationCode,
          rescueMedicationOther: rescueMedicationOther,
        );
    final normalizedNotes = SeizureValidators.normalizeNotes(notes);

    return SeizureModel(
      id: (map['id'] as String?) ?? '',
      patientId: (map['patientId'] as String?) ?? '',
      dateTime: _dateTimeFromAny(map['dateTime']),
      durationSeconds: normalizedDuration,
      durationUnknown: normalizedDurationUnknown,
      type: normalizedType,
      intensity: normalizedIntensity,
      postictalRecoveryMinutes: normalizedPostictalRecoveryMinutes,
      triggers: normalizedTriggers,
      injury: injury,
      cyanosis: cyanosis,
      emergencyCall: emergencyCall,
      emergencyVisit: emergencyVisit,
      rescueMedicationCode: normalizedMedicationCode,
      rescueMedicationOther: normalizedMedicationOther,
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
      'durationUnknown': durationUnknown,
      'type': type,
      'intensity': intensity,
      'postictalRecoveryMinutes': postictalRecoveryMinutes,
      'triggers': triggers,
      'injury': injury,
      'cyanosis': cyanosis,
      'emergencyCall': emergencyCall,
      'emergencyVisit': emergencyVisit,
      'rescueMedicationCode': rescueMedicationCode,
      'rescueMedicationOther': rescueMedicationOther,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SeizureModel copyWith({
    String? id,
    String? patientId,
    DateTime? dateTime,
    Object? durationSeconds = _unset,
    bool? durationUnknown,
    String? type,
    int? intensity,
    Object? postictalRecoveryMinutes = _unset,
    List<String>? triggers,
    bool? injury,
    bool? cyanosis,
    bool? emergencyCall,
    bool? emergencyVisit,
    Object? rescueMedicationCode = _unset,
    Object? rescueMedicationOther = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SeizureModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      durationSeconds: durationSeconds == _unset
          ? this.durationSeconds
          : durationSeconds as int?,
      durationUnknown: durationUnknown ?? this.durationUnknown,
      type: type ?? this.type,
      intensity: intensity ?? this.intensity,
      postictalRecoveryMinutes: postictalRecoveryMinutes == _unset
          ? this.postictalRecoveryMinutes
          : postictalRecoveryMinutes as int?,
      triggers: triggers ?? this.triggers,
      injury: injury ?? this.injury,
      cyanosis: cyanosis ?? this.cyanosis,
      emergencyCall: emergencyCall ?? this.emergencyCall,
      emergencyVisit: emergencyVisit ?? this.emergencyVisit,
      rescueMedicationCode: rescueMedicationCode == _unset
          ? this.rescueMedicationCode
          : rescueMedicationCode as String?,
      rescueMedicationOther: rescueMedicationOther == _unset
          ? this.rescueMedicationOther
          : rescueMedicationOther as String?,
      notes: notes == _unset ? this.notes : notes as String?,
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
