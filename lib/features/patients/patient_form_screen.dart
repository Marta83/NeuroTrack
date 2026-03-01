import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/patient_clinical_catalog.dart';
import '../../models/patient_model.dart';
import '../../ui/soft_ui.dart';
import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen.newPatient({
    this.firstPatientRequired = false,
    super.key,
  }) : patientId = null;

  const PatientFormScreen.edit({
    required this.patientId,
    super.key,
  }) : firstPatientRequired = false;

  final String? patientId;
  final bool firstPatientRequired;

  bool get isEdit => patientId != null;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _referenceHospitalController = TextEditingController();
  final _epilepsyOnsetAgeMonthsController = TextEditingController();

  String _selectedSex = 'No especificado';
  String? _selectedSeizureFrequencyBaseline;
  final Set<String> _selectedGenes = <String>{};
  final Set<String> _selectedComorbidities = <String>{};
  final Set<String> _selectedTherapies = <String>{};
  final Set<String> _selectedDevices = <String>{};
  final List<_MedicationDraft> _medicationDrafts = <_MedicationDraft>[];

  bool _consentForResearch = false;
  bool _didHydrateForm = false;

  static const List<String> _geneOptions = <String>[
    'STXBP1',
    'SCN2A',
    'KCNQ2',
    'CDKL5',
    'PCDH19',
    'DEPDC5',
    'SYNGAP1',
    'SLC2A1',
  ];

  static const List<String> _sexOptions = <String>[
    'Femenino',
    'Masculino',
    'Intersexual',
    'No especificado',
  ];

  @override
  void dispose() {
    _aliasController.dispose();
    _birthYearController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _referenceHospitalController.dispose();
    _epilepsyOnsetAgeMonthsController.dispose();
    for (final draft in _medicationDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!widget.isEdit) {
      return _buildScaffold(context, userId: userId);
    }

    final patientAsync = ref.watch(
      patientByIdProvider((userId: userId, patientId: widget.patientId!)),
    );

    return patientAsync.when(
      data: (patient) {
        _hydrateFormIfNeeded(patient);
        return _buildScaffold(context, userId: userId, currentPatient: patient);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Editar paciente')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Editar paciente')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context, {
    required String userId,
    PatientModel? currentPatient,
  }) {
    final isLoading = ref.watch(patientControllerProvider).isLoading;

    return PopScope(
      canPop: widget.isEdit || !widget.firstPatientRequired,
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.isEdit || !widget.firstPatientRequired,
        title: Text(widget.isEdit ? 'Editar paciente' : 'Nuevo paciente'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SoftConstrainedBody(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: <Widget>[
                if (!widget.isEdit && widget.firstPatientRequired) ...<Widget>[
                  Text(
                    'Crea la ficha del paciente',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para empezar, necesitamos crear una ficha. Luego podrás registrar episodios y ver la evolución.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: gapSection),
                ],
                _buildBasicSection(context),
                const SizedBox(height: gapSection),
                _buildGeneticsSection(context),
                const SizedBox(height: gapSection),
                _buildHealthSection(context),
                const SizedBox(height: gapSection),
                _buildMedicationSection(context),
                const SizedBox(height: gapSection),
                _buildConsentSection(context),
                const SizedBox(height: gapSection),
                FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _savePatient(
                            userId: userId,
                            currentPatient: currentPatient,
                          ),
                  icon: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    widget.isEdit
                        ? 'Guardar cambios'
                        : widget.firstPatientRequired
                            ? 'Crear paciente'
                            : 'Guardar paciente',
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildBasicSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(
          icon: Icons.person_outline,
          title: 'Datos básicos',
          subtitle: 'Estos datos nos ayudan a organizar el seguimiento.',
        ),
        TextFormField(
          controller: _aliasController,
          decoration: softDecoration(
            context,
            label: 'Alias (opcional)',
            hint: 'Ej: Peque valiente',
          ),
          maxLength: 80,
        ),
        const SizedBox(height: gapField),
        TextFormField(
          controller: _birthYearController,
          decoration: softDecoration(context, label: 'Año de nacimiento'),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa el año de nacimiento.';
            }
            final year = int.tryParse(value.trim());
            final currentYear = DateTime.now().year;
            if (year == null || year < 1900 || year > currentYear) {
              return 'Año inválido.';
            }
            return null;
          },
        ),
        const SizedBox(height: gapField),
        DropdownButtonFormField<String>(
          initialValue: _selectedSex,
          decoration: softDecoration(context, label: 'Sexo'),
          items: _sexOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            if (value != null) {
              setState(() => _selectedSex = value);
            }
          },
        ),
        const SizedBox(height: gapField),
        TextFormField(
          controller: _countryController,
          decoration: softDecoration(context, label: 'País'),
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresa el país.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGeneticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(
          icon: Icons.science_outlined,
          title: 'Genética',
          subtitle: 'Si conoces el gen afectado, puedes indicarlo aquí.',
        ),
        SoftChipsWrap(
          children: _geneOptions
              .map(
                (gene) => softFilterChip(
                  context,
                  label: gene,
                  selected: _selectedGenes.contains(gene),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenes.add(gene);
                      } else {
                        _selectedGenes.remove(gene);
                      }
                    });
                  },
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(
          icon: Icons.favorite_outline,
          title: 'Salud y seguimiento',
        ),
        SoftExpansionSection(
          title: 'Información de salud (opcional)',
          subtitle: 'Completa solo lo que conozcas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _cityController,
                decoration: softDecoration(context, label: 'Ciudad (opcional)'),
              ),
              const SizedBox(height: gapField),
              TextFormField(
                controller: _referenceHospitalController,
                decoration: softDecoration(
                  context,
                  label: 'Hospital de referencia (opcional)',
                ),
              ),
              const SizedBox(height: gapField),
              TextFormField(
                controller: _epilepsyOnsetAgeMonthsController,
                decoration: softDecoration(
                  context,
                  label: 'Edad inicio de crisis (meses) (opcional)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (String? value) {
                  final raw = value?.trim() ?? '';
                  if (raw.isEmpty) {
                    return null;
                  }
                  final parsed = int.tryParse(raw);
                  if (parsed == null || parsed < 0 || parsed > 1200) {
                    return 'Ingresa un valor entre 0 y 1200 meses.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: gapField),
              DropdownButtonFormField<String?>(
                initialValue: _selectedSeizureFrequencyBaseline,
                decoration: softDecoration(
                  context,
                  label: 'Frecuencia basal de crisis (opcional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Seleccionar (opcional)'),
                  ),
                  ...PatientClinicalCatalog.seizureFrequencyBaselineOptions.map(
                    (option) => DropdownMenuItem<String?>(
                      value: option.code,
                      child: Text(option.labelEs),
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() => _selectedSeizureFrequencyBaseline = value);
                },
              ),
              const SizedBox(height: 20),
              _groupLabel(context, 'Otras dificultades asociadas'),
              const SizedBox(height: gapSmall),
              _buildExclusiveChipGroup(
                context,
                selected: _selectedComorbidities,
                options: PatientClinicalCatalog.comorbidityOptions,
                onToggle: (String code) {
                  setState(() {
                    _toggleExclusiveSelection(_selectedComorbidities, code);
                  });
                },
              ),
              const SizedBox(height: 20),
              _groupLabel(context, 'Terapias y apoyos'),
              const SizedBox(height: gapSmall),
              _buildExclusiveChipGroup(
                context,
                selected: _selectedTherapies,
                options: PatientClinicalCatalog.therapyOptions,
                onToggle: (String code) {
                  setState(() {
                    _toggleExclusiveSelection(_selectedTherapies, code);
                  });
                },
              ),
              const SizedBox(height: 20),
              _groupLabel(context, 'Dispositivos y soportes'),
              const SizedBox(height: gapSmall),
              _buildExclusiveChipGroup(
                context,
                selected: _selectedDevices,
                options: PatientClinicalCatalog.deviceOptions,
                onToggle: (String code) {
                  setState(() {
                    _toggleExclusiveSelection(_selectedDevices, code);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationSection(BuildContext context) {
    final count = _medicationDrafts.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(
          icon: Icons.medication_outlined,
          title: 'Medicación habitual',
        ),
        SoftExpansionSection(
          title: 'Medicación habitual (opcional)',
          subtitle: 'Medicaciones que toma actualmente, si las hay.',
          selectedCount: count,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () {
                  setState(() {
                    _medicationDrafts.add(_MedicationDraft());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Añadir medicación'),
              ),
              if (_medicationDrafts.isEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'No hay medicaciones añadidas.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              ..._medicationDrafts.asMap().entries.map((entry) {
                final index = entry.key;
                final draft = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'Medicación ${index + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar medicación',
                                onPressed: () {
                                  setState(() {
                                    draft.dispose();
                                    _medicationDrafts.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: draft.nameController,
                            decoration:
                                softDecoration(context, label: 'Nombre'),
                            validator: (String? value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'Indica el nombre de la medicación.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: gapField),
                          TextFormField(
                            controller: draft.doseController,
                            decoration: softDecoration(
                              context,
                              label: 'Dosis (opcional)',
                              hint: 'Ej: 5 mg',
                            ),
                          ),
                          const SizedBox(height: gapField),
                          TextFormField(
                            controller: draft.scheduleController,
                            decoration: softDecoration(
                              context,
                              label: 'Pauta (opcional)',
                              hint: 'Ej: 2 veces al día',
                            ),
                          ),
                          const SizedBox(height: gapField),
                          TextFormField(
                            controller: draft.notesController,
                            decoration: softDecoration(
                              context,
                              label: 'Notas (opcional)',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsentSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(
          icon: Icons.verified_user_outlined,
          title: 'Consentimiento',
        ),
        Text(
          '¿Autorizas el uso anónimo de estos datos para investigación?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Solo se usarán datos anonimizados.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: gapSmall),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Acepto el uso anónimo para investigación'),
          value: _consentForResearch,
          onChanged: (bool? value) {
            setState(() => _consentForResearch = value ?? false);
          },
        ),
      ],
    );
  }

  Widget _groupLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildExclusiveChipGroup(
    BuildContext context, {
    required Set<String> selected,
    required List<CatalogOption> options,
    required void Function(String code) onToggle,
  }) {
    return SoftChipsWrap(
      children: options
          .map(
            (option) => softFilterChip(
              context,
              label: option.labelEs,
              selected: selected.contains(option.code),
              onSelected: (_) => onToggle(option.code),
            ),
          )
          .toList(growable: false),
    );
  }

  void _toggleExclusiveSelection(Set<String> selected, String code) {
    const exclusiveCodes = <String>{'NONE', 'UNKNOWN'};

    if (selected.contains(code)) {
      selected.remove(code);
      return;
    }

    if (exclusiveCodes.contains(code)) {
      selected
        ..clear()
        ..add(code);
      return;
    }

    selected
      ..removeAll(exclusiveCodes)
      ..add(code);
  }

  Future<void> _savePatient({
    required String userId,
    required PatientModel? currentPatient,
  }) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_consentForResearch) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar el consentimiento para continuar.'),
          ),
        );
      return;
    }

    final onsetRaw = _epilepsyOnsetAgeMonthsController.text.trim();
    final int? onsetMonths = onsetRaw.isEmpty ? null : int.tryParse(onsetRaw);

    if (!widget.isEdit) {
      final patient = PatientModel.create(
        ownerUserId: userId,
        alias: _aliasController.text,
        birthYear: int.parse(_birthYearController.text.trim()),
        sex: _selectedSex,
        country: _countryController.text,
        geneSummary: _sortedCodes(_selectedGenes),
        city: _nullIfEmpty(_cityController.text),
        referenceHospital: _nullIfEmpty(_referenceHospitalController.text),
        epilepsyOnsetAgeMonths: onsetMonths,
        seizureFrequencyBaseline: _selectedSeizureFrequencyBaseline,
        comorbidities: _sortedCodes(_selectedComorbidities),
        therapies: _sortedCodes(_selectedTherapies),
        devices: _sortedCodes(_selectedDevices),
        currentMedications: _currentMedicationsPayload(),
        consentForResearch: _consentForResearch,
        consentAcceptedAt: DateTime.now(),
        consentVersion: 'v1.0',
      );
      await ref.read(patientControllerProvider.notifier).createPatient(patient);
      _handleCreateResult(patient.id);
      return;
    }

    if (currentPatient == null) {
      return;
    }

    final updated = currentPatient.copyWith(
      alias: _aliasController.text,
      birthYear: int.parse(_birthYearController.text.trim()),
      sex: _selectedSex,
      country: _countryController.text,
      geneSummary: _sortedCodes(_selectedGenes),
      city: _nullIfEmpty(_cityController.text),
      referenceHospital: _nullIfEmpty(_referenceHospitalController.text),
      epilepsyOnsetAgeMonths: onsetMonths,
      seizureFrequencyBaseline: _selectedSeizureFrequencyBaseline,
      comorbidities: _sortedCodes(_selectedComorbidities),
      therapies: _sortedCodes(_selectedTherapies),
      devices: _sortedCodes(_selectedDevices),
      currentMedications: _currentMedicationsPayload(),
      consentForResearch: _consentForResearch,
      consentAcceptedAt:
          (_consentForResearch && !currentPatient.consentForResearch)
              ? DateTime.now()
              : currentPatient.consentAcceptedAt,
      updatedAt: DateTime.now(),
    );

    final shouldContinue = await _confirmStableChangesIfNeeded(
      oldPatient: currentPatient,
      updatedPatient: updated,
    );
    if (!shouldContinue) {
      return;
    }

    await ref.read(patientControllerProvider.notifier).updatePatientWithHistory(
          oldPatient: currentPatient,
          updatedPatient: updated,
          changedBy: userId,
          reason: 'Actualización perfil',
        );
    _handleSaveResult(successMessage: 'Cambios guardados.');
  }

  Future<bool> _confirmStableChangesIfNeeded({
    required PatientModel oldPatient,
    required PatientModel updatedPatient,
  }) async {
    final stableChanged = oldPatient.birthYear != updatedPatient.birthYear ||
        oldPatient.sex != updatedPatient.sex ||
        _sortedCodes(oldPatient.geneSummary.toSet()).join('|') !=
            _sortedCodes(updatedPatient.geneSummary.toSet()).join('|');

    if (!stableChanged) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar cambio'),
          content: const Text(
            'Este dato normalmente no cambia. ¿Seguro que quieres modificarlo?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, continuar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _hydrateFormIfNeeded(PatientModel patient) {
    if (_didHydrateForm) {
      return;
    }
    _didHydrateForm = true;

    _aliasController.text = patient.alias;
    _birthYearController.text = '${patient.birthYear}';
    _countryController.text = patient.country;
    _cityController.text = patient.city ?? '';
    _referenceHospitalController.text = patient.referenceHospital ?? '';
    _epilepsyOnsetAgeMonthsController.text =
        patient.epilepsyOnsetAgeMonths?.toString() ?? '';
    _selectedSex = patient.sex;
    _selectedSeizureFrequencyBaseline = patient.seizureFrequencyBaseline;
    _selectedGenes
      ..clear()
      ..addAll(patient.geneSummary);
    _selectedComorbidities
      ..clear()
      ..addAll(patient.comorbidities);
    _selectedTherapies
      ..clear()
      ..addAll(patient.therapies);
    _selectedDevices
      ..clear()
      ..addAll(patient.devices);
    _consentForResearch = patient.consentForResearch;

    for (final draft in _medicationDrafts) {
      draft.dispose();
    }
    _medicationDrafts
      ..clear()
      ..addAll(
        patient.currentMedications.map(
          (item) => _MedicationDraft.fromMap(item),
        ),
      );
  }

  List<Map<String, dynamic>> _currentMedicationsPayload() {
    return _medicationDrafts
        .map(
          (draft) => <String, dynamic>{
            'name': draft.nameController.text.trim(),
            'dose': _nullIfEmpty(draft.doseController.text),
            'schedule': _nullIfEmpty(draft.scheduleController.text),
            'notes': _nullIfEmpty(draft.notesController.text),
          },
        )
        .toList(growable: false);
  }

  String? _nullIfEmpty(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  List<String> _sortedCodes(Set<String> values) {
    final list = values.toList(growable: false)..sort();
    return list;
  }

  void _handleSaveResult({required String successMessage}) {
    final state = ref.read(patientControllerProvider);

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
      ..showSnackBar(SnackBar(content: Text(successMessage)));
    Navigator.of(context).pop();
  }

  void _handleCreateResult(String patientId) {
    final state = ref.read(patientControllerProvider);

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
      ..showSnackBar(const SnackBar(content: Text('Paciente guardado.')));
    context.go('/patients/$patientId');
  }
}

class _MedicationDraft {
  _MedicationDraft()
      : nameController = TextEditingController(),
        doseController = TextEditingController(),
        scheduleController = TextEditingController(),
        notesController = TextEditingController();

  _MedicationDraft.fromMap(Map<String, dynamic> map)
      : nameController =
            TextEditingController(text: (map['name'] as String?) ?? ''),
        doseController =
            TextEditingController(text: (map['dose'] as String?) ?? ''),
        scheduleController =
            TextEditingController(text: (map['schedule'] as String?) ?? ''),
        notesController =
            TextEditingController(text: (map['notes'] as String?) ?? '');

  final TextEditingController nameController;
  final TextEditingController doseController;
  final TextEditingController scheduleController;
  final TextEditingController notesController;

  void dispose() {
    nameController.dispose();
    doseController.dispose();
    scheduleController.dispose();
    notesController.dispose();
  }
}
