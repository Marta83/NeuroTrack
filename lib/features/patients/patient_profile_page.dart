import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/medication_history_entry.dart';
import '../../models/patient_clinical_catalog.dart';
import '../../models/patient_model.dart';
import '../../ui/soft_ui.dart';
import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class PatientProfilePage extends ConsumerStatefulWidget {
  const PatientProfilePage({
    required this.patientId,
    super.key,
  });

  final String patientId;

  @override
  ConsumerState<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends ConsumerState<PatientProfilePage> {
  static const List<String> _reasonOptions = <String>[
    'Inicio',
    'Ajuste de dosis',
    'Cambio',
    'Retirada',
    'Efectos secundarios',
    'Otro',
  ];
  static const List<String> _doseUnitOptions = <String>[
    'mg',
    'ml',
    'gotas',
    'comprimidos',
  ];
  static const Map<String, String> _frequencyOptions = <String, String>{
    '1': '1 vez/día',
    '2': '2 veces/día',
    '3': '3 veces/día',
    '4': '4 veces/día',
    'PRN': 'PRN (solo si hace falta)',
  };
  static const List<String> _timingOptions = <String>[
    'Mañana',
    'Tarde',
    'Noche',
  ];
  static const List<String> _sexOptions = <String>[
    'Femenino',
    'Masculino',
    'Intersexual',
    'No especificado',
  ];
  static const List<String> _geneOptions = <String>[
    'STXBP1',
    'SCN2A',
    'KCNQ2',
    'CDKL5',
    'PCDH19',
    'DEPDC5',
    'SYNGAP1',
    'SLC2A1',
    'UNKNOWN',
  ];

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final patientAsync = ref.watch(
      patientByIdProvider((userId: userId, patientId: widget.patientId)),
    );

    return patientAsync.when(
      data: (patient) {
        if (kDebugMode) {
          final ownerMatches = patient.ownerUserId == userId;
          debugPrint(
            'Medication debug -> uid=$userId ownerUserId=${patient.ownerUserId} patientId=${patient.id} ownerMatches=$ownerMatches',
          );
          if (!ownerMatches) {
            debugPrint(
              'Medication debug warning: el usuario autenticado no coincide con ownerUserId del paciente.',
            );
          }
        }

        final medicationAsync = ref.watch(
          patientMedicationHistoryProvider(
              (userId: userId, patientId: patient.id)),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Perfil del paciente'),
          ),
          body: SafeArea(
            child: SoftConstrainedBody(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: <Widget>[
                  _softCard(
                    context,
                    title: 'Datos básicos',
                    action: _sectionEditButton(
                      context,
                      onPressed: () => _openBasicSectionEditor(patient),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _line(
                            context,
                            'Alias',
                            patient.alias.isEmpty
                                ? 'Sin alias'
                                : patient.alias),
                        _line(context, 'País / ciudad',
                            _joinCountryCity(patient)),
                        _line(context, 'Sexo', patient.sex),
                        _line(
                          context,
                          'Nacimiento / edad',
                          '${patient.birthYear} · ${DateTime.now().year - patient.birthYear} años aprox.',
                        ),
                        _line(context, 'Hospital',
                            patient.referenceHospital ?? 'Sin dato'),
                      ],
                    ),
                  ),
                  const SizedBox(height: gapSection),
                  _softCard(
                    context,
                    title: 'Genética',
                    action: _sectionEditButton(
                      context,
                      onPressed: () => _openGeneticsSectionEditor(patient),
                    ),
                    child: patient.geneSummary.isEmpty
                        ? const Text('Sin datos')
                        : SoftChipsWrap(
                            children: patient.geneSummary
                                .map((gene) => Chip(label: Text(gene)))
                                .toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: gapSection),
                  _softCard(
                    context,
                    title: 'Medicación',
                    action: FilledButton.tonalIcon(
                      onPressed: () =>
                          _openMedicationEntryForm(patient.id, userId),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir cambio de medicación'),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Medicación actual',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        medicationAsync.when(
                          data: (entries) {
                            final activeEntries = entries
                                .where((entry) => entry.endedAt == null)
                                .toList(growable: false);
                            if (activeEntries.isEmpty) {
                              return Text(
                                'Sin medicación registrada',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              );
                            }
                            return Column(
                              children: activeEntries
                                  .map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _MedicationTimelineItem(
                                        entry: entry,
                                        onEdit: () => _openMedicationEntryForm(
                                          patient.id,
                                          userId,
                                          entry: entry,
                                        ),
                                        onFinalize: () => _finalizeMedication(
                                          patient.id,
                                          userId,
                                          entry,
                                        ),
                                        onDelete: () => _deleteMedication(
                                          patient.id,
                                          userId,
                                          entry,
                                        ),
                                        onShowNotes: entry.notes == null ||
                                                entry.notes!.trim().isEmpty
                                            ? null
                                            : () => _showNotes(entry.notes!),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) {
                            if (kDebugMode) {
                              debugPrint(
                                'Medication history load error (active): $error',
                              );
                              if (error is FirebaseException) {
                                debugPrint(
                                  'code=${error.code} message=${error.message}',
                                );
                              }
                              debugPrintStack(stackTrace: stack);
                            }
                            return Text(
                              'No hemos podido cargar la medicación. Revisa tu conexión o inténtalo de nuevo.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Historial de medicación',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        medicationAsync.when(
                          data: (entries) {
                            if (entries.isEmpty) {
                              return Text(
                                'Cuando hagas cambios de medicación, aparecerán aquí.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              );
                            }
                            return Column(
                              children: entries
                                  .map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _MedicationTimelineItem(
                                        entry: entry,
                                        onEdit: () => _openMedicationEntryForm(
                                          patient.id,
                                          userId,
                                          entry: entry,
                                        ),
                                        onFinalize: () => _finalizeMedication(
                                          patient.id,
                                          userId,
                                          entry,
                                        ),
                                        onDelete: () => _deleteMedication(
                                          patient.id,
                                          userId,
                                          entry,
                                        ),
                                        onShowNotes: entry.notes == null ||
                                                entry.notes!.trim().isEmpty
                                            ? null
                                            : () => _showNotes(entry.notes!),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) {
                            if (kDebugMode) {
                              debugPrint(
                                'Medication history load error (history): $error',
                              );
                              if (error is FirebaseException) {
                                debugPrint(
                                  'code=${error.code} message=${error.message}',
                                );
                              }
                              debugPrintStack(stackTrace: stack);
                            }
                            return Text(
                              'No hemos podido cargar la medicación. Revisa tu conexión o inténtalo de nuevo.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: gapSection),
                  _softCard(
                    context,
                    title: 'Terapias',
                    action: _sectionEditButton(
                      context,
                      onPressed: () => _openTherapiesSectionEditor(patient),
                    ),
                    child: Text(_labelsFromCodes(
                      patient.therapies,
                      PatientClinicalCatalog.therapyOptions,
                    )),
                  ),
                  const SizedBox(height: gapSection),
                  _softCard(
                    context,
                    title: 'Dispositivos y soportes',
                    action: _sectionEditButton(
                      context,
                      onPressed: () => _openDevicesSectionEditor(patient),
                    ),
                    child: Text(_labelsFromCodes(
                      patient.devices,
                      PatientClinicalCatalog.deviceOptions,
                    )),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _sectionEditButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Editar'),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _softCard(
    BuildContext context, {
    required String title,
    required Widget child,
    Widget? action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
          children: <TextSpan>[
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value.isEmpty ? 'Sin dato' : value),
          ],
        ),
      ),
    );
  }

  String _joinCountryCity(PatientModel patient) {
    final parts = <String>[
      if (patient.country.trim().isNotEmpty) patient.country,
      if ((patient.city ?? '').trim().isNotEmpty) patient.city!,
    ];
    return parts.isEmpty ? 'Sin dato' : parts.join(' · ');
  }

  String _labelsFromCodes(List<String> codes, List<CatalogOption> options) {
    if (codes.isEmpty) {
      return 'Sin dato';
    }
    final labels = codes.map((code) {
      for (final option in options) {
        if (option.code == code) {
          return option.labelEs;
        }
      }
      return code;
    }).toList(growable: false);
    return labels.join(', ');
  }

  String _dateText(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _openBasicSectionEditor(PatientModel patient) async {
    final aliasController = TextEditingController(text: patient.alias);
    final countryController = TextEditingController(text: patient.country);
    final cityController = TextEditingController(text: patient.city ?? '');
    final hospitalController =
        TextEditingController(text: patient.referenceHospital ?? '');
    final birthYearController =
        TextEditingController(text: '${patient.birthYear}');
    String selectedSex = patient.sex;

    final formKey = GlobalKey<FormState>();

    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Text(
                        'Editar datos básicos',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Puedes cambiar solo lo que haya cambiado. Lo demás puede quedar igual.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: aliasController,
                        decoration:
                            _medicationFieldDecoration(context, label: 'Alias'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: countryController,
                        decoration:
                            _medicationFieldDecoration(context, label: 'País'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Indica el país.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cityController,
                        decoration: _medicationFieldDecoration(context,
                            label: 'Ciudad'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _sexOptions.contains(selectedSex)
                            ? selectedSex
                            : _sexOptions.last,
                        decoration:
                            _medicationFieldDecoration(context, label: 'Sexo'),
                        items: _sexOptions
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() => selectedSex = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: birthYearController,
                        decoration: _medicationFieldDecoration(
                          context,
                          label: 'Año de nacimiento',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse((value ?? '').trim());
                          final currentYear = DateTime.now().year;
                          if (parsed == null ||
                              parsed < 1900 ||
                              parsed > currentYear) {
                            return 'Año inválido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hospitalController,
                        decoration: _medicationFieldDecoration(
                          context,
                          label: 'Hospital de referencia',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                final updatedPatient = patient.copyWith(
                                  alias: aliasController.text.trim(),
                                  country: countryController.text.trim(),
                                  city: cityController.text.trim().isEmpty
                                      ? null
                                      : cityController.text.trim(),
                                  sex: selectedSex,
                                  birthYear: int.parse(
                                      birthYearController.text.trim()),
                                  referenceHospital:
                                      hospitalController.text.trim().isEmpty
                                          ? null
                                          : hospitalController.text.trim(),
                                );
                                final success = await _saveSectionPatientUpdate(
                                    updatedPatient);
                                if (!context.mounted) {
                                  return;
                                }
                                if (success) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                              child: const Text('Guardar cambios'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    aliasController.dispose();
    countryController.dispose();
    cityController.dispose();
    hospitalController.dispose();
    birthYearController.dispose();

    if (didSave == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Datos básicos actualizados.')));
    }
  }

  Future<void> _openGeneticsSectionEditor(PatientModel patient) async {
    final selected = <String>{...patient.geneSummary};
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      'Editar genética',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puedes cambiar solo lo que haya cambiado. Lo demás puede quedar igual.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    SoftChipsWrap(
                      children: _geneOptions
                          .map(
                            (gene) => FilterChip(
                              label:
                                  Text(gene == 'UNKNOWN' ? 'No se sabe' : gene),
                              selected: selected.contains(gene),
                              onSelected: (isSelected) {
                                setModalState(() {
                                  if (gene == 'UNKNOWN') {
                                    if (isSelected) {
                                      selected
                                        ..clear()
                                        ..add('UNKNOWN');
                                    } else {
                                      selected.remove('UNKNOWN');
                                    }
                                    return;
                                  }
                                  if (isSelected) {
                                    selected
                                      ..remove('UNKNOWN')
                                      ..add(gene);
                                  } else {
                                    selected.remove(gene);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final updatedPatient = patient.copyWith(
                                geneSummary: selected.toList(growable: false),
                              );
                              final success = await _saveSectionPatientUpdate(
                                  updatedPatient);
                              if (!context.mounted) {
                                return;
                              }
                              if (success) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            child: const Text('Guardar cambios'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (didSave == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Genética actualizada.')));
    }
  }

  Future<void> _openTherapiesSectionEditor(PatientModel patient) async {
    final didSave = await _openCatalogSectionEditor(
      title: 'Editar terapias',
      patient: patient,
      initialSelected: patient.therapies,
      options: PatientClinicalCatalog.therapyOptions,
      onBuildPatient: (updated) => patient.copyWith(therapies: updated),
    );
    if (didSave == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Terapias actualizadas.')));
    }
  }

  Future<void> _openDevicesSectionEditor(PatientModel patient) async {
    final didSave = await _openCatalogSectionEditor(
      title: 'Editar dispositivos y apoyos',
      patient: patient,
      initialSelected: patient.devices,
      options: PatientClinicalCatalog.deviceOptions,
      onBuildPatient: (updated) => patient.copyWith(devices: updated),
    );
    if (didSave == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Dispositivos y apoyos actualizados.')));
    }
  }

  Future<bool?> _openCatalogSectionEditor({
    required String title,
    required PatientModel patient,
    required List<String> initialSelected,
    required List<CatalogOption> options,
    required PatientModel Function(List<String> selected) onBuildPatient,
  }) {
    final selected = <String>{...initialSelected};
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puedes cambiar solo lo que haya cambiado. Lo demás puede quedar igual.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    SoftChipsWrap(
                      children: options
                          .map(
                            (option) => FilterChip(
                              label: Text(option.labelEs),
                              selected: selected.contains(option.code),
                              onSelected: (isSelected) {
                                setModalState(() {
                                  _toggleExclusiveSelection(
                                    selected: selected,
                                    code: option.code,
                                    isSelected: isSelected,
                                  );
                                });
                              },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final updatedPatient = onBuildPatient(
                                selected.toList(growable: false),
                              );
                              final success = await _saveSectionPatientUpdate(
                                  updatedPatient);
                              if (!context.mounted) {
                                return;
                              }
                              if (success) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            child: const Text('Guardar cambios'),
                          ),
                        ),
                      ],
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

  void _toggleExclusiveSelection({
    required Set<String> selected,
    required String code,
    required bool isSelected,
  }) {
    const exclusive = <String>{'NONE', 'UNKNOWN'};
    if (exclusive.contains(code)) {
      if (isSelected) {
        selected
          ..clear()
          ..add(code);
      } else {
        selected.remove(code);
      }
      return;
    }

    if (isSelected) {
      selected
        ..remove('NONE')
        ..remove('UNKNOWN')
        ..add(code);
    } else {
      selected.remove(code);
    }
  }

  Future<bool> _saveSectionPatientUpdate(PatientModel updatedPatient) async {
    await ref
        .read(patientControllerProvider.notifier)
        .updatePatient(updatedPatient);
    final state = ref.read(patientControllerProvider);
    if (state.hasError) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(state.error.toString())),
        );
      return false;
    }
    return true;
  }

  Future<void> _openMedicationEntryForm(
    String patientId,
    String userId, {
    MedicationHistoryEntry? entry,
  }) async {
    final isEditing = entry != null;
    final nameController = TextEditingController(text: entry?.name ?? '');
    final amountController = TextEditingController(
      text: _formatDoseAmount(entry?.doseAmount),
    );
    final notesController = TextEditingController(text: entry?.notes ?? '');

    DateTime startedAt = entry?.startedAt ?? DateTime.now();
    DateTime? endedAt = entry?.endedAt;
    String? doseUnit = entry?.doseUnit;
    String? frequencySelection;
    if (entry?.isPrn ?? false) {
      frequencySelection = 'PRN';
    } else if (entry?.frequencyPerDay != null) {
      frequencySelection = '${entry!.frequencyPerDay}';
    }
    final selectedTiming = <String>{...?entry?.timing};
    String? reason = entry?.reason;
    if (reason != null && !_reasonOptions.contains(reason)) {
      reason = null;
    }

    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context,
              void Function(void Function()) setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Form(
                  key: formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      Text(
                        isEditing
                            ? 'Editar cambio de medicación'
                            : 'Añadir cambio de medicación',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Básico',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: nameController,
                        decoration: _medicationFieldDecoration(
                          context,
                          label: 'Medicación',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Indica la medicación.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 640;
                          final amountField = TextFormField(
                            controller: amountController,
                            decoration: _medicationFieldDecoration(
                              context,
                              label: '¿Cuánto toma cada vez?',
                              hint: 'Ej. 250',
                              helper:
                                  'Si no lo sabes, puedes dejarlo en blanco.',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          );
                          final unitField = DropdownButtonFormField<String?>(
                            initialValue: doseUnit,
                            decoration: _medicationFieldDecoration(
                              context,
                              label: 'Unidad',
                              hint: 'mg / ml / gotas',
                            ),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('-'),
                              ),
                              ..._doseUnitOptions.map(
                                (unit) => DropdownMenuItem<String?>(
                                  value: unit,
                                  child: Text(unit),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setModalState(() => doseUnit = value),
                          );
                          final frequencyField =
                              DropdownButtonFormField<String?>(
                            initialValue: frequencySelection,
                            decoration: _medicationFieldDecoration(
                              context,
                              label: 'Frecuencia',
                              hint: '2 veces/día o PRN',
                            ),
                            items: <DropdownMenuItem<String?>>[
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('-'),
                              ),
                              ..._frequencyOptions.entries.map(
                                (entry) => DropdownMenuItem<String?>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              ),
                            ],
                            onChanged: (value) =>
                                setModalState(() => frequencySelection = value),
                          );

                          if (!isWide) {
                            return Column(
                              children: <Widget>[
                                amountField,
                                const SizedBox(height: 12),
                                unitField,
                                const SizedBox(height: 12),
                                frequencyField,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: amountField),
                              const SizedBox(width: 10),
                              SizedBox(width: 110, child: unitField),
                              const SizedBox(width: 10),
                              SizedBox(width: 150, child: frequencyField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _dateSelectionField(
                        context,
                        label: '¿Desde cuándo la toma?',
                        value: _dateText(startedAt),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startedAt,
                            firstDate: DateTime(2000),
                            lastDate:
                                DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setModalState(() => startedAt = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            14,
                          ),
                          collapsedShape: const RoundedRectangleBorder(
                            side: BorderSide.none,
                          ),
                          shape: const RoundedRectangleBorder(
                            side: BorderSide.none,
                          ),
                          title: Text(
                            'Detalles (opcional)',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Momento del día',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SoftChipsWrap(
                              children: _timingOptions
                                  .map(
                                    (timing) => FilterChip(
                                      label: Text(timing),
                                      selected: selectedTiming.contains(timing),
                                      onSelected: (selected) {
                                        setModalState(() {
                                          if (selected) {
                                            selectedTiming.add(timing);
                                          } else {
                                            selectedTiming.remove(timing);
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 12),
                            _dateSelectionField(
                              context,
                              label: '¿Hasta cuándo la tomó?',
                              value: endedAt == null
                                  ? 'Sin fecha'
                                  : _dateText(endedAt!),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endedAt ?? startedAt,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now()
                                      .add(const Duration(days: 3650)),
                                );
                                if (picked != null) {
                                  setModalState(() => endedAt = picked);
                                }
                              },
                              onClear: endedAt == null
                                  ? null
                                  : () => setModalState(() => endedAt = null),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: reason,
                              decoration: _medicationFieldDecoration(
                                context,
                                label: 'Motivo',
                              ),
                              items: <DropdownMenuItem<String?>>[
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Sin motivo'),
                                ),
                                ..._reasonOptions.map(
                                  (option) => DropdownMenuItem<String?>(
                                    value: option,
                                    child: Text(option),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setModalState(() => reason = value),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: notesController,
                              decoration: _medicationFieldDecoration(
                                context,
                                label: 'Notas (si quieres)',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          if (endedAt != null && endedAt!.isBefore(startedAt)) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'La fecha fin no puede ser anterior al inicio.'),
                                ),
                              );
                            return;
                          }

                          final amountText = amountController.text.trim();
                          final parsedAmount = amountText.isEmpty
                              ? null
                              : double.tryParse(
                                  amountText.replaceAll(',', '.'));
                          if (amountText.isNotEmpty && parsedAmount == null) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La cantidad por toma debe ser numérica.',
                                  ),
                                ),
                              );
                            return;
                          }

                          Object? frequencyValue;
                          if (frequencySelection == 'PRN') {
                            frequencyValue = 'PRN';
                          } else if (frequencySelection != null) {
                            frequencyValue = int.tryParse(frequencySelection!);
                          }

                          final built = MedicationHistoryEntry(
                            id: entry?.id ?? '',
                            name: nameController.text.trim(),
                            startedAt: startedAt,
                            endedAt: endedAt,
                            doseAmount: parsedAmount,
                            doseUnit: doseUnit,
                            frequency: frequencyValue,
                            timing: selectedTiming.toList(growable: false),
                            reason: reason,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            createdAt: entry?.createdAt ?? DateTime.now(),
                            createdBy: entry?.createdBy ?? userId,
                          );

                          if (isEditing) {
                            await ref
                                .read(patientMedicationControllerProvider
                                    .notifier)
                                .updateMedicationHistoryEntry(
                                  userId: userId,
                                  patientId: patientId,
                                  entry: built,
                                );
                          } else {
                            await ref
                                .read(patientMedicationControllerProvider
                                    .notifier)
                                .addMedicationHistoryEntry(
                                  userId: userId,
                                  patientId: patientId,
                                  entry: built,
                                );
                          }

                          final state =
                              ref.read(patientMedicationControllerProvider);
                          if (state.hasError) {
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text(state.error.toString())),
                              );
                            return;
                          }

                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                        child: Text(isEditing ? 'Guardar cambios' : 'Guardar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
    notesController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Cambio de medicación actualizado.'
                  : 'Cambio de medicación añadido.',
            ),
          ),
        );
    }
  }

  Future<void> _finalizeMedication(
    String patientId,
    String userId,
    MedicationHistoryEntry entry,
  ) async {
    await ref
        .read(patientMedicationControllerProvider.notifier)
        .finalizeMedicationHistoryEntry(
          userId: userId,
          patientId: patientId,
          entryId: entry.id,
          endedAt: DateTime.now(),
        );
    final state = ref.read(patientMedicationControllerProvider);
    if (!mounted) {
      return;
    }
    if (state.hasError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error.toString())));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Medicación finalizada.')));
  }

  Future<void> _deleteMedication(
    String patientId,
    String userId,
    MedicationHistoryEntry entry,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrada'),
        content: const Text('¿Seguro que quieres eliminar esta entrada?'),
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
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await ref
        .read(patientMedicationControllerProvider.notifier)
        .deleteMedicationHistoryEntry(
          userId: userId,
          patientId: patientId,
          entryId: entry.id,
        );
    final state = ref.read(patientMedicationControllerProvider);
    if (!mounted) {
      return;
    }
    if (state.hasError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error.toString())));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Entrada eliminada.')));
  }

  Future<void> _showNotes(String notes) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notas'),
          content: Text(notes),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _medicationFieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    String? helper,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      helperStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      hintStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
      ),
    );
  }

  Widget _dateSelectionField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Quitar fecha',
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.calendar_today_outlined, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDoseAmount(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }
}

String formatMedicationLine(MedicationHistoryEntry entry) {
  final parts = <String>[entry.name];

  final doseParts = <String>[];
  if (entry.doseAmount != null) {
    final amount = entry.doseAmount!;
    doseParts.add(
      amount == amount.roundToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toString(),
    );
  }
  if (entry.doseUnit != null && entry.doseUnit!.trim().isNotEmpty) {
    doseParts.add(entry.doseUnit!.trim());
  }
  if (doseParts.isNotEmpty) {
    parts.add(doseParts.join(' '));
  }

  final perDay = entry.frequencyPerDay;
  if (perDay != null) {
    final suffix = perDay == 1 ? 'vez/día' : 'veces/día';
    parts.add('$perDay $suffix');
  } else if (entry.isPrn) {
    parts.add('PRN');
  }

  if (entry.timing.isNotEmpty) {
    parts.add(entry.timing.join(', '));
  }

  return parts.join(' · ');
}

class _MedicationTimelineItem extends StatelessWidget {
  const _MedicationTimelineItem({
    required this.entry,
    required this.onEdit,
    required this.onFinalize,
    required this.onDelete,
    this.onShowNotes,
  });

  final MedicationHistoryEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onFinalize;
  final VoidCallback onDelete;
  final VoidCallback? onShowNotes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateText = _date(entry.startedAt);
    final untilText =
        entry.endedAt == null ? '' : ' · Hasta ${_date(entry.endedAt!)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    formatMedicationLine(entry),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Desde $dateText$untilText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (entry.reason != null &&
                      entry.reason!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(entry.reason!),
                    ),
                  ],
                  if (onShowNotes != null)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: onShowNotes,
                      child: const Text('Ver notas'),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'finalize') {
                  onFinalize();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                    value: 'edit', child: Text('Editar')),
                const PopupMenuItem<String>(
                  value: 'finalize',
                  child: Text('Finalizar'),
                ),
                const PopupMenuItem<String>(
                    value: 'delete', child: Text('Borrar')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}
