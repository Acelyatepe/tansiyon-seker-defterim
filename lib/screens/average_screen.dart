import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/measurement_store.dart';
import '../services/measurement_summary.dart';
import '../widgets/instant_choice.dart';

class AverageScreen extends StatefulWidget {
  const AverageScreen({
    super.key,
    required this.store,
  });

  final MeasurementStore store;

  @override
  State<AverageScreen> createState() => _AverageScreenState();
}

class _AverageScreenState extends State<AverageScreen> {
  int _period = 0;

  Widget _summaryCard({
    required String title,
    required String? value,
    required String unit,
    required int count,
    required Color accent,
    required IconData icon,
    String? subtitle,
  }) {
    final hasValue = value != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFEAE8E4),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count kayıt',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (!hasValue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 28,
                    color: AppColors.mutedText,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Henüz kayıt yok',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
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
        final summary = MeasurementSummary(
          widget.store.records,
          SummaryPeriod.values[_period],
          DateTime.now(),
        );

        return ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
          ),
          children: [
            const Text(
              'Ortalamaların',
              style: TextStyle(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Kaydettiğin ölçümlerin ortalamasını görüntüle.',
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
                  '7 gün',
                  '30 gün',
                  'Tümü',
                ],
                selected: _period,
                accent: AppColors.text,
                onSelected: (value) {
                  setState(() {
                    _period = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 22),

            _summaryCard(
              title: 'Tansiyon',
              subtitle: 'Ortalama ölçüm',
              value: summary.systolic == null
                  ? null
                  : '${summary.systolic}/${summary.diastolic}',
              unit: 'mmHg',
              count: summary.pressure.length,
              accent: AppColors.bloodPressure,
              icon: Icons.favorite_rounded,
            ),

            if (summary.pulse != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bloodPressure
                      .withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart_outlined,
                      size: 21,
                      color: AppColors.bloodPressure,
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Text(
                        'Ortalama nabız',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    Text(
                      '${summary.pulse} atım/dk',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bloodPressure,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            _summaryCard(
              title: 'Açlık şekeri',
              subtitle: 'Aç karnına ölçümler',
              value: summary.fastingValue?.toString(),
              unit: 'mg/dL',
              count: summary.fasting.length,
              accent: AppColors.bloodSugar,
              icon: Icons.water_drop_rounded,
            ),

            const SizedBox(height: 16),

            _summaryCard(
              title: 'Tokluk şekeri',
              subtitle: 'Tok karnına ölçümler',
              value: summary.fedValue?.toString(),
              unit: 'mg/dL',
              count: summary.fed.length,
              accent: AppColors.bloodSugar,
              icon: Icons.water_drop_outlined,
            ),
          ],
        );
      },
    );
  }
}