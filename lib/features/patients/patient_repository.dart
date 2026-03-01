import '../../models/patient_model.dart';
import '../../models/patient_history_entry.dart';
import '../../models/medication_history_entry.dart';
import 'patient_service.dart';

class PatientRepositoryException implements Exception {
  const PatientRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PatientRepository {
  const PatientRepository(this._service);

  final PatientService _service;

  Future<void> createPatient(PatientModel patient) async {
    try {
      await _service.createPatient(patient);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException('No se pudo crear el paciente.');
    }
  }

  Future<void> updatePatient(PatientModel patient) async {
    try {
      await _service.updatePatient(patient);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
          'No se pudo actualizar el paciente.');
    }
  }

  Future<bool> updatePatientWithHistory({
    required PatientModel oldPatient,
    required PatientModel updatedPatient,
    required String changedBy,
    String? reason,
  }) async {
    try {
      return await _service.updatePatientWithHistory(
        oldPatient: oldPatient,
        updatedPatient: updatedPatient,
        changedBy: changedBy,
        reason: reason,
      );
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
          'No se pudo actualizar el paciente.');
    }
  }

  Stream<List<PatientModel>> streamPatientsByOwner(String userId) {
    try {
      return _service.streamPatientsByOwner(userId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
          'No se pudieron obtener los pacientes.');
    }
  }

  Stream<PatientModel> streamPatientById({
    required String userId,
    required String patientId,
  }) {
    try {
      return _service.streamPatientById(userId: userId, patientId: patientId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException('No se pudo obtener el paciente.');
    }
  }

  Stream<List<PatientHistoryEntry>> streamPatientHistory({
    required String userId,
    required String patientId,
  }) {
    try {
      return _service.streamPatientHistory(
          userId: userId, patientId: patientId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
          'No se pudo obtener la evolución.');
    }
  }

  Future<bool> userHasPatients(String ownerUserId) async {
    try {
      return await _service.userHasPatients(ownerUserId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
        'No se pudo comprobar si existen pacientes.',
      );
    }
  }

  Future<String?> getFirstPatientId(String ownerUserId) async {
    try {
      return await _service.getFirstPatientId(ownerUserId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
        'No se pudo obtener el primer paciente.',
      );
    }
  }

  Stream<List<MedicationHistoryEntry>> streamMedicationHistory({
    required String userId,
    required String patientId,
  }) {
    try {
      return _service.streamMedicationHistory(userId: userId, patientId: patientId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
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
      await _service.addMedicationHistoryEntry(
        userId: userId,
        patientId: patientId,
        entry: entry,
      );
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
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
      await _service.updateMedicationHistoryEntry(
        userId: userId,
        patientId: patientId,
        entry: entry,
      );
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException(
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
      await _service.finalizeMedicationHistoryEntry(
        userId: userId,
        patientId: patientId,
        entryId: entryId,
        endedAt: endedAt,
      );
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException('No se pudo finalizar la medicación.');
    }
  }

  Future<void> deleteMedicationHistoryEntry({
    required String userId,
    required String patientId,
    required String entryId,
  }) async {
    try {
      await _service.deleteMedicationHistoryEntry(
        userId: userId,
        patientId: patientId,
        entryId: entryId,
      );
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException('No se pudo eliminar la medicación.');
    }
  }
}
