import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../models/patient_model.dart';
import '../../models/patient_history_entry.dart';
import '../../models/medication_history_entry.dart';

class PatientServiceException implements Exception {
  const PatientServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PatientService {
  PatientService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _patientsCollection =>
      _firestore.collection('patients');

  Future<void> createPatient(PatientModel patient) async {
    try {
      await _patientsCollection.doc(patient.id).set(patient.toMap());
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo crear el paciente.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudo crear el paciente.');
    }
  }

  Future<void> updatePatient(PatientModel patient) async {
    try {
      final updatedPatient = patient.copyWith(updatedAt: DateTime.now());
      await _patientsCollection
          .doc(updatedPatient.id)
          .update(updatedPatient.toMap());
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo actualizar el paciente.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudo actualizar el paciente.');
    }
  }

  Future<bool> updatePatientWithHistory({
    required PatientModel oldPatient,
    required PatientModel updatedPatient,
    required String changedBy,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();
      final nextPatient = updatedPatient.copyWith(
        createdAt: oldPatient.createdAt,
        updatedAt: now,
      );

      final oldState = _diffablePatientMap(oldPatient.toMap());
      final nextState = _diffablePatientMap(nextPatient.toMap());
      final changes = _buildChanges(oldState: oldState, nextState: nextState);
      if (changes.isEmpty) {
        return false;
      }

      final patientRef = _patientsCollection.doc(nextPatient.id);
      final historyRef = patientRef.collection('history').doc();

      final batch = _firestore.batch();
      batch.update(patientRef, nextPatient.toMap());
      batch.set(historyRef, <String, dynamic>{
        'changedAt': Timestamp.fromDate(now),
        'changedBy': changedBy,
        'reason': reason?.trim().isEmpty ?? true ? null : reason?.trim(),
        'changes': changes,
        'snapshot': nextPatient.toMap(),
      });
      await batch.commit();
      return true;
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo actualizar el paciente.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudo actualizar el paciente.');
    }
  }

  Stream<List<PatientModel>> streamPatientsByOwner(String userId) {
    try {
      return _patientsCollection
          .where('ownerUserId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final data = doc.data();
          if ((data['id'] as String?) == null ||
              (data['id'] as String).isEmpty) {
            data['id'] = doc.id;
          }
          return PatientModel.fromMap(data);
        }).toList(growable: false);
      });
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudieron obtener los pacientes.',
      );
    } catch (_) {
      throw const PatientServiceException(
          'No se pudieron obtener los pacientes.');
    }
  }

  Stream<PatientModel> streamPatientById({
    required String userId,
    required String patientId,
  }) {
    try {
      return _patientsCollection.doc(patientId).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            throw const PatientServiceException('El paciente no existe.');
          }

          final data = snapshot.data()!;
          if ((data['ownerUserId'] as String?) != userId) {
            throw const PatientServiceException(
              'No tienes permisos para este paciente.',
            );
          }
          if ((data['id'] as String?) == null ||
              (data['id'] as String).isEmpty) {
            data['id'] = snapshot.id;
          }
          return PatientModel.fromMap(data);
        },
      );
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo obtener el paciente.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudo obtener el paciente.');
    }
  }

  Future<bool> userHasPatients(String ownerUserId) async {
    try {
      final snapshot = await _patientsCollection
          .where('ownerUserId', isEqualTo: ownerUserId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo comprobar si existen pacientes.',
      );
    } catch (_) {
      throw const PatientServiceException(
        'No se pudo comprobar si existen pacientes.',
      );
    }
  }

  Future<String?> getFirstPatientId(String ownerUserId) async {
    try {
      try {
        final ordered = await _patientsCollection
            .where('ownerUserId', isEqualTo: ownerUserId)
            .orderBy('createdAt')
            .limit(1)
            .get();
        if (ordered.docs.isNotEmpty) {
          return ordered.docs.first.id;
        }
      } on FirebaseException {
        // Fallback when order/index is unavailable.
      }

      final fallback = await _patientsCollection
          .where('ownerUserId', isEqualTo: ownerUserId)
          .limit(1)
          .get();
      if (fallback.docs.isEmpty) {
        return null;
      }
      return fallback.docs.first.id;
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo obtener el primer paciente.',
      );
    } catch (_) {
      throw const PatientServiceException(
          'No se pudo obtener el primer paciente.');
    }
  }

  Stream<List<PatientHistoryEntry>> streamPatientHistory({
    required String userId,
    required String patientId,
  }) {
    try {
      final patientRef = _patientsCollection.doc(patientId);
      return patientRef
          .collection('history')
          .orderBy('changedAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
        final patientSnapshot = await patientRef.get();
        if (!patientSnapshot.exists || patientSnapshot.data() == null) {
          throw const PatientServiceException('El paciente no existe.');
        }
        final data = patientSnapshot.data()!;
        if ((data['ownerUserId'] as String?) != userId) {
          throw const PatientServiceException(
            'No tienes permisos para este paciente.',
          );
        }

        return snapshot.docs
            .map((doc) => PatientHistoryEntry.fromMap(
                  id: doc.id,
                  patientId: patientId,
                  map: doc.data(),
                ))
            .toList(growable: false);
      });
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo obtener la evolución.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudo obtener la evolución.');
    }
  }

  Stream<List<MedicationHistoryEntry>> streamMedicationHistory({
    required String userId,
    required String patientId,
  }) async* {
    try {
      await _assertPatientOwnership(userId: userId, patientId: patientId);

      final historyCollection =
          _patientsCollection.doc(patientId).collection('medication_history');

      await for (final snapshot in historyCollection
          .orderBy('startedAt', descending: true)
          .snapshots()) {
        try {
          final entries = snapshot.docs
              .map(
                (doc) => MedicationHistoryEntry.fromMap(
                  id: doc.id,
                  map: doc.data(),
                ),
              )
              .toList(growable: false);
          yield entries;
        } catch (error, stackTrace) {
          _debugMedicationLoadError(error, stackTrace);
          rethrow;
        }
      }
    } on FirebaseException catch (error, stackTrace) {
      _debugMedicationLoadError(error, stackTrace);
      throw PatientServiceException(
        error.message ?? 'No se pudo obtener el historial de medicación.',
      );
    } catch (error, stackTrace) {
      _debugMedicationLoadError(error, stackTrace);
      throw const PatientServiceException(
        'No se pudo obtener el historial de medicación.',
      );
    }
  }

  Future<void> addMedicationHistoryEntry({
    required String userId,
    required String patientId,
    required MedicationHistoryEntry entry,
  }) async {
    try {
      await _assertPatientOwnership(userId: userId, patientId: patientId);
      final collection =
          _patientsCollection.doc(patientId).collection('medication_history');
      final doc =
          entry.id.isEmpty ? collection.doc() : collection.doc(entry.id);
      await doc.set(entry.copyWith(id: doc.id).toMap());
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo guardar el cambio de medicación.',
      );
    } catch (_) {
      throw const PatientServiceException(
        'No se pudo guardar el cambio de medicación.',
      );
    }
  }

  Future<void> updateMedicationHistoryEntry({
    required String userId,
    required String patientId,
    required MedicationHistoryEntry entry,
  }) async {
    try {
      await _assertPatientOwnership(userId: userId, patientId: patientId);
      if (entry.id.trim().isEmpty) {
        throw const PatientServiceException('Entrada de medicación inválida.');
      }
      await _patientsCollection
          .doc(patientId)
          .collection('medication_history')
          .doc(entry.id)
          .update(entry.toMap());
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo actualizar el cambio de medicación.',
      );
    } on PatientServiceException {
      rethrow;
    } catch (_) {
      throw const PatientServiceException(
        'No se pudo actualizar el cambio de medicación.',
      );
    }
  }

  Future<void> finalizeMedicationHistoryEntry({
    required String userId,
    required String patientId,
    required String entryId,
    required DateTime endedAt,
  }) async {
    try {
      await _assertPatientOwnership(userId: userId, patientId: patientId);
      await _patientsCollection
          .doc(patientId)
          .collection('medication_history')
          .doc(entryId)
          .update(<String, dynamic>{
        'endedAt': Timestamp.fromDate(endedAt),
      });
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo finalizar la medicación.',
      );
    } catch (_) {
      throw const PatientServiceException(
          'No se pudo finalizar la medicación.');
    }
  }

  Future<void> deleteMedicationHistoryEntry({
    required String userId,
    required String patientId,
    required String entryId,
  }) async {
    try {
      await _assertPatientOwnership(userId: userId, patientId: patientId);
      await _patientsCollection
          .doc(patientId)
          .collection('medication_history')
          .doc(entryId)
          .delete();
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudo eliminar la medicación.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudo eliminar la medicación.');
    }
  }

  Map<String, dynamic> _diffablePatientMap(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map)
      ..remove('updatedAt')
      ..remove('createdAt');
    return _normalizeValue(copy) as Map<String, dynamic>;
  }

  Map<String, dynamic> _buildChanges({
    required Map<String, dynamic> oldState,
    required Map<String, dynamic> nextState,
  }) {
    final keys = <String>{...oldState.keys, ...nextState.keys};
    final changes = <String, dynamic>{};
    for (final key in keys) {
      final from = oldState[key];
      final to = nextState[key];
      if (jsonEncode(from) != jsonEncode(to)) {
        changes[key] = <String, dynamic>{
          'from': from,
          'to': to,
        };
      }
    }
    return changes;
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      final normalized = <String, dynamic>{};
      final sortedKeys = value.keys.toList()..sort();
      for (final key in sortedKeys) {
        normalized[key] = _normalizeValue(value[key]);
      }
      return normalized;
    }
    if (value is List<dynamic>) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  Future<void> _assertPatientOwnership({
    required String userId,
    required String patientId,
  }) async {
    final patientSnapshot = await _patientsCollection.doc(patientId).get();
    if (!patientSnapshot.exists || patientSnapshot.data() == null) {
      throw const PatientServiceException('El paciente no existe.');
    }
    final data = patientSnapshot.data()!;
    if ((data['ownerUserId'] as String?) != userId) {
      throw const PatientServiceException(
        'No tienes permisos para este paciente.',
      );
    }
  }

  void _debugMedicationLoadError(Object error, StackTrace stackTrace) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('Medication load error: $error');
    if (error is FirebaseException) {
      debugPrint('code=${error.code} message=${error.message}');
    }
    debugPrintStack(stackTrace: stackTrace);
  }
}
