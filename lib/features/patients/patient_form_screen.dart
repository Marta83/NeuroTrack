import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_clinical_catalog.dart';
import '../../models/patient_model.dart';
import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  static const double _maxFormWidth = 760;
  static const double _sectionGap = 22;
  static const double _fieldGap = 12;
  static const EdgeInsets _cardPadding = EdgeInsets.all(16);

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
  bool _healthSectionExpanded = false;
  bool _medicationSectionExpanded = false;

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
    final isLoading = ref.watch(patientControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo paciente')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxFormWidth),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _buildBasicSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildGeneticsSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildHealthSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildMedicationSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildConsentSection(context),
                  const SizedBox(height: _sectionGap),
                  FilledButton.icon(
                    onPressed: isLoading ? null : _savePatient,
                    icon: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar paciente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _sectionCard(
      context,
      title: 'Datos básicos',
      icon: Icons.person_outline,
      subtitle: 'Estos datos nos ayudan a personalizar el seguimiento.',
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _aliasController,
            decoration: _inputDecoration(
              context,
              labelText: 'Alias (opcional)',
              hintText: 'Ej: Peque valiente',
            ),
            maxLength: 80,
          ),
          const SizedBox(height: _fieldGap),
          TextFormField(
            controller: _birthYearController,
            decoration: _inputDecoration(
              context,
              labelText: 'Año de nacimiento',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
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
          const SizedBox(height: _fieldGap),
          DropdownButtonFormField<String>(
            initialValue: _selectedSex,
            decoration: _inputDecoration(context, labelText: 'Sexo'),
            items: _sexOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(growable: false),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedSex = value);
            },
          ),
          const SizedBox(height: _fieldGap),
          TextFormField(
            controller: _countryController,
            decoration: _inputDecoration(context, labelText: 'País'),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el país.';
              }
              return null;
            },
          ),
          if (!_consentForResearch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Recuerda aceptar el consentimiento antes de guardar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneticsSection(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Genética',
      icon: Icons.science_outlined,
      subtitle: 'Si conoces el gen afectado, puedes indicarlo aquí.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _geneOptions
            .map(
              (gene) => FilterChip(
                label: Text(gene),
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
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Salud y seguimiento',
      icon: Icons.favorite_outline,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          initiallyExpanded: _healthSectionExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() => _healthSectionExpanded = expanded);
          },
          title: const Text('Información de salud (opcional)'),
          subtitle: const Text('Puedes completar solo lo que conozcas.'),
          childrenPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          children: <Widget>[
            TextFormField(
              controller: _cityController,
              decoration: _inputDecoration(context, labelText: 'Ciudad (opcional)'),
            ),
            const SizedBox(height: _fieldGap),
            TextFormField(
              controller: _referenceHospitalController,
              decoration: _inputDecoration(
                context,
                labelText: 'Hospital de referencia (opcional)',
              ),
            ),
            const SizedBox(height: _fieldGap),
            TextFormField(
              controller: _epilepsyOnsetAgeMonthsController,
              decoration: _inputDecoration(
                context,
                labelText:
                    '¿A qué edad empezaron las crisis? (meses) (opcional)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
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
            const SizedBox(height: _fieldGap),
            DropdownButtonFormField<String?>(
              initialValue: _selectedSeizureFrequencyBaseline,
              decoration: _inputDecoration(
                context,
                labelText:
                    '¿Con qué frecuencia suele tener crisis? (aproximadamente)',
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
            const SizedBox(height: 16),
            _subTitle(context, 'Otras dificultades asociadas'),
            const SizedBox(height: 8),
            _buildExclusiveChipGroup(
              selected: _selectedComorbidities,
              options: PatientClinicalCatalog.comorbidityOptions,
              onToggle: (String code) {
                setState(() {
                  _toggleExclusiveSelection(_selectedComorbidities, code);
                });
              },
            ),
            const SizedBox(height: 16),
            _subTitle(context, 'Terapias y apoyos'),
            const SizedBox(height: 8),
            _buildExclusiveChipGroup(
              selected: _selectedTherapies,
              options: PatientClinicalCatalog.therapyOptions,
              onToggle: (String code) {
                setState(() {
                  _toggleExclusiveSelection(_selectedTherapies, code);
                });
              },
            ),
            const SizedBox(height: 16),
            _subTitle(context, 'Dispositivos y soportes'),
            const SizedBox(height: 8),
            _buildExclusiveChipGroup(
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
    );
  }

  Widget _buildMedicationSection(BuildContext context) {
    final int count = _medicationDrafts.length;

    return _sectionCard(
      context,
      title: 'Medicación habitual',
      icon: Icons.medication_outlined,
      subtitle: 'Medicaciones que toma actualmente (si las hay).',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          initiallyExpanded: _medicationSectionExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() => _medicationSectionExpanded = expanded);
          },
          title: Text(
            count == 0
                ? 'Medicaciones actuales'
                : 'Medicaciones actuales ($count añadidas)',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _medicationDrafts.add(_MedicationDraft());
                    _medicationSectionExpanded = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('➕ Añadir medicación'),
              ),
            ),
            if (_medicationDrafts.isEmpty)
              Text(
                'No hay medicaciones añadidas.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ..._medicationDrafts.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final draft = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildMedicationCard(context, draft, index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    _MedicationDraft draft,
    int index,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
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
                    style: Theme.of(context).textTheme.titleSmall,
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
            const SizedBox(height: 6),
            TextFormField(
              controller: draft.nameController,
              decoration: _inputDecoration(
                context,
                labelText: 'Nombre',
              ),
              validator: (String? value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return 'Indica el nombre de la medicación.';
                }
                return null;
              },
            ),
            const SizedBox(height: _fieldGap),
            TextFormField(
              controller: draft.doseController,
              decoration: _inputDecoration(
                context,
                labelText: 'Dosis (opcional)',
                hintText: 'Ej: 5 mg',
              ),
            ),
            const SizedBox(height: _fieldGap),
            TextFormField(
              controller: draft.scheduleController,
              decoration: _inputDecoration(
                context,
                labelText: 'Pauta (opcional)',
                hintText: 'Ej: 2 veces al día',
              ),
            ),
            const SizedBox(height: _fieldGap),
            TextFormField(
              controller: draft.notesController,
              decoration: _inputDecoration(
                context,
                labelText: 'Notas (opcional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _sectionCard(
      context,
      title: 'Consentimiento',
      icon: Icons.verified_user_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Acepto el uso anónimo para investigación'),
            value: _consentForResearch,
            onChanged: (bool? value) {
              setState(() => _consentForResearch = value ?? false);
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 19, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: _fieldGap),
            child,
          ],
        ),
      ),
    );
  }

  Widget _subTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildExclusiveChipGroup({
    required Set<String> selected,
    required List<CatalogOption> options,
    required void Function(String code) onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => FilterChip(
              label: Text(option.labelEs),
              selected: selected.contains(option.code),
              onSelected: (_) => onToggle(option.code),
            ),
          )
          .toList(growable: false),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
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

  Future<void> _savePatient() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_consentForResearch) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar el consentimiento para continuar.'),
          ),
        );
      return;
    }

    final userId = ref.read(authRepositoryProvider).currentUser?.uid;
    if (userId == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Sesion no valida.')));
      return;
    }

    final onsetRaw = _epilepsyOnsetAgeMonthsController.text.trim();
    final int? onsetMonths = onsetRaw.isEmpty ? null : int.tryParse(onsetRaw);

    final patient = PatientModel.create(
      ownerUserId: userId,
      alias: _aliasController.text,
      birthYear: int.parse(_birthYearController.text.trim()),
      sex: _selectedSex,
      country: _countryController.text,
      geneSummary: _selectedGenes.toList(growable: false),
      city: _nullIfEmpty(_cityController.text),
      referenceHospital: _nullIfEmpty(_referenceHospitalController.text),
      epilepsyOnsetAgeMonths: onsetMonths,
      seizureFrequencyBaseline: _selectedSeizureFrequencyBaseline,
      comorbidities: _selectedComorbidities.toList(growable: false),
      therapies: _selectedTherapies.toList(growable: false),
      devices: _selectedDevices.toList(growable: false),
      currentMedications: _currentMedicationsPayload(),
      consentForResearch: _consentForResearch,
      consentAcceptedAt: DateTime.now(),
      consentVersion: 'v1.0',
    );

    await ref.read(patientControllerProvider.notifier).createPatient(patient);
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

    Navigator.of(context).pop();
  }
}

class _MedicationDraft {
  _MedicationDraft()
      : nameController = TextEditingController(),
        doseController = TextEditingController(),
        scheduleController = TextEditingController(),
        notesController = TextEditingController();

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
