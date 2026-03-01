import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationHistoryEntry {
  const MedicationHistoryEntry({
    required this.id,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.doseAmount,
    this.doseUnit,
    this.frequency,
    this.timing = const <String>[],
    this.reason,
    this.notes,
    required this.createdAt,
    this.createdBy,
  });

  final String id;
  final String name;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? doseAmount;
  final String? doseUnit;
  final Object? frequency; // int (1..4) or "PRN"
  final List<String> timing;
  final String? reason;
  final String? notes;
  final DateTime createdAt;
  final String? createdBy;

  int? get frequencyPerDay {
    final value = frequency;
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  bool get isPrn {
    final value = frequency;
    if (value is! String) {
      return false;
    }
    return value.trim().toUpperCase() == 'PRN';
  }

  factory MedicationHistoryEntry.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return MedicationHistoryEntry(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      startedAt: _dateTimeFromAny(map['startedAt']),
      endedAt: _nullableDateTimeFromAny(map['endedAt']),
      doseAmount: _nullableDoubleFromAny(map['doseAmount']),
      doseUnit: (map['doseUnit'] as String?)?.trim(),
      frequency: _frequencyFromAny(map['frequency']),
      timing: List<String>.from(
        (map['timing'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>()
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty),
      ),
      reason: (map['reason'] as String?)?.trim(),
      notes: (map['notes'] as String?)?.trim(),
      createdAt: _dateTimeFromAny(map['createdAt']),
      createdBy: (map['createdBy'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
      'doseAmount': doseAmount,
      'doseUnit': doseUnit,
      'frequency': frequency,
      'timing': timing.isEmpty ? null : timing,
      'reason': reason,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  MedicationHistoryEntry copyWith({
    String? id,
    String? name,
    DateTime? startedAt,
    Object? endedAt = _unset,
    Object? doseAmount = _unset,
    Object? doseUnit = _unset,
    Object? frequency = _unset,
    List<String>? timing,
    Object? reason = _unset,
    Object? notes = _unset,
    DateTime? createdAt,
    Object? createdBy = _unset,
  }) {
    return MedicationHistoryEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt == _unset ? this.endedAt : endedAt as DateTime?,
      doseAmount:
          doseAmount == _unset ? this.doseAmount : doseAmount as double?,
      doseUnit: doseUnit == _unset ? this.doseUnit : doseUnit as String?,
      frequency: frequency == _unset ? this.frequency : frequency,
      timing: timing ?? this.timing,
      reason: reason == _unset ? this.reason : reason as String?,
      notes: notes == _unset ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy == _unset ? this.createdBy : createdBy as String?,
    );
  }

  static const Object _unset = Object();

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

  static DateTime? _nullableDateTimeFromAny(dynamic value) {
    if (value == null) {
      return null;
    }
    return _dateTimeFromAny(value);
  }

  static double? _nullableDoubleFromAny(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }

  static Object? _frequencyFromAny(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final normalized = value.trim().toUpperCase();
      if (normalized == 'PRN') {
        return 'PRN';
      }
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
}
