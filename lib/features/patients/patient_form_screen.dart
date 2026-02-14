import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/patient_model.dart';
import '../auth/auth_provider.dart';
import 'patient_provider.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedSex = 'No especificado';
  final Set<String> _selectedGenes = <String>{};
  bool _consentForResearch = false;

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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(
                  labelText: 'Alias (opcional)',
                  hintText: 'Ej: Paciente A',
                ),
                maxLength: 80,
              ),
              TextFormField(
                controller: _birthYearController,
                decoration: const InputDecoration(
                  labelText: 'Ano de nacimiento',
                ),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el ano de nacimiento.';
                  }
                  final year = int.tryParse(value.trim());
                  final currentYear = DateTime.now().year;
                  if (year == null || year < 1900 || year > currentYear) {
                    return 'Ano invalido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: const InputDecoration(labelText: 'Sexo'),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Pais'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el pais.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Genes afectados',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
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
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Consiento uso para investigacion'),
                value: _consentForResearch,
                onChanged: (bool? value) {
                  setState(() => _consentForResearch = value ?? false);
                },
              ),
              if (!_consentForResearch)
                Text(
                  'El consentimiento es obligatorio para investigacion.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 20),
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
    );
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

    final patient = PatientModel.create(
      ownerUserId: userId,
      alias: _aliasController.text,
      birthYear: int.parse(_birthYearController.text.trim()),
      sex: _selectedSex,
      country: _countryController.text,
      geneSummary: _selectedGenes.toList(growable: false),
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
