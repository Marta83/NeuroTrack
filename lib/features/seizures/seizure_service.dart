import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/seizure_model.dart';

class SeizureServiceException implements Exception {
  const SeizureServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SeizureService {
  SeizureService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _seizuresCollection =>
      _firestore.collection('seizures');

  CollectionReference<Map<String, dynamic>> get _patientsCollection =>
      _firestore.collection('patients');

  Future<void> createSeizure({
    required String ownerUserId,
    required SeizureModel seizure,
  }) async {
    try {
      await _assertPatientOwnership(
        patientId: seizure.patientId,
        ownerUserId: ownerUserId,
      );
      await _seizuresCollection.doc(seizure.id).set(seizure.toMap());
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        error.message ?? 'No se pudo crear la crisis.',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (_) {
      throw const SeizureServiceException('No se pudo crear la crisis.');
    }
  }

  Future<void> updateSeizure({
    required String ownerUserId,
    required SeizureModel seizure,
  }) async {
    try {
      await _assertPatientOwnership(
        patientId: seizure.patientId,
        ownerUserId: ownerUserId,
      );
      final updatedSeizure = seizure.copyWith(updatedAt: DateTime.now());
      await _seizuresCollection.doc(updatedSeizure.id).update(updatedSeizure.toMap());
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        error.message ?? 'No se pudo actualizar la crisis.',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (_) {
      throw const SeizureServiceException('No se pudo actualizar la crisis.');
    }
  }

  Future<void> deleteSeizure({
    required String ownerUserId,
    required String seizureId,
  }) async {
    try {
      final seizureDoc = await _seizuresCollection.doc(seizureId).get();
      if (!seizureDoc.exists) {
        throw const SeizureServiceException('La crisis no existe.');
      }

      final data = seizureDoc.data();
      if (data == null) {
        throw const SeizureServiceException('No se pudo leer la crisis.');
      }

      final patientId = (data['patientId'] as String?) ?? '';
      if (patientId.isEmpty) {
        throw const SeizureServiceException('La crisis no tiene patientId valido.');
      }

      await _assertPatientOwnership(
        patientId: patientId,
        ownerUserId: ownerUserId,
      );
      await _seizuresCollection.doc(seizureId).delete();
    } on FirebaseException catch (error) {
      throw SeizureServiceException(
        error.message ?? 'No se pudo eliminar la crisis.',
      );
    } on SeizureServiceException {
      rethrow;
    } catch (_) {
      throw const SeizureServiceException('No se pudo eliminar la crisis.');
    }
  }

  Stream<List<SeizureModel>> streamSeizuresByPatient({
    required String ownerUserId,
    required String patientId,
  }) async* {
    await _assertPatientOwnership(
      patientId: patientId,
      ownerUserId: ownerUserId,
    );

    yield* _seizuresCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final data = doc.data();
            if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
              data['id'] = doc.id;
            }
            return SeizureModel.fromMap(data);
          })
          .toList(growable: false);
    });
  }

  Future<void> _assertPatientOwnership({
    required String patientId,
    required String ownerUserId,
  }) async {
    final patientDoc = await _patientsCollection.doc(patientId).get();
    if (!patientDoc.exists) {
      throw const SeizureServiceException('El paciente no existe.');
    }

    final data = patientDoc.data();
    final patientOwner = (data?['ownerUserId'] as String?) ?? '';
    if (patientOwner != ownerUserId) {
      throw const SeizureServiceException(
        'No tienes permisos para acceder a este paciente.',
      );
    }
  }
}
