import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/seizure_model.dart';
import '../../models/seizure_trigger.dart';

class SeizureContextFormState {
  const SeizureContextFormState({
    this.triggers = const <String>{},
    this.injury = false,
    this.cyanosis = false,
    this.emergencyCall = false,
    this.emergencyVisit = false,
  });

  final Set<String> triggers;
  final bool injury;
  final bool cyanosis;
  final bool emergencyCall;
  final bool emergencyVisit;

  bool hasTrigger(String code) => triggers.contains(code);

  SeizureContextFormState copyWith({
    Set<String>? triggers,
    bool? injury,
    bool? cyanosis,
    bool? emergencyCall,
    bool? emergencyVisit,
  }) {
    return SeizureContextFormState(
      triggers: triggers ?? this.triggers,
      injury: injury ?? this.injury,
      cyanosis: cyanosis ?? this.cyanosis,
      emergencyCall: emergencyCall ?? this.emergencyCall,
      emergencyVisit: emergencyVisit ?? this.emergencyVisit,
    );
  }
}

class SeizureContextFormController extends StateNotifier<SeizureContextFormState> {
  SeizureContextFormController() : super(const SeizureContextFormState());

  bool hasTrigger(String code) => state.hasTrigger(code);

  void toggleTrigger(String code) {
    if (SeizureTrigger.fromCode(code) == null) {
      return;
    }

    final updated = <String>{...state.triggers};
    if (updated.contains(code)) {
      updated.remove(code);
    } else {
      updated.add(code);
    }

    state = state.copyWith(triggers: updated);
  }

  void setFlag({
    bool? injury,
    bool? cyanosis,
    bool? emergencyCall,
    bool? emergencyVisit,
  }) {
    state = state.copyWith(
      injury: injury,
      cyanosis: cyanosis,
      emergencyCall: emergencyCall,
      emergencyVisit: emergencyVisit,
    );
  }

  void loadFromSeizure(SeizureModel seizure) {
    state = SeizureContextFormState(
      triggers: seizure.triggers.toSet(),
      injury: seizure.injury,
      cyanosis: seizure.cyanosis,
      emergencyCall: seizure.emergencyCall,
      emergencyVisit: seizure.emergencyVisit,
    );
  }
}

final seizureContextFormProvider = StateNotifierProvider.autoDispose<
    SeizureContextFormController, SeizureContextFormState>(
  (Ref ref) => SeizureContextFormController(),
);
