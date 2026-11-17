import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/validation/measurement_validators.dart';
import '../models/measurement.dart';
import '../widgets/instant_choice.dart';
import '../widgets/instant_dialog.dart';
import '../widgets/measurement_date_time_dialog.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({
    super.key,
    this.now = DateTime.now,
    this.onSave,
    this.initial,
  });

  final DateTime Function() now;
  final Future<void> Function(Measurement)? onSave;
  final Measurement? initial;

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();

  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _glucose = TextEditingController();

  late DateTime _dateTime = widget.now();

  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  late final _scale =
      Tween<double>(begin: 1, end: 1.015).animate(_animation);

  int _type = 0;
  int _meal = 0;
  bool _saving = false;
  bool _submitted = false;

  String? _dateError;
  String? _confirmation;
  Timer? _confirmationTimer;

  Color get _accent =>
      _type == 0 ? AppColors.bloodPressure : AppColors.bloodSugar;

  @override
  void initState() {
    super.initState();

    final record = widget.initial;

    if (record != null) {
      _dateTime = record.dateTime;
      _type = record.isPressure ? 0 : 1;
      _meal = record.fasting ? 0 : 1;

      if (record.isPressure) {
        _systolic.text = '${record.value}';
        _diastolic.text = '${record.diastolic}';
        _pulse.text = record.pulse?.toString() ?? '';
      } else {
        _glucose.text = '${record.value}';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _systolic,
      _diastolic,
      _pulse,
      _glucose,
    ]) {
      controller.dispose();
    }

    _confirmationTimer?.cancel();
    _animation.dispose();
    super.dispose();
  }

  Future<void> _editDateTime() async {
    final value = await showInstantDialog<DateTime>(
      context: context,
      builder: (_) =>
          MeasurementDateTimeDialog(
  value: _dateTime,
  now: widget.now,
  accent: _accent,
),
    );

    if (!mounted || value == null) return;

    setState(() {
      _dateTime = value;
      _dateError = null;
      _confirmation = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _submitted = true;
      _confirmation = null;
      _dateError =
          MeasurementValidators.dateTime(_dateTime, widget.now());
    });

    if (!_form.currentState!.validate() || _dateError != null) {
      return;
    }

    setState(() => _saving = true);

    final record = Measurement(
      id: widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type == 0
          ? MeasurementType.bloodPressure
          : MeasurementType.bloodSugar,
      dateTime: _dateTime,
      value: int.parse(
        _type == 0 ? _systolic.text : _glucose.text,
      ),
      diastolic:
          _type == 0 ? int.parse(_diastolic.text) : null,
      pulse:
          _type == 0 ? int.tryParse(_pulse.text) : null,
      fasting: _meal == 0,
    );

    try {
      await widget.onSave?.call(record);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _confirmation =
            'Kayıt kaydedilemedi. Lütfen tekrar deneyin.';
      });

      return;
    }

    if (!mounted) return;

    if (!MediaQuery.disableAnimationsOf(context)) {
      await _animation.forward();

      if (!mounted) return;

      await _animation.reverse();

      if (!mounted) return;
    }

    if (widget.initial != null) {
      Navigator.pop(context);
      return;
    }

    _form.currentState!.reset();

    for (final controller in [
      _systolic,
      _diastolic,
      _pulse,
      _glucose,
    ]) {
      controller.clear();
    }

    setState(() {
      _saving = false;
      _submitted = false;
      _dateTime = widget.now();
      _dateError = null;
      _confirmation = 'Kayıt eklendi';
    });

    _confirmationTimer?.cancel();

    _confirmationTimer =
        Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _confirmation = null);
      }
    });
  }

  Widget _field(
    String label,
    String unit,
    TextEditingController controller,
    FormFieldValidator<String> validator,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText,
            ),
          ),
        ),
        TextFormField(
          key: ValueKey(label),
          controller: controller,
          enabled: !_saving,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          validator: validator,
          onChanged: (_) {
            if (_submitted) {
              _form.currentState!.validate();
            }

            if (_confirmation != null) {
              setState(() => _confirmation = null);
            }
          },
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedText.withValues(alpha: 0.45),
            ),
            suffixText: unit,
            suffixStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: Color(0xFFEAE5DD),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(
                color: Color(0xFFEAE5DD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: _accent,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            errorMaxLines: 4,
          ),
        ),
      ],
    );
  }

  Widget _typeSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: InstantChoice(
        labels: const ['Tansiyon', 'Şeker'],
        selected: _type,
        accent: _accent,
        onSelected: _saving || widget.initial != null
            ? null
            : (index) {
                if (index == _type) return;

                FocusScope.of(context).unfocus();
                _form.currentState?.reset();

                setState(() {
                  _type = index;
                  _submitted = false;
                  _dateError = null;
                  _confirmation = null;
                });
              },
      ),
    );
  }

  Widget _dateTimeCard() {
    return Semantics(
      label: 'Tarih ve saati düzenle',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _saving ? null : _editDateTime,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEAE5DD),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 20,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_dateTime.day} '
                        '${MaterialLocalizations.of(context).formatMonthYear(_dateTime)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeInput(_dateTime),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashFactory: NoSplash.splashFactory,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.initial == null) ...[
              const Text(
                'Bugünkü ölçümünü ekle',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ölçümlerini kolayca kaydet ve takip et.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText,
                ),
              ),
            ] else ...[
              const Text(
                'Kaydı düzenle',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],

            const SizedBox(height: 22),

            _typeSelector(),

            const SizedBox(height: 22),

            ScaleTransition(
              scale: _scale,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    if (_type == 0) ...[
                      _field(
                        'Büyük tansiyon',
                        'mmHg',
                        _systolic,
                        (value) =>
                            MeasurementValidators.systolic(
                          value,
                          _diastolic.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(
                        'Küçük tansiyon',
                        'mmHg',
                        _diastolic,
                        MeasurementValidators.diastolic,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        'Nabız',
                        'atım/dk · isteğe bağlı',
                        _pulse,
                        MeasurementValidators.pulse,
                      ),
                    ] else ...[
                      _field(
                        'Kan şekeri',
                        'mg/dL',
                        _glucose,
                        MeasurementValidators.glucose,
                      ),
                      const SizedBox(height: 18),
                      const Padding(
                        padding:
                            EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Ölçüm zamanı',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0ECE6),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: InstantChoice(
                          labels: const ['Aç', 'Tok'],
                          selected: _meal,
                          accent: _accent,
                          onSelected: _saving
                              ? null
                              : (index) {
                                  setState(() {
                                    _meal = index;
                                    _confirmation = null;
                                  });
                                },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            _dateTimeCard(),

            if (_dateError != null) ...[
              const SizedBox(height: 8),
              Text(
                _dateError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: 18),

            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
foregroundColor: Colors.white,                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _saving ? 'Kaydediliyor…' : 'Kaydet',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            if (_confirmation != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _confirmation!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}