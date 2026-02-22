class SeizureTrigger {
  const SeizureTrigger({
    required this.code,
    required this.labelEs,
  });

  final String code;
  final String labelEs;

  static const SeizureTrigger sleepDeprivation = SeizureTrigger(
    code: 'SLEEP_DEPRIVATION',
    labelEs: 'Falta de sueño',
  );

  static const SeizureTrigger fever = SeizureTrigger(
    code: 'FEVER',
    labelEs: 'Fiebre / infección',
  );

  static const SeizureTrigger stress = SeizureTrigger(
    code: 'STRESS',
    labelEs: 'Estrés',
  );

  static const SeizureTrigger missedMeds = SeizureTrigger(
    code: 'MISSED_MEDS',
    labelEs: 'Olvido de medicación',
  );

  static const SeizureTrigger unknown = SeizureTrigger(
    code: 'UNKNOWN',
    labelEs: 'No se sabe',
  );

  static const List<SeizureTrigger> values = <SeizureTrigger>[
    sleepDeprivation,
    fever,
    stress,
    missedMeds,
    unknown,
  ];

  static SeizureTrigger? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }
    final normalized = code.trim();
    for (final trigger in values) {
      if (trigger.code == normalized) {
        return trigger;
      }
    }
    return null;
  }
}
