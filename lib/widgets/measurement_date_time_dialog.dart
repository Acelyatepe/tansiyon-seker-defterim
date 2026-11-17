import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/validation/measurement_validators.dart';

String dateInput(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year.toString().padLeft(4, '0')}';

String timeInput(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class MeasurementDateTimeDialog extends StatefulWidget {
  const MeasurementDateTimeDialog({
    super.key,
    required this.value,
    required this.now,
    required this.accent,
  });

  final DateTime value;
  final DateTime Function() now;
  final Color accent;

  @override
  State<MeasurementDateTimeDialog> createState() =>
      _MeasurementDateTimeDialogState();
}

class _MeasurementDateTimeDialogState
    extends State<MeasurementDateTimeDialog> {
  late final List<TextEditingController> _dateControllers;
  late final List<TextEditingController> _timeControllers;

  late final List<FocusNode> _dateFocusNodes;
  late final List<FocusNode> _timeFocusNodes;

  String? _error;

  @override
  void initState() {
    super.initState();

    _dateControllers = [
      TextEditingController(
        text: widget.value.day.toString().padLeft(2, '0'),
      ),
      TextEditingController(
        text: widget.value.month.toString().padLeft(2, '0'),
      ),
      TextEditingController(
        text: widget.value.year.toString().padLeft(4, '0'),
      ),
    ];

    _timeControllers = [
      TextEditingController(
        text: widget.value.hour.toString().padLeft(2, '0'),
      ),
      TextEditingController(
        text: widget.value.minute.toString().padLeft(2, '0'),
      ),
    ];

    _dateFocusNodes = List.generate(3, (_) => FocusNode());
    _timeFocusNodes = List.generate(2, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in [
      ..._dateControllers,
      ..._timeControllers,
    ]) {
      controller.dispose();
    }

    for (final node in [
      ..._dateFocusNodes,
      ..._timeFocusNodes,
    ]) {
      node.dispose();
    }

    super.dispose();
  }

  void _clearError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Widget _numberPart({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLength,
    FocusNode? nextFocus,
    double width = 48,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLength,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        decoration: const InputDecoration(
          counterText: '',
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onTap: () {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        },
        onChanged: (value) {
          _clearError();

          if (value.length == maxLength && nextFocus != null) {
            nextFocus.requestFocus();
          }
        },
      ),
    );
  }

  Widget _separator(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
    );
  }

  Widget _inputBox({
    required String label,
    required String helper,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE7E4DF),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: widget.accent,
                size: 21,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 7),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            helper,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedText,
            ),
          ),
        ),
      ],
    );
  }

  void _apply() {
    final day = _dateControllers[0].text;
    final month = _dateControllers[1].text;
    final year = _dateControllers[2].text;

    final hour = _timeControllers[0].text;
    final minute = _timeControllers[1].text;

    if (day.length != 2 ||
        month.length != 2 ||
        year.length != 4 ||
        hour.length != 2 ||
        minute.length != 2) {
      setState(() {
        _error = 'Tarih ve saat bilgilerini eksiksiz girin.';
      });
      return;
    }

    final dateText = '$day.$month.$year';
    final timeText = '$hour:$minute';

    final value = MeasurementValidators.parseDateTime(
      dateText,
      timeText,
    );

    final error =
        MeasurementValidators.dateTime(value, widget.now());

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: widget.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarih ve saat',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ölçüm zamanını düzenle',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              _inputBox(
                label: 'Tarih',
                helper: 'GG.AA.YYYY',
                icon: Icons.calendar_today_rounded,
                child: Row(
                  children: [
                    _numberPart(
                      controller: _dateControllers[0],
                      focusNode: _dateFocusNodes[0],
                      maxLength: 2,
                      nextFocus: _dateFocusNodes[1],
                    ),
                    _separator('.'),
                    _numberPart(
                      controller: _dateControllers[1],
                      focusNode: _dateFocusNodes[1],
                      maxLength: 2,
                      nextFocus: _dateFocusNodes[2],
                    ),
                    _separator('.'),
                    _numberPart(
                      controller: _dateControllers[2],
                      focusNode: _dateFocusNodes[2],
                      maxLength: 4,
                      width: 68,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _inputBox(
                label: 'Saat',
                helper: '24 saat formatı · SS:DD',
                icon: Icons.schedule_rounded,
                child: Row(
                  children: [
                    _numberPart(
                      controller: _timeControllers[0],
                      focusNode: _timeFocusNodes[0],
                      maxLength: 2,
                      nextFocus: _timeFocusNodes[1],
                    ),
                    _separator(':'),
                    _numberPart(
                      controller: _timeControllers[1],
                      focusNode: _timeFocusNodes[1],
                      maxLength: 2,
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.text,
                          side: const BorderSide(
                            color: Color(0xFFE2E0DC),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _apply,
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: const Text(
                          'Uygula',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}