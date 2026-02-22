class RescueMedication {
  const RescueMedication({
    required this.code,
    required this.labelEs,
  });

  final String code;
  final String labelEs;

  static const String otherCode = 'OTHER';

  static const RescueMedication midazolamOromucosal = RescueMedication(
    code: 'MIDAZOLAM_OROMUCOSAL',
    labelEs: 'Midazolam (bucal/oromucosal)',
  );

  static const RescueMedication midazolamIntrnasal = RescueMedication(
    code: 'MIDAZOLAM_INTRNASAL',
    labelEs: 'Midazolam (intranasal)',
  );

  static const RescueMedication diazepamRectal = RescueMedication(
    code: 'DIAZEPAM_RECTAL',
    labelEs: 'Diazepam (rectal)',
  );

  static const RescueMedication diazepamIntranasal = RescueMedication(
    code: 'DIAZEPAM_INTRNASAL',
    labelEs: 'Diazepam (intranasal)',
  );

  static const RescueMedication diazepamOral = RescueMedication(
    code: 'DIAZEPAM_ORAL',
    labelEs: 'Diazepam (oral)',
  );

  static const RescueMedication lorazepamOral = RescueMedication(
    code: 'LORAZEPAM_ORAL',
    labelEs: 'Lorazepam (oral)',
  );

  static const RescueMedication clonazepamOral = RescueMedication(
    code: 'CLONAZEPAM_ORAL',
    labelEs: 'Clonazepam (oral)',
  );

  static const RescueMedication other = RescueMedication(
    code: otherCode,
    labelEs: 'Otra / no listado',
  );

  static const List<RescueMedication> values = <RescueMedication>[
    midazolamOromucosal,
    midazolamIntrnasal,
    diazepamRectal,
    diazepamIntranasal,
    diazepamOral,
    lorazepamOral,
    clonazepamOral,
    other,
  ];

  static RescueMedication? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }
    final normalized = code.trim();
    for (final option in values) {
      if (option.code == normalized) {
        return option;
      }
    }
    return null;
  }
}
