import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/rescue_medication.dart';
import '../auth/auth_provider.dart';
import '../seizures/seizure_provider.dart';
import 'patient_provider.dart';

class PatientScreen extends ConsumerWidget {
  const PatientScreen({
    required this.patientId,
    super.key,
  });

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final patientAsync = ref.watch(
      patientByIdProvider((userId: userId, patientId: patientId)),
    );

    return patientAsync.when(
      data: (patient) {
        final seizuresAsync = ref.watch(seizuresByPatientProvider(patient.id));
        final isMutationLoading = ref.watch(seizureControllerProvider).isLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              patient.alias.isNotEmpty
                  ? patient.alias
                  : 'Paciente ${patient.id.substring(0, 8)}',
            ),
          ),
          body: seizuresAsync.when(
            data: (seizures) {
              if (seizures.isEmpty) {
                return const Center(
                  child: Text('No hay crisis registradas para este paciente.'),
                );
              }

              return ListView.separated(
                itemCount: seizures.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final seizure = seizures[index];
                  final dateText =
                      '${seizure.dateTime.day.toString().padLeft(2, '0')}/'
                      '${seizure.dateTime.month.toString().padLeft(2, '0')}/'
                      '${seizure.dateTime.year} '
                      '${seizure.dateTime.hour.toString().padLeft(2, '0')}:'
                      '${seizure.dateTime.minute.toString().padLeft(2, '0')}';
                  final rescueMedication = _formatRescueMedication(
                    seizure.rescueMedicationCode,
                    seizure.rescueMedicationOther,
                  );
                  final medicationText = rescueMedication == null
                      ? ''
                      : '\nMedicación de rescate: $rescueMedication';
                  final durationText = _formatDuration(
                    durationSeconds: seizure.durationSeconds,
                    durationUnknown: seizure.durationUnknown,
                  );

                  return ListTile(
                    title: Text('${seizure.type}  Intensidad ${seizure.intensity}'),
                    subtitle: Text(
                      'Fecha: $dateText\nDuración: $durationText$medicationText',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: isMutationLoading
                          ? null
                          : () => _confirmDelete(context, ref, seizure.id),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object error, StackTrace stackTrace) {
              return Center(child: Text('Error: $error'));
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/patients/${patient.id}/seizures/new'),
            icon: const Icon(Icons.add_alert),
            label: const Text('Registrar crisis'),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) {
        return Scaffold(body: Center(child: Text('Error: $error')));
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String seizureId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar crisis'),
          content: const Text('Esta accion no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(seizureControllerProvider.notifier).deleteSeizure(seizureId);
    final state = ref.read(seizureControllerProvider);
    if (state.hasError && context.mounted) {
      final errorMessage = state.error.toString();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  String? _formatRescueMedication(String? code, String? other) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }

    if (code == RescueMedication.otherCode) {
      final normalizedOther = other?.trim() ?? '';
      return normalizedOther.isEmpty ? 'Otra / no listado' : normalizedOther;
    }

    return RescueMedication.fromCode(code)?.labelEs ?? code;
  }

  String _formatDuration({
    required int? durationSeconds,
    required bool durationUnknown,
  }) {
    if (durationUnknown) {
      return 'Desconocida';
    }
    if (durationSeconds == null) {
      return 'Sin dato';
    }
    if (durationSeconds % 60 == 0) {
      return '${durationSeconds ~/ 60} min';
    }
    return '$durationSeconds seg';
  }
}
