import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../models/medication_history_entry.dart';
import '../../models/seizure_model.dart';
import '../auth/auth_provider.dart';
import 'report_pdf_service.dart';
import 'report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (Ref ref) => ReportRepository(
    firestore: FirebaseFirestore.instance,
    authRepository: ref.watch(authRepositoryProvider),
  ),
);

final reportPdfServiceProvider = Provider<ReportPdfService>(
  (Ref ref) => ReportPdfService(),
);

final reportControllerProvider =
    AsyncNotifierProvider<ReportController, void>(ReportController.new);

class ReportController extends AsyncNotifier<void> {
  late final ReportRepository _repository;
  late final ReportPdfService _pdfService;

  @override
  FutureOr<void> build() {
    _repository = ref.read(reportRepositoryProvider);
    _pdfService = ref.read(reportPdfServiceProvider);
  }

  Future<void> generateAndShareMedicalReport({
    required String patientId,
    required DateTime startDate,
    required DateTime endDate,
    bool includeMedication = true,
    bool includeSeizures = true,
    bool includeSeizureNotes = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final patient = await _repository.fetchPatient(patientId);
      final medicationHistory = includeMedication
          ? await _repository.fetchAllMedicationHistory(patientId)
          : const <MedicationHistoryEntry>[];
      final seizuresInRange = includeSeizures
          ? await _repository.fetchSeizuresInRange(
              patientId: patientId,
              startInclusive: startDate,
              endInclusive: endDate,
            )
          : const <SeizureModel>[];

      final pdfBytes = await _pdfService.buildMedicalReportPdf(
        patient: patient,
        startDate: startDate,
        endDate: endDate,
        medicationHistory: medicationHistory,
        seizuresInRange: seizuresInRange,
        includeMedication: includeMedication,
        includeSeizures: includeSeizures,
        includeSeizureNotes: includeSeizureNotes,
      );

      final fileName =
          'informe_${_slug(patient.alias.isEmpty ? patient.id : patient.alias)}_${_fmtDateForFile(DateTime.now())}.pdf';
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    });
  }

  String _fmtDateForFile(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  String _slug(String value) {
    final cleaned =
        value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return cleaned.isEmpty ? 'paciente' : cleaned;
  }
}
