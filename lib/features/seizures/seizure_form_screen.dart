import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/seizure_model.dart';
import 'seizure_provider.dart';

class SeizureFormScreen extends ConsumerStatefulWidget {
  const SeizureFormScreen({
    required this.patientId,
    super.key,
  });

  final String patientId;

  @override
  ConsumerState<SeizureFormScreen> createState() => _SeizureFormScreenState();
}

class _SeizureFormScreenState extends ConsumerState<SeizureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _medicationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDateTime;
  String _selectedType = 'Focal';
  int _intensity = 3;

  static const List<String> _typeOptions = <String>[
    'Focal',
    'Generalizada',
    'Ausencia',
    'Tonico-clonica',
    'Otro',
  ];

  @override
  void dispose() {
    _durationController.dispose();
    _medicationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(seizureControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar crisis')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha y hora'),
                subtitle: Text(
                  _selectedDateTime == null
                      ? 'Seleccionar fecha/hora'
                      : _formatDateTime(_selectedDateTime!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              if (_selectedDateTime == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'La fecha es obligatoria.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duracion (segundos)',
                ),
                keyboardType: TextInputType.number,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La duracion es obligatoria.';
                  }
                  final duration = int.tryParse(value.trim());
                  if (duration == null || duration <= 0) {
                    return 'La duracion debe ser mayor a 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: _typeOptions
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
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Intensidad: $_intensity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_intensity',
                onChanged: (double value) {
                  setState(() => _intensity = value.toInt());
                },
              ),
              TextFormField(
                controller: _medicationController,
                decoration: const InputDecoration(labelText: 'Medicacion'),
                maxLength: 500,
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 4,
                maxLength: 2000,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isLoading ? null : _saveSeizure,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );
    if (pickedTime == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveSeizure() async {
    if (_selectedDateTime == null) {
      setState(() {});
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final seizure = SeizureModel.create(
      patientId: widget.patientId,
      dateTime: _selectedDateTime!,
      durationSeconds: int.parse(_durationController.text.trim()),
      type: _selectedType,
      intensity: _intensity,
      medicationUsed: _medicationController.text,
      notes: _notesController.text,
    );

    await ref.read(seizureControllerProvider.notifier).createSeizure(seizure);
    final state = ref.read(seizureControllerProvider);

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

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}
