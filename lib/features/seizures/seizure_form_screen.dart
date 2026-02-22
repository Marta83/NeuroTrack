import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/validators/seizure_validators.dart';
import '../../models/rescue_medication.dart';
import '../../models/seizure_model.dart';
import '../../models/seizure_trigger.dart';
import 'seizure_context_form_state.dart';
import 'seizure_provider.dart';

class SeizureFormScreen extends ConsumerStatefulWidget {
  const SeizureFormScreen({
    required this.patientId,
    this.initialSeizure,
    super.key,
  });

  final String patientId;
  final SeizureModel? initialSeizure;

  @override
  ConsumerState<SeizureFormScreen> createState() => _SeizureFormScreenState();
}

class _SeizureFormScreenState extends ConsumerState<SeizureFormScreen> {
  static const double _maxFormWidth = 760;
  static const double _cardRadius = 16;
  static const double _inputRadius = 12;
  static const double _sectionGap = 20;
  static const double _fieldGap = 12;
  static const EdgeInsets _cardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _durationController = TextEditingController();
  final _postictalRecoveryController = TextEditingController();
  final _rescueMedicationOtherController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDateTime;
  bool _showDateTimeError = false;
  bool _isContextExpanded = false;
  String _selectedType = 'Focal';
  int _intensity = 3;
  String? _selectedRescueMedicationCode;
  String _durationUnit = 'seg';

