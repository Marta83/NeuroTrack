import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters/seizure_labels.dart';
import '../../models/patient_model.dart';
import '../../models/rescue_medication.dart';
import '../../models/seizure_model.dart';
import '../../ui/soft_ui.dart';
import '../auth/auth_provider.dart';
import '../reports/report_provider.dart';
import '../seizures/seizure_provider.dart';
import 'patient_provider.dart';

final patientRangeDaysProvider =
    StateProvider.family.autoDispose<int, String>((Ref ref, String patientId) {
  return 30;
});

final patientEpisodesPageProvider =
    StateProvider.family.autoDispose<int, String>((Ref ref, String patientId) {
  return 0;
});

class PatientScreen extends ConsumerWidget {
  const PatientScreen({
    required this.patientId,
    super.key,
  });

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid;
    final rangeDays = ref.watch(patientRangeDaysProvider(patientId));
    final episodesPage = ref.watch(patientEpisodesPageProvider(patientId));
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final patientAsync = ref.watch(
      patientByIdProvider((userId: userId, patientId: patientId)),
    );

    return patientAsync.when(
      data: (patient) {
        final allSeizuresAsync =
            ref.watch(seizuresByPatientProvider(patient.id));
        final analyticsAsync = ref.watch(
          seizuresAnalyticsByPatientProvider(
              (patientId: patient.id, daysBack: 180)),
        );
        final isMutationLoading =
            ref.watch(seizureControllerProvider).isLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(patient.alias.isNotEmpty ? patient.alias : 'Paciente'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Ver evolución',
                onPressed: () =>
                    context.push('/patients/${patient.id}/history'),
                icon: const Icon(Icons.insights_outlined),
              ),
              IconButton(
                tooltip: 'Editar',
                onPressed: () => context.push('/patients/${patient.id}/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Exportar informe (PDF)',
                onPressed: () => _openExportReportSheet(context, ref, patient),
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () => _confirmSignOut(context, ref),
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: SoftConstrainedBody(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: <Widget>[
                  _buildCompactHeader(
                    context,
                    patient,
                    onSeedPressed: kDebugMode
                        ? () async {
                            try {
                              await ref
                                  .read(seizureRepositoryProvider)
                                  .seedTestSeizuresForPatient(patient.id,
                                      count: 80);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Crisis de prueba generadas.'),
                                  ),
                                );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                            }
                          }
                        : null,
                    onDeleteSeedPressed: kDebugMode
                        ? () async {
                            try {
                              final deleted = await ref
                                  .read(seizureRepositoryProvider)
                                  .deleteSeededTestSeizuresForPatient(
                                      patient.id);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      deleted == 0
                                          ? 'No había crisis de prueba para borrar.'
                                          : 'Crisis de prueba eliminadas: $deleted',
                                    ),
                                  ),
                                );
                            } catch (error) {
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text(error.toString())),
                                );
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: gapSection),
                  analyticsAsync.when(
                    data: (analyticsSeizures) {
                      return _buildEvolutionSection(
                        context,
                        seizuresForAnalytics: analyticsSeizures,
                        patient: patient,
                        rangeDays: rangeDays,
                        onRangeChanged: (int value) {
                          ref
                              .read(
                                  patientRangeDaysProvider(patientId).notifier)
                              .state = value;
                        },
                      );
                    },
                    loading: () => _buildLoadingEvolution(context),
                    error: (Object error, StackTrace stackTrace) {
                      return Text('Error en evolución: $error');
                    },
                  ),
                  const SizedBox(height: gapSection),
                  const SoftSectionHeader(
                    icon: Icons.history,
                    title: 'Últimos episodios',
                  ),
                  allSeizuresAsync.when(
                    data: (seizures) {
                      if (seizures.isEmpty) {
                        return const Text(
                            'No hay crisis registradas para este paciente.');
                      }

                      const pageSize = 15;
                      final totalPages = (seizures.length / pageSize).ceil();
                      final currentPage = episodesPage.clamp(0, totalPages - 1);
                      final start = currentPage * pageSize;
                      final end = math.min(start + pageSize, seizures.length);
                      final pageItems = seizures.sublist(start, end);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'Página ${currentPage + 1} de $totalPages',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Página anterior',
                                onPressed: currentPage > 0
                                    ? () {
                                        ref
                                            .read(patientEpisodesPageProvider(
                                                    patientId)
                                                .notifier)
                                            .state = currentPage - 1;
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Página siguiente',
                                onPressed: currentPage < totalPages - 1
                                    ? () {
                                        ref
                                            .read(patientEpisodesPageProvider(
                                                    patientId)
                                                .notifier)
                                            .state = currentPage + 1;
                                      }
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                          ...pageItems.map((seizure) {
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
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              title: Text(
                                  '${seizureTypeLabel(seizure.type)} · Intensidad ${seizure.intensity}'),
                              subtitle: Text(
                                'Fecha: ${_formatDateTime(seizure.dateTime)}\n'
                                'Duración: $durationText$medicationText',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    tooltip: 'Editar crisis',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: isMutationLoading
                                        ? null
                                        : () => context.push(
                                              '/patients/${patient.id}/seizures/${seizure.id}/edit',
                                              extra: seizure,
                                            ),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar crisis',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: isMutationLoading
                                        ? null
                                        : () => _confirmDelete(
                                            context, ref, seizure.id),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (Object error, StackTrace stackTrace) {
                      return Text('Error: $error');
                    },
                  ),
                  const SizedBox(height: 70),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.push('/patients/${patient.id}/seizures/new'),
            icon: const Icon(Icons.add_alert),
            label: const Text('Registrar crisis'),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) {
        return Scaffold(body: Center(child: Text('Error: $error')));
      },
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    PatientModel patient, {
    required VoidCallback? onSeedPressed,
    required VoidCallback? onDeleteSeedPressed,
  }) {
    final age = DateTime.now().year - patient.birthYear;
    final gene =
        patient.geneSummary.isEmpty ? 'Sin gen' : patient.geneSummary.first;
    final hospital = patient.referenceHospital;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '${patient.alias.isNotEmpty ? patient.alias : 'Paciente'} · $age años · $gene',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (hospital != null && hospital.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            hospital,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 4),
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => context.push('/patients/${patient.id}/profile'),
          child: const Text('Ver perfil completo'),
        ),
        if (kDebugMode && onSeedPressed != null)
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: onSeedPressed,
            icon: const Icon(Icons.bug_report_outlined, size: 16),
            label: const Text('Generar datos de prueba'),
          ),
        if (kDebugMode && onDeleteSeedPressed != null)
          TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: onDeleteSeedPressed,
            icon: const Icon(Icons.delete_sweep_outlined, size: 16),
            label: const Text('Borrar datos de prueba'),
          ),
      ],
    );
  }

  Widget _buildLoadingEvolution(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEvolutionSection(
    BuildContext context, {
    required List<SeizureModel> seizuresForAnalytics,
    required PatientModel patient,
    required int rangeDays,
    required ValueChanged<int> onRangeChanged,
  }) {
    final now = DateTime.now();
    final currentStart = now.subtract(Duration(days: rangeDays));
    final previousStart = now.subtract(Duration(days: rangeDays * 2));
    final previousEnd = currentStart;

    final currentSeizures = _filterByDateRange(
      seizuresForAnalytics,
      startInclusive: currentStart,
      endExclusive: now.add(const Duration(seconds: 1)),
    );
    final previousSeizures = _filterByDateRange(
      seizuresForAnalytics,
      startInclusive: previousStart,
      endExclusive: previousEnd,
    );

    final totalCurrent = currentSeizures.length;
    final totalPrev = previousSeizures.length;
    final trend =
        _computeTrend(totalCurrent: totalCurrent, totalPrev: totalPrev);
    final series = _buildFrequencySeries(
      seizures: currentSeizures,
      rangeDays: rangeDays,
      now: now,
    );

    final metrics = <_MetricItem>[
      _MetricItem(label: 'Crisis', value: '$totalCurrent'),
      _MetricItem(
          label: 'Intensidad media', value: _avgIntensity(currentSeizures)),
      _MetricItem(
          label: 'Duración media', value: _avgDuration(currentSeizures)),
      _MetricItem(
          label: 'Recuperación media', value: _avgRecovery(currentSeizures)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(icon: Icons.show_chart, title: 'Evolución'),
        _RangeFilter(
          selectedDays: rangeDays,
          onChanged: onRangeChanged,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map((metric) => _MetricPill(metric: metric))
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
        _TrendIndicator(
          trend: trend,
          rangeDays: rangeDays,
        ),
        const SizedBox(height: 16),
        _FrequencyChart(series: series),
      ],
    );
  }

  List<SeizureModel> _filterByDateRange(
    List<SeizureModel> seizures, {
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return seizures.where((seizure) {
      return !seizure.dateTime.isBefore(startInclusive) &&
          seizure.dateTime.isBefore(endExclusive);
    }).toList(growable: false);
  }

  _TrendData _computeTrend({
    required int totalCurrent,
    required int totalPrev,
  }) {
    if (totalPrev == 0) {
      if (totalCurrent == 0) {
        return const _TrendData.neutral('Sin cambios');
      }
      return const _TrendData.upNoPct('Nuevo aumento');
    }

    final pct = (totalCurrent - totalPrev) / totalPrev;
    if (pct < 0) {
      return _TrendData.down(pct.abs());
    }
    if (pct > 0) {
      return _TrendData.up(pct);
    }
    return const _TrendData.neutral('Sin cambios');
  }

  _FrequencySeries _buildFrequencySeries({
    required List<SeizureModel> seizures,
    required int rangeDays,
    required DateTime now,
  }) {
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: rangeDays - 1));

    if (rangeDays == 7) {
      final points = List<int>.filled(7, 0);
      final labels = <String>[];
      for (int i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        labels.add('${day.day}/${day.month}');
      }
      for (final seizure in seizures) {
        final day = DateTime(
          seizure.dateTime.year,
          seizure.dateTime.month,
          seizure.dateTime.day,
        );
        final idx = day.difference(start).inDays;
        if (idx >= 0 && idx < points.length) {
          points[idx] += 1;
        }
      }
      return _FrequencySeries(points: points, labels: labels);
    }

    final bucketCount = (rangeDays / 7).ceil();
    final points = List<int>.filled(bucketCount, 0);
    final labels = <String>[];
    for (int i = 0; i < bucketCount; i++) {
      final bucketStart = start.add(Duration(days: i * 7));
      labels.add('${bucketStart.day}/${bucketStart.month}');
    }

    for (final seizure in seizures) {
      final day = DateTime(
        seizure.dateTime.year,
        seizure.dateTime.month,
        seizure.dateTime.day,
      );
      final diff = day.difference(start).inDays;
      if (diff < 0) {
        continue;
      }
      final idx = diff ~/ 7;
      if (idx >= 0 && idx < points.length) {
        points[idx] += 1;
      }
    }

    return _FrequencySeries(points: points, labels: labels);
  }

  String _avgIntensity(List<SeizureModel> seizures) {
    if (seizures.isEmpty) {
      return 'Sin dato';
    }
    final sum = seizures.fold<int>(0, (acc, s) => acc + s.intensity);
    final avg = sum / seizures.length;
    return avg.toStringAsFixed(1);
  }

  String _avgDuration(List<SeizureModel> seizures) {
    final values = seizures
        .map((s) => s.durationSeconds)
        .whereType<int>()
        .where((v) => v > 0)
        .toList(growable: false);
    if (values.isEmpty) {
      return 'Sin dato';
    }
    final avgSeconds = values.reduce((a, b) => a + b) / values.length;
    if (avgSeconds >= 60) {
      return '${(avgSeconds / 60).toStringAsFixed(1)} min';
    }
    return '${avgSeconds.toStringAsFixed(0)} seg';
  }

  String _avgRecovery(List<SeizureModel> seizures) {
    final values = seizures
        .map((s) => s.postictalRecoveryMinutes)
        .whereType<int>()
        .where((v) => v > 0)
        .toList(growable: false);
    if (values.isEmpty) {
      return 'Sin dato';
    }
    final avg = values.reduce((a, b) => a + b) / values.length;
    return '${avg.toStringAsFixed(1)} min';
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String seizureId) async {
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

  Future<void> _openExportReportSheet(
    BuildContext context,
    WidgetRef ref,
    PatientModel patient,
  ) {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();
    bool includeMedication = true;
    bool includeSeizures = true;
    bool includeNotes = false;
    bool isGenerating = false;

    Future<void> pickDate({
      required bool isStart,
      required void Function(void Function()) setModalState,
    }) async {
      final initialDate = isStart ? startDate : endDate;
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
      );
      if (picked == null) {
        return;
      }
      setModalState(() {
        if (isStart) {
          startDate = DateTime(picked.year, picked.month, picked.day);
          if (startDate.isAfter(endDate)) {
            endDate = startDate;
          }
        } else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          if (endDate.isBefore(startDate)) {
            startDate = DateTime(
              endDate.year,
              endDate.month,
              endDate.day,
            );
          }
        }
      });
    }

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      'Informe para el médico',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este informe está pensado para compartir con tu profesional sanitario.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _reportDateField(
                      context,
                      label: 'Desde',
                      value: _formatDateOnly(startDate),
                      onTap: () =>
                          pickDate(isStart: true, setModalState: setState),
                    ),
                    const SizedBox(height: 12),
                    _reportDateField(
                      context,
                      label: 'Hasta',
                      value: _formatDateOnly(endDate),
                      onTap: () =>
                          pickDate(isStart: false, setModalState: setState),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Incluir medicación'),
                      value: includeMedication,
                      onChanged: (value) =>
                          setState(() => includeMedication = value),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Incluir episodios'),
                      value: includeSeizures,
                      onChanged: (value) =>
                          setState(() => includeSeizures = value),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Incluir notas de episodios'),
                      value: includeNotes,
                      onChanged: includeSeizures
                          ? (value) => setState(() => includeNotes = value)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              if (!includeMedication && !includeSeizures) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selecciona al menos una sección para exportar.',
                                      ),
                                    ),
                                  );
                                return;
                              }
                              setState(() => isGenerating = true);
                              await ref
                                  .read(reportControllerProvider.notifier)
                                  .generateAndShareMedicalReport(
                                    patientId: patient.id,
                                    startDate: startDate,
                                    endDate: endDate,
                                    includeMedication: includeMedication,
                                    includeSeizures: includeSeizures,
                                    includeSeizureNotes: includeNotes,
                                  );
                              final reportState =
                                  ref.read(reportControllerProvider);
                              if (!context.mounted) {
                                return;
                              }
                              setState(() => isGenerating = false);
                              if (reportState.hasError) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(reportState.error.toString()),
                                    ),
                                  );
                                return;
                              }
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('PDF generado correctamente.'),
                                  ),
                                );
                            },
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Generar PDF'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    await ref.read(authControllerProvider.notifier).signOut();
    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('No se pudo cerrar sesión')));
      return;
    }

    // Limpieza explícita de estado por usuario.
    ref.invalidate(patientsByOwnerProvider);
    ref.invalidate(patientByIdProvider);
    ref.invalidate(patientHistoryProvider);
    ref.invalidate(seizuresByPatientProvider);
    ref.invalidate(seizuresAnalyticsByPatientProvider);
    ref.invalidate(seizuresByPatientMonthProvider);
    ref.invalidate(patientRangeDaysProvider);
    ref.invalidate(patientEpisodesPageProvider);
    ref.invalidate(reportControllerProvider);

    if (!context.mounted) {
      return;
    }
    context.go('/login');
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

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  Widget _reportDateField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(value),
                  ],
                ),
              ),
              const Icon(Icons.calendar_today_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeFilter extends StatelessWidget {
  const _RangeFilter({
    required this.selectedDays,
    required this.onChanged,
  });

  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftChipsWrap(
      children: <int>[7, 30, 90]
          .map(
            (days) => ChoiceChip(
              label: Text('$days días'),
              selected: selectedDays == days,
              onSelected: (_) => onChanged(days),
              selectedColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: Theme.of(context).textTheme.bodyMedium,
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MetricItem {
  const _MetricItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.metric});

  final _MetricItem metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              metric.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              metric.value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendData {
  const _TrendData.up(double pct)
      : direction = _TrendDirection.up,
        percent = pct,
        message = '';

  const _TrendData.down(double pct)
      : direction = _TrendDirection.down,
        percent = pct,
        message = '';

  const _TrendData.upNoPct(String msg)
      : direction = _TrendDirection.up,
        percent = null,
        message = msg;

  const _TrendData.neutral(String msg)
      : direction = _TrendDirection.neutral,
        percent = null,
        message = msg;

  final _TrendDirection direction;
  final String message;
  final double? percent;
}

enum _TrendDirection { up, down, neutral }

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({
    required this.trend,
    required this.rangeDays,
  });

  final _TrendData trend;
  final int rangeDays;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    Color color;
    String title;

    switch (trend.direction) {
      case _TrendDirection.up:
        icon = Icons.arrow_upward_rounded;
        color = colorScheme.error.withValues(alpha: 0.9);
        if (trend.percent != null) {
          title = '+${(trend.percent! * 100).toStringAsFixed(0)}%';
        } else {
          title = trend.message;
        }
      case _TrendDirection.down:
        icon = Icons.arrow_downward_rounded;
        color = colorScheme.tertiary.withValues(alpha: 0.9);
        title = '-${(trend.percent! * 100).toStringAsFixed(0)}%';
      case _TrendDirection.neutral:
        icon = Icons.remove_rounded;
        color = colorScheme.onSurfaceVariant;
        title = trend.message;
    }

    final subtitle = 'respecto a los $rangeDays días anteriores';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencySeries {
  const _FrequencySeries({required this.points, required this.labels});

  final List<int> points;
  final List<String> labels;
}

class _FrequencyChart extends StatelessWidget {
  const _FrequencyChart({required this.series});

  final _FrequencySeries series;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Frecuencia',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: series.points,
                  color: colorScheme.primary.withValues(alpha: 0.85),
                  subtle: colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  series.labels.isEmpty ? '' : series.labels.first,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  series.labels.isEmpty ? '' : series.labels.last,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.color,
    required this.subtle,
  });

  final List<int> values;
  final Color color;
  final Color subtle;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = subtle
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      basePaint,
    );

    if (values.isEmpty) {
      return;
    }

    final maxValue = math.max(1, values.reduce(math.max));
    final dx = values.length == 1 ? 0.0 : size.width / (values.length - 1);

    final path = Path();
    final pointPaint = Paint()..color = color;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < values.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] / maxValue) * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, pointPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
