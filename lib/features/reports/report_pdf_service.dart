import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/formatters/seizure_labels.dart';
import '../../models/medication_history_entry.dart';
import '../../models/patient_model.dart';
import '../../models/rescue_medication.dart';
import '../../models/seizure_model.dart';
import '../../models/seizure_trigger.dart';

class ReportPdfService {
  Future<Uint8List> buildMedicalReportPdf({
    required PatientModel patient,
    required DateTime startDate,
    required DateTime endDate,
    required List<MedicationHistoryEntry> medicationHistory,
    required List<SeizureModel> seizuresInRange,
    required bool includeMedication,
    required bool includeSeizures,
    required bool includeSeizureNotes,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        maxPages: 200,
        build: (context) => <pw.Widget>[
          _header(patient: patient, startDate: startDate, endDate: endDate),
          pw.SizedBox(height: 12),
          _patientInfo(patient),
          if (includeMedication) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            _medicationHistorySection(medicationHistory),
          ],
          if (includeSeizures) ...<pw.Widget>[
            pw.SizedBox(height: 18),
            _seizureSummarySection(seizuresInRange),
            pw.SizedBox(height: 12),
            _seizureListSection(
              seizuresInRange,
              includeNotes: includeSeizureNotes,
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Este informe está pensado para compartir con tu profesional sanitario.',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header({
    required PatientModel patient,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final alias = patient.alias.trim().isEmpty ? 'Paciente' : patient.alias;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          _safe('Informe de episodios - $alias'),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Rango de episodios: ${_fmtDate(startDate)} - ${_fmtDate(endDate)}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _patientInfo(PatientModel patient) {
    final ageApprox = DateTime.now().year - patient.birthYear;
    return _section(
      title: 'Datos del paciente',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _line('Alias',
              patient.alias.trim().isEmpty ? 'Sin alias' : patient.alias),
          _line('Edad aproximada', '$ageApprox años'),
          _line(
            'Genes',
            patient.geneSummary.isEmpty
                ? 'Sin datos'
                : patient.geneSummary.join(', '),
          ),
          _line('Sexo', patient.sex),
          _line('País / ciudad', _countryCity(patient)),
          _line('Hospital', patient.referenceHospital ?? 'Sin dato'),
        ],
      ),
    );
  }

  pw.Widget _medicationHistorySection(List<MedicationHistoryEntry> medication) {
    if (medication.isEmpty) {
      return _section(
        title: 'Medicacion (historial completo)',
        child: pw.Text(
          _safe('No hay cambios de medicacion registrados.'),
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }

    final rows = medication
        .map((entry) => <String>[
              entry.name,
              _medicationDoseText(entry),
              _fmtDate(entry.startedAt),
              entry.endedAt == null ? 'En curso' : _fmtDate(entry.endedAt!),
              entry.reason ?? '',
              entry.notes ?? '',
            ])
        .toList(growable: false);

    return _section(
      title: 'Medicacion (historial completo)',
      child: pw.TableHelper.fromTextArray(
        headers: _safeList(const <String>[
          'Medicación',
          'Dosis',
          'Inicio',
          'Fin',
          'Motivo',
          'Notas',
        ]),
        data: rows.map(_safeList).toList(growable: false),
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8.5),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
        cellAlignments: const <int, pw.Alignment>{
          0: pw.Alignment.centerLeft,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.centerLeft,
          5: pw.Alignment.centerLeft,
        },
      ),
    );
  }

  pw.Widget _seizureSummarySection(List<SeizureModel> seizures) {
    final total = seizures.length;
    final avgIntensity =
        _avgDouble(seizures.map((e) => e.intensity.toDouble()));
    final avgDuration = _avgDouble(
      seizures
          .map((e) => e.durationSeconds)
          .whereType<int>()
          .map((value) => value.toDouble()),
    );
    final avgRecovery = _avgDouble(
      seizures
          .map((e) => e.postictalRecoveryMinutes)
          .whereType<int>()
          .map((value) => value.toDouble()),
    );
    final topTypes = _topTypes(seizures);

    return _section(
      title: 'Resumen de episodios (solo rango)',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          _line('Nº episodios', '$total'),
          _line(
            'Intensidad media',
            avgIntensity == null ? 'Sin dato' : avgIntensity.toStringAsFixed(1),
          ),
          _line(
            'Duración media',
            avgDuration == null
                ? 'Sin dato'
                : '${avgDuration.toStringAsFixed(1)} seg',
          ),
          _line(
            'Recuperación media',
            avgRecovery == null
                ? 'Sin dato'
                : '${avgRecovery.toStringAsFixed(1)} min',
          ),
          _line(
            'Tipos más frecuentes',
            topTypes.isEmpty ? 'Sin dato' : topTypes.join(', '),
          ),
        ],
      ),
    );
  }

  pw.Widget _seizureListSection(
    List<SeizureModel> seizures, {
    required bool includeNotes,
  }) {
    if (seizures.isEmpty) {
      return _section(
        title: 'Lista de episodios (solo rango)',
        child: pw.Text(
          _safe('No hay episodios en este periodo.'),
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }

    final headers = <String>[
      'Fecha/hora',
      'Tipo',
      'Duración',
      'Intensidad',
      'Recuperación',
      'Rescate',
      'Contexto',
      if (includeNotes) 'Notas',
    ];

    final rows = seizures.map((seizure) {
      final contextText = seizure.triggers
          .map((code) => SeizureTrigger.fromCode(code)?.labelEs ?? code)
          .join(', ');

      return <String>[
        _fmtDateTime(seizure.dateTime),
        seizureTypeLabel(seizure.type),
        seizure.durationUnknown
            ? 'Desconocida'
            : seizure.durationSeconds == null
                ? 'Sin dato'
                : '${seizure.durationSeconds} seg',
        '${seizure.intensity}',
        seizure.postictalRecoveryMinutes == null
            ? 'Sin dato'
            : '${seizure.postictalRecoveryMinutes} min',
        _rescueLabel(seizure),
        contextText.isEmpty ? 'Sin contexto' : contextText,
        if (includeNotes) seizure.notes ?? '',
      ];
    }).toList(growable: false);

    return _section(
      title: 'Lista de episodios (solo rango)',
      child: pw.TableHelper.fromTextArray(
        headers: _safeList(headers),
        data: rows.map(_safeList).toList(growable: false),
        headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
        cellStyle: const pw.TextStyle(fontSize: 8.2),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      ),
    );
  }

  pw.Widget _section({required String title, required pw.Widget child}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          _safe(title),
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        child,
      ],
    );
  }

  pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          style: const pw.TextStyle(fontSize: 10),
          children: <pw.TextSpan>[
            pw.TextSpan(
              text: '${_safe(label)}: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: _safe(value)),
          ],
        ),
      ),
    );
  }

  String _countryCity(PatientModel patient) {
    final parts = <String>[
      if (patient.country.trim().isNotEmpty) patient.country,
      if ((patient.city ?? '').trim().isNotEmpty) patient.city!,
    ];
    return parts.isEmpty ? 'Sin dato' : parts.join(' · ');
  }

  String _medicationDoseText(MedicationHistoryEntry entry) {
    final parts = <String>[];
    if (entry.doseAmount != null) {
      final amount = entry.doseAmount!;
      parts.add(
        amount == amount.roundToDouble()
            ? amount.toStringAsFixed(0)
            : amount.toString(),
      );
    }
    if ((entry.doseUnit ?? '').trim().isNotEmpty) {
      parts.add(entry.doseUnit!.trim());
    }
    final frequency = entry.frequencyPerDay;
    if (frequency != null) {
      final suffix = frequency == 1 ? 'vez/día' : 'veces/día';
      parts.add('$frequency $suffix');
    } else if (entry.isPrn) {
      parts.add('PRN');
    }
    if (entry.timing.isNotEmpty) {
      parts.add(entry.timing.join(', '));
    }
    return parts.isEmpty ? 'Sin dato' : parts.join(' · ');
  }

  double? _avgDouble(Iterable<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return total / values.length;
  }

  List<String> _topTypes(List<SeizureModel> seizures) {
    final counters = <String, int>{};
    for (final seizure in seizures) {
      counters.update(seizure.type, (value) => value + 1, ifAbsent: () => 1);
    }
    final sorted = counters.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((entry) {
      return '${seizureTypeLabel(entry.key)} (${entry.value})';
    }).toList(growable: false);
  }

  String _rescueLabel(SeizureModel seizure) {
    final code = seizure.rescueMedicationCode;
    if (code == null || code.trim().isEmpty) {
      return 'No';
    }
    if (code == RescueMedication.otherCode) {
      final other = seizure.rescueMedicationOther?.trim() ?? '';
      return other.isEmpty ? 'Otra / no listado' : other;
    }
    return RescueMedication.fromCode(code)?.labelEs ?? code;
  }

  String _fmtDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _fmtDateTime(DateTime value) {
    return '${_fmtDate(value)} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  List<String> _safeList(List<String> values) {
    return values.map(_safe).toList(growable: false);
  }

  String _safe(String input) {
    const map = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'ñ': 'n',
      'Ñ': 'N',
      'ü': 'u',
      'Ü': 'U',
      'º': 'o',
      '·': ' - ',
    };
    final sb = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final replaced = map[ch] ?? ch;
      if (replaced.runes.every((value) => value <= 127)) {
        sb.write(replaced);
      }
    }
    return sb.toString();
  }
}
