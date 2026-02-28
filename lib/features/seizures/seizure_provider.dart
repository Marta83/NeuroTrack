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
    return ref
        .watch(seizureRepositoryProvider)
        .streamSeizuresByPatient(patientId);
  },
);

final seizuresAnalyticsByPatientProvider = StreamProvider.family
    .autoDispose<List<SeizureModel>, ({String patientId, int daysBack})>(
  (Ref ref, ({String patientId, int daysBack}) args) {
    final from = DateTime.now().subtract(Duration(days: args.daysBack));
    return ref.watch(seizureRepositoryProvider).streamSeizuresByPatientFrom(
          patientId: args.patientId,
          from: from,
        );
  },
);

final seizuresByPatientMonthProvider = StreamProvider.family
    .autoDispose<List<SeizureModel>, ({String patientId, DateTime month})>(
  (Ref ref, ({String patientId, DateTime month}) args) {
    final start = DateTime(args.month.year, args.month.month, 1);
    final end = DateTime(args.month.year, args.month.month + 1, 1);
    return ref.watch(seizureRepositoryProvider).streamSeizuresByPatientBetween(
          patientId: args.patientId,
          startInclusive: start,
          endExclusive: end,
        );
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
