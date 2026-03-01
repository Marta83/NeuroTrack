import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/auth/auth_repository.dart';
import '../../models/medication_history_entry.dart';
import '../../models/patient_model.dart';
import '../../models/seizure_model.dart';

class ReportRepositoryException implements Exception {
  const ReportRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReportRepository {
  ReportRepository({
    required FirebaseFirestore firestore,
    required AuthRepository authRepository,
  })  : _firestore = firestore,
        _authRepository = authRepository;

  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  CollectionReference<Map<String, dynamic>> get _patientsCollection =>
      _firestore.collection('patients');
  CollectionReference<Map<String, dynamic>> get _seizuresCollection =>
      _firestore.collection('seizures');

  Future<PatientModel> fetchPatient(String patientId) async {
    try {
      final userId = _requireUserId();
      final snapshot = await _patientsCollection.doc(patientId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        throw const ReportRepositoryException('El paciente no existe.');
      }
      final data = snapshot.data()!;
      if ((data['ownerUserId'] as String?) != userId) {
        throw const ReportRepositoryException(
          'No tienes permisos para este paciente.',
        );
      }
      if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
        data['id'] = snapshot.id;
      }
      return PatientModel.fromMap(data);
    } on FirebaseException catch (error) {
      throw ReportRepositoryException(
        error.message ?? 'No se pudo obtener el paciente.',
      );
    } on ReportRepositoryException {
      rethrow;
    } catch (_) {
      throw const ReportRepositoryException('No se pudo obtener el paciente.');
    }
  }

  Future<List<SeizureModel>> fetchSeizuresInRange({
    required String patientId,
    required DateTime startInclusive,
    required DateTime endInclusive,
  }) async {
    try {
      final userId = _requireUserId();
      await _assertPatientOwnership(
        userId: userId,
        patientId: patientId,
      );

      final snapshot = await _seizuresCollection
          .where('patientId', isEqualTo: patientId)
          .where(
            'dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive),
          )
          .where(
            'dateTime',
            isLessThanOrEqualTo: Timestamp.fromDate(endInclusive),
          )
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
          data['id'] = doc.id;
        }
        return SeizureModel.fromMap(data);
      }).toList(growable: false);
    } on FirebaseException catch (error) {
      throw ReportRepositoryException(
        error.message ?? 'No se pudieron obtener las crisis.',
      );
    } on ReportRepositoryException {
      rethrow;
    } catch (_) {
      throw const ReportRepositoryException(
        'No se pudieron obtener las crisis.',
      );
    }
  }

  Future<List<MedicationHistoryEntry>> fetchAllMedicationHistory(
      String patientId) async {
    try {
      final userId = _requireUserId();
      final patient = await fetchPatient(patientId);
      await _assertPatientOwnership(
        userId: userId,
        patientId: patientId,
      );

      final historySnapshot = await _patientsCollection
          .doc(patientId)
          .collection('medication_history')
          .orderBy('startedAt', descending: true)
          .get();

      final historyEntries = historySnapshot.docs
          .map(
            (doc) => MedicationHistoryEntry.fromMap(
              id: doc.id,
              map: doc.data(),
            ),
          )
          .toList(growable: true);

      final activeNames = historyEntries
          .where((entry) => entry.endedAt == null)
          .map((entry) => entry.name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();

      for (int i = 0; i < patient.currentMedications.length; i++) {
        final current = patient.currentMedications[i];
        final name = (current['name'] as String?)?.trim() ?? '';
        if (name.isEmpty) {
          continue;
        }
        if (activeNames.contains(name.toLowerCase())) {
          continue;
        }
        final parsedAmount = _parseDouble(current['doseAmount']);
        final fallbackDoseText = (current['dose'] as String?)?.trim();
        historyEntries.add(
          MedicationHistoryEntry(
            id: 'legacy_current_$i',
            name: name,
            startedAt: patient.updatedAt,
            endedAt: null,
            doseAmount: parsedAmount,
            doseUnit: (current['doseUnit'] as String?)?.trim(),
            frequency: current['frequency'],
            timing: List<String>.from(
              (current['timing'] as List<dynamic>? ?? const <dynamic>[])
                  .whereType<String>(),
            ),
            reason: 'Actual',
            notes: fallbackDoseText?.isNotEmpty == true
                ? 'Dosis previa: $fallbackDoseText'
                : null,
            createdAt: patient.updatedAt,
            createdBy: patient.ownerUserId,
          ),
        );
      }

      historyEntries.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return historyEntries;
    } on FirebaseException catch (error) {
      throw ReportRepositoryException(
        error.message ?? 'No se pudo obtener el historial de medicación.',
      );
    } on ReportRepositoryException {
      rethrow;
    } catch (_) {
      throw const ReportRepositoryException(
        'No se pudo obtener el historial de medicación.',
      );
    }
  }

  String _requireUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw const ReportRepositoryException('Usuario no autenticado.');
    }
    return user.uid;
  }

  Future<void> _assertPatientOwnership({
    required String userId,
    required String patientId,
  }) async {
    final patientSnapshot = await _patientsCollection.doc(patientId).get();
    if (!patientSnapshot.exists || patientSnapshot.data() == null) {
      throw const ReportRepositoryException('El paciente no existe.');
    }
    final data = patientSnapshot.data()!;
    if ((data['ownerUserId'] as String?) != userId) {
      throw const ReportRepositoryException(
        'No tienes permisos para este paciente.',
      );
    }
  }

  double? _parseDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }
}
