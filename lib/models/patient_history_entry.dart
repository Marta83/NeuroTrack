import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHistoryEntry {
  const PatientHistoryEntry({
    required this.id,
    required this.patientId,
    required this.changedAt,
    required this.changedBy,
    this.reason,
    required this.changes,
    required this.snapshot,
  });

  final String id;
  final String patientId;
  final DateTime changedAt;
  final String changedBy;
  final String? reason;
  final Map<String, dynamic> changes;
  final Map<String, dynamic> snapshot;

  factory PatientHistoryEntry.fromMap({
    required String id,
    required String patientId,
    required Map<String, dynamic> map,
  }) {
    return PatientHistoryEntry(
      id: id,
      patientId: patientId,
      changedAt: _dateTimeFromAny(map['changedAt']),
      changedBy: (map['changedBy'] as String?) ?? '',
      reason: map['reason'] as String?,
      changes: Map<String, dynamic>.from(
          map['changes'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      snapshot: Map<String, dynamic>.from(
          map['snapshot'] as Map<String, dynamic>? ??
              const <String, dynamic>{}),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'changedAt': Timestamp.fromDate(changedAt),
      'changedBy': changedBy,
      'reason': reason,
      'changes': changes,
      'snapshot': snapshot,
    };
  }

  static DateTime _dateTimeFromAny(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
