import '../../models/patient_model.dart';
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
      throw const PatientRepositoryException('No se pudo actualizar el paciente.');
    }
  }

  Stream<List<PatientModel>> streamPatientsByOwner(String userId) {
    try {
      return _service.streamPatientsByOwner(userId);
    } on PatientServiceException catch (error) {
      throw PatientRepositoryException(error.message);
    } catch (_) {
      throw const PatientRepositoryException('No se pudieron obtener los pacientes.');
    }
  }
}
