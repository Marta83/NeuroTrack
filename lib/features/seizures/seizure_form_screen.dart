import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../core/validators/seizure_validators.dart';
import '../../models/rescue_medication.dart';
import '../../models/seizure_model.dart';
import '../../models/seizure_trigger.dart';
import '../../ui/soft_ui.dart';
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
    _selectedType = _normalizeTypeForForm(initial.type);
    _intensity = initial.intensity;
    _selectedRescueMedicationCode = initial.rescueMedicationCode;
    if (initial.postictalRecoveryMinutes != null) {
      _postictalRecoveryController.text = '${initial.postictalRecoveryMinutes}';
    }
    _rescueMedicationOtherController.text = initial.rescueMedicationOther ?? '';
    _notesController.text = initial.notes ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(seizureContextFormProvider.notifier).loadFromSeizure(initial);
    });

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
    final isEditing = widget.initialSeizure != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar episodio' : 'Registrar episodio'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SoftConstrainedBody(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final extraRightGutter =
                    (kIsWeb || constraints.maxWidth >= 600) ? 12.0 : 0.0;

                return Padding(
                  padding: EdgeInsets.only(right: extraRightGutter),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: <Widget>[
                      _buildWhenSection(context),
                      const SizedBox(height: gapSection),
                      _buildHowSection(context),
                      const SizedBox(height: gapSection),
                      FilledButton.icon(
                        onPressed: isLoading ? null : _saveSeizure,
                        icon: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(isEditing ? 'Guardar cambios' : 'Guardar episodio'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhenSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(icon: Icons.schedule, title: '¿Cuándo ocurrió?'),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _pickDateTime,
          child: InputDecorator(
            decoration: _softInputDecoration(
              context,
              label: 'Fecha y hora',
              hint: 'Seleccionar fecha y hora',
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _selectedDateTime == null
                        ? 'Seleccionar fecha/hora'
                        : _formatDateTime(_selectedDateTime!),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
        if (_showDateTimeError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selecciona fecha y hora para continuar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildHowSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final contextState = ref.watch(seizureContextFormProvider);

    final selectedCount = contextState.triggers.length +
        (contextState.injury ? 1 : 0) +
        (contextState.cyanosis ? 1 : 0) +
        (contextState.emergencyCall ? 1 : 0) +
        (contextState.emergencyVisit ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SoftSectionHeader(icon: Icons.timeline, title: '¿Cómo fue el episodio?'),
        _buildTimesRow(context),
        const SizedBox(height: gapField),
        DropdownButtonFormField<String>(
          initialValue: _selectedType,
          decoration: _softInputDecoration(context, label: 'Tipo'),
          items: _typeOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(growable: false),
          onChanged: (String? value) {
            if (value != null) {
              setState(() => _selectedType = value);
            }
          },
        ),
        const SizedBox(height: 28),
        Text(
          'Severidad',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          '¿Cómo de fuerte fue?',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          SeizureValidators.intensityLabel(_intensity),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 2.5),
          child: Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_intensity',
            activeColor: colorScheme.primary.withValues(alpha: 0.85),
            inactiveColor: colorScheme.onSurface.withValues(alpha: 0.12),
            onChanged: (double value) {
              setState(() => _intensity = value.round().clamp(1, 5));
            },
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 28),
        Text(
          'Ayuda / intervención (opcional)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _selectedRescueMedicationCode,
          decoration: _softInputDecoration(
            context,
            label: 'Medicación de rescate (opcional)',
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
          const SizedBox(height: gapField),
          TextFormField(
            controller: _rescueMedicationOtherController,
            decoration: _softInputDecoration(
              context,
              label: 'Otra medicación (especificar)',
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
        const SizedBox(height: 28),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            setState(() => _isContextExpanded = !_isContextExpanded);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (selectedCount > 0)
                        RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                            children: <TextSpan>[
                              const TextSpan(text: 'Contexto (opcional) · '),
                              TextSpan(
                                text: '$selectedCount seleccionados',
                                style: TextStyle(color: colorScheme.primary),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          'Contexto (opcional)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Completa esta parte solo si aporta información útil.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _isContextExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isContextExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
              _contextSubTitle(context, 'Posibles desencadenantes'),
              const SizedBox(height: gapSmall),
              SoftChipsWrap(
                children: SeizureTrigger.values
                    .map(
                      (trigger) => _contextChip(
                        context,
                        label: trigger.labelEs,
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
              const SizedBox(height: gapField),
              _contextSubTitle(context, 'Consecuencias'),
              const SizedBox(height: gapSmall),
              SoftChipsWrap(
                children: <Widget>[
                  _contextChip(
                    context,
                    label: 'Lesión',
                    selected: contextState.injury,
                    onSelected: (bool selected) {
                      ref.read(seizureContextFormProvider.notifier).setFlag(
                            injury: selected,
                          );
                    },
                  ),
                  _contextChip(
                    context,
                    label: 'Cianosis',
                    selected: contextState.cyanosis,
                    onSelected: (bool selected) {
                      ref.read(seizureContextFormProvider.notifier).setFlag(
                            cyanosis: selected,
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: gapField),
              _contextSubTitle(context, 'Atención médica'),
              const SizedBox(height: gapSmall),
              SoftChipsWrap(
                children: <Widget>[
                  _contextChip(
                    context,
                    label: 'Llamada a emergencias',
                    selected: contextState.emergencyCall,
                    onSelected: (bool selected) {
                      ref.read(seizureContextFormProvider.notifier).setFlag(
                            emergencyCall: selected,
                          );
                    },
                  ),
                  _contextChip(
                    context,
                    label: 'Visita a urgencias',
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
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: _softInputDecoration(
            context,
            label: 'Notas (opcional)',
            hint: 'Añade cualquier detalle que pueda ayudar.',
            fillOpacity: 0.14,
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
    );
  }

  Widget _buildTimesRow(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final durationField = TextFormField(
          controller: _durationController,
          decoration: _softInputDecoration(
            context,
            label: 'Duración',
            helper: 'Si no lo sabes, puedes dejarlo en blanco.',
            suffix: SizedBox(
              width: 76,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _durationUnit,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'seg', child: Text('seg')),
                    DropdownMenuItem<String>(value: 'min', child: Text('min')),
                  ],
                  onChanged: (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _durationUnit = value);
                  },
                ),
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
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

        final recoveryField = TextFormField(
          controller: _postictalRecoveryController,
          decoration: _softInputDecoration(
            context,
            label: 'Recuperación (min) (opcional)',
            hint: 'Tiempo hasta estar como siempre',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          validator: (String? value) {
            final parsed = _parsePostictalRecoveryMinutes(value);
            if (value != null && value.trim().isNotEmpty && parsed == null) {
              return 'Ingresa minutos válidos (1-1440).';
            }
            return null;
          },
        );

        if (constraints.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: durationField),
              const SizedBox(width: gapField),
              Expanded(child: recoveryField),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            durationField,
            const SizedBox(height: gapField),
            recoveryField,
          ],
        );
      },
    );
  }

  InputDecoration _softInputDecoration(
    BuildContext context, {
    required String label,
    String? helper,
    String? hint,
    Widget? suffix,
    double fillOpacity = 0.18,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      helperText: helper,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: fillOpacity),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
      hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
      counterStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
    );
  }

  FilterChip _contextChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.4)
            : colorScheme.outlineVariant.withValues(alpha: 0.6),
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

    if (widget.initialSeizure != null) {
      final updatedSeizure = widget.initialSeizure!.copyWith(
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
        updatedAt: DateTime.now(),
      );
      await ref.read(seizureControllerProvider.notifier).updateSeizure(
            updatedSeizure,
          );
    } else {
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
    }
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

  String _normalizeTypeForForm(String raw) {
    const canonical = <String, String>{
      'FOCAL': 'Focal',
      'GENERALIZADA': 'Generalizada',
      'ABSENCE': 'Ausencia',
      'AUSENCIA': 'Ausencia',
      'TONIC_CLONIC': 'Tonico-clonica',
      'TONICO_CLONICA': 'Tonico-clonica',
      'TONICO-CLONICA': 'Tonico-clonica',
      'MYOCLONIC': 'Otro',
      'OTRO': 'Otro',
    };

    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return _typeOptions.first;
    }

    final mapped = canonical[normalized.toUpperCase()] ?? normalized;
    if (_typeOptions.contains(mapped)) {
      return mapped;
    }
    return _typeOptions.first;
  }

  void _scrollToValidationError() {
    double offset = 0;
    if (_selectedDateTime == null) {
      offset = 0;
    } else if (_postictalRecoveryController.text.trim().isNotEmpty &&
        _parsePostictalRecoveryMinutes(_postictalRecoveryController.text) ==
            null) {
      offset = 340;
    } else if (_selectedRescueMedicationCode == RescueMedication.otherCode &&
        _rescueMedicationOtherController.text.trim().isEmpty) {
      offset = 520;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }
}
