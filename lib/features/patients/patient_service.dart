import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/patient_model.dart';

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
      await _patientsCollection.doc(updatedPatient.id).update(updatedPatient.toMap());
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
              if ((data['id'] as String?) == null || (data['id'] as String).isEmpty) {
                data['id'] = doc.id;
              }
              return PatientModel.fromMap(data);
            })
            .toList(growable: false);
      });
    } on FirebaseException catch (error) {
      throw PatientServiceException(
        error.message ?? 'No se pudieron obtener los pacientes.',
      );
    } catch (_) {
      throw const PatientServiceException('No se pudieron obtener los pacientes.');
    }
  }
}