  static const List<String> _typeOptions = <String>[
    'Focal',
    'Generalizada',
    'Ausencia',
    'Tonico-clonica',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSeizure;
    if (initial == null) {
      return;
    }

    _selectedDateTime = initial.dateTime;
    _selectedType = initial.type;
    _intensity = initial.intensity;
    _selectedRescueMedicationCode = initial.rescueMedicationCode;
    if (initial.postictalRecoveryMinutes != null) {
      _postictalRecoveryController.text = '${initial.postictalRecoveryMinutes}';
    }
    _rescueMedicationOtherController.text = initial.rescueMedicationOther ?? '';
    _notesController.text = initial.notes ?? '';
    ref.read(seizureContextFormProvider.notifier).loadFromSeizure(initial);

    final durationSeconds = initial.durationSeconds;
    if (durationSeconds != null) {
      if (durationSeconds % 60 == 0) {
        _durationUnit = 'min';
        _durationController.text = '${durationSeconds ~/ 60}';
      } else {
        _durationUnit = 'seg';
        _durationController.text = '$durationSeconds';
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _durationController.dispose();
    _postictalRecoveryController.dispose();
    _rescueMedicationOtherController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(seizureControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar episodio')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxFormWidth),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  _buildWhenSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildHowSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildAfterSection(context),
                  const SizedBox(height: _sectionGap),
                  _buildAdditionalSection(context),
                  const SizedBox(height: _sectionGap),
                  FilledButton.icon(
                    onPressed: isLoading ? null : _saveSeizure,
                    icon: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar episodio'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhenSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _sectionCard(
      context,
      title: '¿Cuándo ocurrió?',
      icon: Icons.schedule,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          if (_showDateTimeError)
            Text(
              'Selecciona fecha y hora para continuar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _sectionCard(
      context,
      title: 'Cómo fue',
      icon: Icons.timeline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildDurationInput(context),
          const SizedBox(height: _fieldGap),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: _inputDecoration(context, labelText: 'Tipo'),
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
          const SizedBox(height: _fieldGap),
          Text(
            '¿Cómo de fuerte fue?  —  ${SeizureValidators.intensityLabel(_intensity)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_intensity',
            onChanged: (double value) {
              setState(() => _intensity = value.round().clamp(1, 5));
            },
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Leve',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              Text(
                'Muy intensa',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInput(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final durationField = TextFormField(
          controller: _durationController,
          decoration: _inputDecoration(
            context,
            labelText: '¿Cuánto duró?',
            helperText: 'Si no lo sabes, puedes dejarlo en blanco.',
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
            final duration = int.tryParse(raw);
            if (duration == null || duration <= 0) {
              return 'Solo enteros positivos.';
            }
            return null;
          },
        );

        final segmented = SizedBox(
          height: 56,
          child: SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'seg', label: Text('seg')),
              ButtonSegment<String>(value: 'min', label: Text('min')),
            ],
            selected: <String>{_durationUnit},
            showSelectedIcon: false,
            onSelectionChanged: (Set<String> selected) {
              if (selected.isEmpty) {
                return;
              }
              setState(() {
                _durationUnit = selected.first;
              });
            },
          ),
        );

        if (constraints.maxWidth < 430) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              SizedBox(width: constraints.maxWidth, child: durationField),
              segmented,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: durationField),
            const SizedBox(width: 12),
            segmented,
          ],
        );
      },
    );
  }

  Widget _buildAfterSection(BuildContext context) {
    return _sectionCard(
      context,
      title: 'Después del episodio',
      icon: Icons.healing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _postictalRecoveryController,
            decoration: _inputDecoration(
              context,
              labelText:
                  '¿En cuánto tiempo volvió a estar como siempre? (min) (opcional)',
              hintText: 'Ej: 10',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (String? value) {
              final parsed = _parsePostictalRecoveryMinutes(value);
              if (value != null && value.trim().isNotEmpty && parsed == null) {
                return 'Ingresa minutos válidos (1-1440).';
              }
              return null;
            },
          ),
          const SizedBox(height: _fieldGap),
          DropdownButtonFormField<String?>(
            initialValue: _selectedRescueMedicationCode,
            decoration: _inputDecoration(
              context,
              labelText: 'Medicación de rescate (opcional)',
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Ninguna'),
              ),
              ...RescueMedication.values.map(
                (option) => DropdownMenuItem<String?>(
                  value: option.code,
                  child: Text(option.labelEs),
                ),
              ),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedRescueMedicationCode = value;
                if (value != RescueMedication.otherCode) {
                  _rescueMedicationOtherController.clear();
                }
              });
            },
          ),
          if (_selectedRescueMedicationCode == RescueMedication.otherCode) ...<Widget>[
            const SizedBox(height: _fieldGap),
            TextFormField(
              controller: _rescueMedicationOtherController,
              decoration: _inputDecoration(
                context,
                labelText: 'Otra medicación (especificar)',
              ),
              maxLength: 500,
              validator: (String? value) {
                try {
                  SeizureValidators.normalizeRescueMedicationOther(
                    rescueMedicationCode: _selectedRescueMedicationCode,
                    rescueMedicationOther: value,
                  );
                  return null;
                } catch (_) {
                  return 'Indica la medicación utilizada.';
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalSection(BuildContext context) {
    final contextState = ref.watch(seizureContextFormProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final int selectedCount = contextState.triggers.length +
        (contextState.injury ? 1 : 0) +
        (contextState.cyanosis ? 1 : 0) +
        (contextState.emergencyCall ? 1 : 0) +
        (contextState.emergencyVisit ? 1 : 0);

    final String contextTitle = selectedCount == 0
        ? '¿Había algo que pudiera haber influido? (opcional)'
        : '¿Había algo que pudiera haber influido? ($selectedCount seleccionados)';

    return _sectionCard(
      context,
      title: 'Información adicional',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              initiallyExpanded: _isContextExpanded,
              onExpansionChanged: (bool value) {
                setState(() => _isContextExpanded = value);
              },
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Text(contextTitle),
              children: <Widget>[
                _contextSubTitle(context, 'Posibles desencadenantes'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SeizureTrigger.values
                      .map(
                        (trigger) => FilterChip(
                          label: Text(trigger.labelEs),
                          selected: contextState.hasTrigger(trigger.code),
                          onSelected: (_) {
                            ref
                                .read(seizureContextFormProvider.notifier)
                                .toggleTrigger(trigger.code);
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 16),
                _contextSubTitle(context, 'Consecuencias'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilterChip(
                      label: const Text('Lesión'),
                      selected: contextState.injury,
                      onSelected: (bool selected) {
                        ref.read(seizureContextFormProvider.notifier).setFlag(
                              injury: selected,
                            );
                      },
                    ),
                    FilterChip(
                      label: const Text('Cianosis'),
                      selected: contextState.cyanosis,
                      onSelected: (bool selected) {
                        ref.read(seizureContextFormProvider.notifier).setFlag(
                              cyanosis: selected,
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _contextSubTitle(context, 'Atención médica'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    FilterChip(
                      label: const Text('Llamada a emergencias'),
                      selected: contextState.emergencyCall,
                      onSelected: (bool selected) {
                        ref.read(seizureContextFormProvider.notifier).setFlag(
                              emergencyCall: selected,
                            );
                      },
                    ),
                    FilterChip(
                      label: const Text('Visita a urgencias'),
                      selected: contextState.emergencyVisit,
                      onSelected: (bool selected) {
                        ref.read(seizureContextFormProvider.notifier).setFlag(
                              emergencyVisit: selected,
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: _fieldGap),
          TextFormField(
            controller: _notesController,
            decoration: _inputDecoration(
              context,
              labelText: 'Notas (opcional)',
              hintText: 'Ej: estaba resfriado, había dormido poco…',
            ),
            maxLines: 4,
            maxLength: 2000,
            buildCounter: (
              BuildContext context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              return Text(
                '$currentLength/${maxLength ?? 2000}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              );
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
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  icon,
                  size: 19,
                  color: colorScheme.onSurfaceVariant,
                ),
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
            const SizedBox(height: _fieldGap),
            child,
          ],
        ),
      ),
    );
  }

  Widget _contextSubTitle(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String labelText,
    String? helperText,
    String? hintText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      hintText: hintText,
      filled: true,
      isDense: false,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_inputRadius),
      ),
      helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
      counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
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
      _showDateTimeError = false;
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
      setState(() {
        _showDateTimeError = true;
      });
      _scrollToValidationError();
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      _scrollToValidationError();
      return;
    }

    final int? durationSeconds =
        _durationToSeconds(_durationController.text, _durationUnit);
    final int? postictalRecoveryMinutes = _parsePostictalRecoveryMinutes(
      _postictalRecoveryController.text,
    );
    final seizureContext = ref.read(seizureContextFormProvider);

    final seizure = SeizureModel.create(
      patientId: widget.patientId,
      dateTime: _selectedDateTime!,
      durationSeconds: durationSeconds,
      durationUnknown: false,
      type: _selectedType,
      intensity: _intensity,
      postictalRecoveryMinutes: postictalRecoveryMinutes,
      triggers: seizureContext.triggers.toList(growable: false),
      injury: seizureContext.injury,
      cyanosis: seizureContext.cyanosis,
      emergencyCall: seizureContext.emergencyCall,
      emergencyVisit: seizureContext.emergencyVisit,
      rescueMedicationCode: _selectedRescueMedicationCode,
      rescueMedicationOther: _rescueMedicationOtherController.text,
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

  int? _durationToSeconds(String raw, String unit) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    if (unit == 'min') {
      return parsed * 60;
    }
    return parsed;
  }

  int? _parsePostictalRecoveryMinutes(String? raw) {
    final normalized = raw?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    if (parsed > SeizureValidators.maxPostictalRecoveryMinutes) {
      return null;
    }
    return parsed;
  }

  void _scrollToValidationError() {
    double offset = 0;
    if (_selectedDateTime == null) {
      offset = 0;
    } else if (_postictalRecoveryController.text.trim().isNotEmpty &&
        _parsePostictalRecoveryMinutes(_postictalRecoveryController.text) == null) {
      offset = 460;
    } else if (_selectedRescueMedicationCode == RescueMedication.otherCode &&
        _rescueMedicationOtherController.text.trim().isEmpty) {
      offset = 560;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }
}
