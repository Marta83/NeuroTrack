import '../auth/auth_repository.dart';
import '../../models/seizure_model.dart';
import 'seizure_service.dart';

class SeizureRepositoryException implements Exception {
  const SeizureRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SeizureRepository {
  const SeizureRepository({
    required SeizureService service,
    required AuthRepository authRepository,
  })  : _service = service,
        _authRepository = authRepository;

  final SeizureService _service;
  final AuthRepository _authRepository;

  Future<void> createSeizure(SeizureModel seizure) async {
    try {
      final userId = _requireUserId();
      await _service.createSeizure(ownerUserId: userId, seizure: seizure);
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (_) {
      throw const SeizureRepositoryException('No se pudo crear la crisis.');
    }
  }

  Future<void> updateSeizure(SeizureModel seizure) async {
    try {
      final userId = _requireUserId();
      await _service.updateSeizure(ownerUserId: userId, seizure: seizure);
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (_) {
      throw const SeizureRepositoryException(
          'No se pudo actualizar la crisis.');
    }
  }

  Future<void> deleteSeizure(String seizureId) async {
    try {
      final userId = _requireUserId();
      await _service.deleteSeizure(ownerUserId: userId, seizureId: seizureId);
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (_) {
      throw const SeizureRepositoryException('No se pudo eliminar la crisis.');
    }
  }

  Stream<List<SeizureModel>> streamSeizuresByPatient(String patientId) {
    try {
      final userId = _requireUserId();
      return _service.streamSeizuresByPatient(
        ownerUserId: userId,
        patientId: patientId,
      );
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (_) {
      throw const SeizureRepositoryException(
          'No se pudieron obtener las crisis.');
    }
  }

  Stream<List<SeizureModel>> streamSeizuresByPatientFrom({
    required String patientId,
    required DateTime from,
  }) {
    try {
      final userId = _requireUserId();
      return _service.streamSeizuresByPatientFrom(
        ownerUserId: userId,
        patientId: patientId,
        from: from,
      );
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (_) {
      throw const SeizureRepositoryException(
          'No se pudieron obtener las crisis.');
    }
  }

  Stream<List<SeizureModel>> streamSeizuresByPatientBetween({
    required String patientId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    try {
      final userId = _requireUserId();
      return _service.streamSeizuresByPatientBetween(
        ownerUserId: userId,
        patientId: patientId,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
      );
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (_) {
      throw const SeizureRepositoryException(
          'No se pudieron obtener las crisis.');
    }
  }

  Future<void> seedTestSeizuresForPatient(
    String patientId, {
    int count = 80,
  }) async {
    try {
      final userId = _requireUserId();
      await _service.seedTestSeizuresForPatient(
        patientId,
        ownerUserId: userId,
        count: count,
      );
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (error) {
      throw SeizureRepositoryException(
        'No se pudieron generar crisis de prueba. Detalle: $error',
      );
    }
  }

  Future<int> deleteSeededTestSeizuresForPatient(String patientId) async {
    try {
      final userId = _requireUserId();
      return await _service.deleteSeededTestSeizuresForPatient(
        patientId,
        ownerUserId: userId,
      );
    } on SeizureServiceException catch (error) {
      throw SeizureRepositoryException(error.message);
    } on SeizureRepositoryException {
      rethrow;
    } catch (error) {
      throw SeizureRepositoryException(
        'No se pudieron eliminar crisis de prueba. Detalle: $error',
      );
    }
  }

  String _requireUserId() {
    final user = _authRepository.currentUser;
    if (user == null) {
      throw const SeizureRepositoryException('Usuario no autenticado.');
    }
    return user.uid;
  }
}
