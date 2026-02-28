import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_history_entry.dart';
import '../../ui/soft_ui.dart';
import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class PatientHistoryScreen extends ConsumerWidget {
  const PatientHistoryScreen({
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

    final historyAsync = ref.watch(
      patientHistoryProvider((userId: userId, patientId: patientId)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Evolución')),
      body: SafeArea(
        child: SoftConstrainedBody(
          child: historyAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                      'Aún no hay cambios registrados para este paciente.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final entry = entries[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    title: Text(_summaryForChanges(entry.changes)),
                    subtitle: Text(_formatDateTime(entry.changedAt)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangeDetail(context, entry),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(child: Text('Error: $error')),
          ),
        ),
      ),
    );
  }

  String _summaryForChanges(Map<String, dynamic> changes) {
    if (changes.isEmpty) {
      return 'Perfil actualizado';
    }

    final keys = changes.keys.toSet();
    if (keys.contains('currentMedications')) {
      return 'Medicación actualizada';
    }
    if (keys.contains('referenceHospital')) {
      return 'Nuevo hospital de referencia';
    }
    if (keys.contains('therapies')) {
      return 'Terapias actualizadas';
    }
    if (keys.contains('devices')) {
      return 'Dispositivos actualizados';
    }
    if (keys.contains('city')) {
      return 'Ciudad de seguimiento actualizada';
    }
    if (keys.contains('seizureFrequencyBaseline')) {
      return 'Frecuencia basal actualizada';
    }
    return 'Perfil actualizado (${changes.length} cambios)';
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showChangeDetail(
    BuildContext context,
    PatientHistoryEntry entry,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Detalle de cambio',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(entry.changedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      ...entry.changes.entries.map((change) {
                        final value = change.value as Map<String, dynamic>?;
                        final from = value?['from'];
                        final to = value?['to'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    change.key,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Antes: ${_prettyValue(from)}'),
                                  const SizedBox(height: 4),
                                  Text('Ahora: ${_prettyValue(to)}'),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      Text(
                        'Estado completo en esa fecha',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(_prettyValue(entry.snapshot)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _prettyValue(dynamic value) {
    if (value == null) {
      return 'Sin dato';
    }
    if (value is List<dynamic>) {
      if (value.isEmpty) {
        return '[]';
      }
      return value.join(', ');
    }
    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return '{}';
      }
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(' | ');
    }
    return '$value';
  }
}
