class CatalogOption {
  const CatalogOption({
    required this.code,
    required this.labelEs,
  });

  final String code;
  final String labelEs;
}

class PatientClinicalCatalog {
  static const List<CatalogOption> seizureFrequencyBaselineOptions =
      <CatalogOption>[
    CatalogOption(code: 'DAILY', labelEs: 'Diarias'),
    CatalogOption(code: 'WEEKLY', labelEs: 'Semanales'),
    CatalogOption(code: 'MONTHLY', labelEs: 'Mensuales'),
    CatalogOption(code: 'OCCASIONAL', labelEs: 'Ocasionales'),
    CatalogOption(code: 'UNKNOWN', labelEs: 'No lo sé'),
  ];

  static const List<CatalogOption> comorbidityOptions = <CatalogOption>[
    CatalogOption(
      code: 'DEVELOPMENTAL_DELAY',
      labelEs: 'Retraso del desarrollo',
    ),
    CatalogOption(code: 'AUTISM_TRAITS', labelEs: 'Rasgos TEA / Autismo'),
    CatalogOption(code: 'SLEEP_PROBLEMS', labelEs: 'Problemas de sueño'),
    CatalogOption(
      code: 'FEEDING_DIFFICULTIES',
      labelEs: 'Dificultades de alimentación',
    ),
    CatalogOption(code: 'GERD', labelEs: 'Reflujo / problemas digestivos'),
    CatalogOption(
      code: 'BEHAVIORAL_CHALLENGES',
      labelEs: 'Conducta (irritabilidad, agitación)',
    ),
    CatalogOption(code: 'MOTOR_IMPAIRMENT', labelEs: 'Dificultades motoras'),
    CatalogOption(code: 'VISION_PROBLEMS', labelEs: 'Problemas de visión'),
    CatalogOption(code: 'HEARING_PROBLEMS', labelEs: 'Problemas de audición'),
    CatalogOption(code: 'NONE', labelEs: 'Ninguna'),
    CatalogOption(code: 'UNKNOWN', labelEs: 'No lo sé'),
  ];

  static const List<CatalogOption> therapyOptions = <CatalogOption>[
    CatalogOption(code: 'PHYSIOTHERAPY', labelEs: 'Fisioterapia'),
    CatalogOption(
      code: 'OCCUPATIONAL_THERAPY',
      labelEs: 'Terapia ocupacional',
    ),
    CatalogOption(code: 'SPEECH_THERAPY', labelEs: 'Logopedia'),
    CatalogOption(code: 'AAC', labelEs: 'Comunicación aumentativa'),
    CatalogOption(code: 'PSYCHOLOGY', labelEs: 'Apoyo psicológico'),
    CatalogOption(code: 'EARLY_INTERVENTION', labelEs: 'Atención temprana'),
    CatalogOption(code: 'NONE', labelEs: 'Ninguna'),
    CatalogOption(code: 'UNKNOWN', labelEs: 'No lo sé'),
    CatalogOption(code: 'OTHER', labelEs: 'Otra'),
  ];

  static const List<CatalogOption> deviceOptions = <CatalogOption>[
    CatalogOption(code: 'WHEELCHAIR', labelEs: 'Silla de ruedas'),
    CatalogOption(code: 'WALKER', labelEs: 'Andador'),
    CatalogOption(code: 'ORTHOSES', labelEs: 'Ortesis'),
    CatalogOption(
      code: 'STROLLER_ADAPTIVE',
      labelEs: 'Silla/paseador adaptado',
    ),
    CatalogOption(code: 'FEEDING_TUBE_PEG', labelEs: 'Gastrostomía (PEG)'),
    CatalogOption(code: 'FEEDING_TUBE_NG', labelEs: 'Sonda nasogástrica'),
    CatalogOption(code: 'OXYGEN', labelEs: 'Oxígeno'),
    CatalogOption(code: 'SEIZURE_MONITOR', labelEs: 'Monitor de crisis'),
    CatalogOption(code: 'HELMET', labelEs: 'Casco protector'),
    CatalogOption(code: 'NONE', labelEs: 'Ninguno'),
    CatalogOption(code: 'UNKNOWN', labelEs: 'No lo sé'),
    CatalogOption(code: 'OTHER', labelEs: 'Otro'),
  ];

  static bool isValidSeizureFrequencyBaseline(String value) {
    return seizureFrequencyBaselineOptions.any(
      (option) => option.code == value,
    );
  }

  static bool isValidComorbidity(String value) {
    return comorbidityOptions.any((option) => option.code == value);
  }

  static bool isValidTherapy(String value) {
    return therapyOptions.any((option) => option.code == value);
  }

  static bool isValidDevice(String value) {
    return deviceOptions.any((option) => option.code == value);
  }
}
