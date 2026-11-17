import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/models/measurement.dart';
import 'package:tansiyon_seker_defterim/services/measurement_summary.dart';

void main() {
  final now = DateTime(2026, 9, 24, 12);
  Measurement pressure(int value, int small, int? pulse, DateTime date) =>
      Measurement(
        id: '$value-$date',
        type: MeasurementType.bloodPressure,
        dateTime: date,
        value: value,
        diastolic: small,
        pulse: pulse,
      );
  Measurement sugar(int value, bool fasting) => Measurement(
    id: '$value',
    type: MeasurementType.bloodSugar,
    dateTime: now,
    value: value,
    fasting: fasting,
  );

  test('Ortalamalar yuvarlanır, boş nabız dışlanır, Aç ve Tok ayrılır', () {
    final summary = MeasurementSummary(
      [
        pressure(123, 80, 71, now),
        pressure(124, 81, null, now),
        sugar(100, true),
        sugar(101, true),
        sugar(140, false),
      ],
      SummaryPeriod.all,
      now,
    );
    expect(summary.systolic, 124);
    expect(summary.diastolic, 81);
    expect(summary.pulse, 71);
    expect(summary.pressure.length, 2);
    expect(summary.fastingValue, 101);
    expect(summary.fasting.length, 2);
    expect(summary.fedValue, 140);
    expect(summary.fed.length, 1);
  });

  test('7 ve 30 gün bugün dahil yerel takvim sınırlarını kullanır', () {
    final records = [
      pressure(100, 70, null, DateTime(2026, 9, 18)),
      pressure(110, 75, null, DateTime(2026, 9, 17, 23, 59)),
      pressure(120, 80, null, DateTime(2026, 8, 26)),
      pressure(130, 85, null, DateTime(2026, 8, 25, 23, 59)),
      pressure(140, 90, null, now.add(const Duration(minutes: 1))),
    ];
    expect(
      MeasurementSummary(records, SummaryPeriod.week, now).pressure.length,
      1,
    );
    expect(
      MeasurementSummary(records, SummaryPeriod.month, now).pressure.length,
      3,
    );
    expect(
      MeasurementSummary(records, SummaryPeriod.all, now).pressure.length,
      4,
    );
  });

  test('Boş gruplarda ortalama yoktur', () {
    final summary = MeasurementSummary([], SummaryPeriod.all, now);
    expect(summary.systolic, isNull);
    expect(summary.diastolic, isNull);
    expect(summary.pulse, isNull);
    expect(summary.fastingValue, isNull);
    expect(summary.fedValue, isNull);
  });
}
