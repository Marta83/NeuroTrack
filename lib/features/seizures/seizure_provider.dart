import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../../models/seizure_model.dart';
import 'seizure_repository.dart';
import 'seizure_service.dart';

final seizureServiceProvider = Provider<SeizureService>(
  (Ref ref) => SeizureService(),
);

final seizureRepositoryProvider = Provider<SeizureRepository>(
  (Ref ref) => SeizureRepository(
    service: ref.watch(seizureServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  ),
);

/// Estados expuestos en AsyncValue: loading / error / data.
final seizuresByPatientProvider =
    StreamProvider.family.autoDispose<List<SeizureModel>, String>(
  (Ref ref, String patientId) {
    return ref.watch(seizureRepositoryProvider).streamSeizuresByPatient(patientId);
  },
);

final seizureControllerProvider =
    AsyncNotifierProvider<SeizureController, void>(SeizureController.new);

class SeizureController extends AsyncNotifier<void> {
  late final SeizureRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.read(seizureRepositoryProvider);
  }

  Future<void> createSeizure(SeizureModel seizure) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.createSeizure(seizure));
  }

  Future<void> updateSeizure(SeizureModel seizure) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateSeizure(seizure));
  }

  Future<void> deleteSeizure(String seizureId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteSeizure(seizureId));
  }
}
