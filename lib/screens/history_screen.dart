import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/measurement.dart';
import '../services/measurement_store.dart';
import '../widgets/instant_choice.dart';
import 'add_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.store,
  });

  final MeasurementStore store;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _filter = 0;

  List<Measurement> _filteredRecords() {
    final records = [...widget.store.records]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (_filter == 1) {
      return records.where((record) => record.isPressure).toList();
    }

    if (_filter == 2) {
      return records.where((record) => !record.isPressure).toList();
    }

    return records;
  }

  String _monthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];

    return months[month - 1];
  }

  String _dateTitle(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  String _time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _edit(Measurement record) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Kaydı düzenle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          body: SafeArea(
            child: AddScreen(
              initial: record,
              onSave: widget.store.update,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Measurement record) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.bloodPressure.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.bloodPressure,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kayıt silinsin mi?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu ölçüm kalıcı olarak silinir. Bu işlem geri alınamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(
                              color: Color(0xFFE2E0DC),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.bloodPressure,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Sil',
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
        );
      },
    );

    if (approved != true || !mounted) return;

    try {
      await widget.store.delete(record.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kayıt silinemedi. Lütfen tekrar deneyin.',
          ),
        ),
      );
    }
  }

  Widget _recordCard(Measurement record) {
    final accent = record.isPressure
        ? AppColors.bloodPressure
        : AppColors.bloodSugar;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEAE8E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              record.isPressure
                  ? Icons.favorite_rounded
                  : Icons.water_drop_rounded,
              color: accent,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _time(record.dateTime),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText,
                      ),
                    ),
                    if (!record.isPressure) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.fasting ? 'Aç' : 'Tok',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 5),

                if (record.isPressure)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.value}/${record.diastolic}',
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          'mmHg',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.value}',
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Text(
                          'mg/dL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (record.isPressure && record.pulse != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.monitor_heart_outlined,
                        size: 15,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${record.pulse} atım/dk',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          PopupMenuButton<String>(
            tooltip: 'İşlemler',
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.mutedText,
            ),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _edit(record);
              } else if (value == 'delete') {
                _delete(record);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.text,
                    ),
                    SizedBox(width: 10),
                    Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.bloodPressure,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sil',
                      style: TextStyle(
                        color: AppColors.bloodPressure,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final records = _filteredRecords();

        final grouped = <DateTime, List<Measurement>>{};

        for (final record in records) {
          final day = DateTime(
            record.dateTime.year,
            record.dateTime.month,
            record.dateTime.day,
          );

          grouped.putIfAbsent(day, () => []).add(record);
        }

        return ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'Geçmiş ölçümlerin',
              style: TextStyle(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Kaydettiğin tansiyon ve şeker ölçümlerini görüntüle.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedText,
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0ECE6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: InstantChoice(
                labels: const [
                  'Hepsi',
                  'Tansiyon',
                  'Şeker',
                ],
                selected: _filter,
                accent: AppColors.text,
                onSelected: (value) {
                  setState(() {
                    _filter = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 22),

            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 44,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEAE8E4),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 34,
                      color: AppColors.mutedText,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Henüz kayıt yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Eklediğin ölçümler burada görünür.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 4,
                    bottom: 10,
                    top: 2,
                  ),
                  child: Text(
                    _dateTitle(entry.key),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                for (final record in entry.value)
                  _recordCard(record),
                const SizedBox(height: 8),
              ],
          ],
        );
      },
    );
  }
}