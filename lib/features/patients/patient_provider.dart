import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_model.dart';
import 'patient_repository.dart';
import 'patient_service.dart';

final patientServiceProvider = Provider<PatientService>(
  (Ref ref) => PatientService(),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (Ref ref) => PatientRepository(ref.watch(patientServiceProvider)),
);

/// Estados expuestos en AsyncValue: loading / error / data.
final patientsByOwnerProvider =
    StreamProvider.family.autoDispose<List<PatientModel>, String>(
  (Ref ref, String userId) {
    return ref.watch(patientRepositoryProvider).streamPatientsByOwner(userId);
  },
);

final patientControllerProvider =
    AsyncNotifierProvider<PatientController, void>(PatientController.new);

class PatientController extends AsyncNotifier<void> {
  late final PatientRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.read(patientRepositoryProvider);
  }

  Future<void> createPatient(PatientModel patient) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.createPatient(patient));
  }

  Future<void> updatePatient(PatientModel patient) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updatePatient(patient));
  }
}
