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
      throw const SeizureRepositoryException('No se pudo actualizar la crisis.');
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
      throw const SeizureRepositoryException('No se pudieron obtener las crisis.');
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
