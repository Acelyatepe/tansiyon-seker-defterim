import '../models/measurement.dart';

enum SummaryPeriod { week, month, all }

class MeasurementSummary {
  MeasurementSummary(
    Iterable<Measurement> records,
    SummaryPeriod period,
    DateTime now,
  ) {
    // Bugün dahil son 7/30 yerel takvim günü.
    final start = switch (period) {
      SummaryPeriod.week => DateTime(now.year, now.month, now.day - 6),
      SummaryPeriod.month => DateTime(now.year, now.month, now.day - 29),
      SummaryPeriod.all => null,
    };
    final filtered = records.where(
      (r) =>
          !r.dateTime.isAfter(now) &&
          (start == null || !r.dateTime.isBefore(start)),
    );
    pressure = filtered.where((r) => r.isPressure).toList();
    fasting = filtered.where((r) => !r.isPressure && r.fasting).toList();
    fed = filtered.where((r) => !r.isPressure && !r.fasting).toList();
  }
  late final List<Measurement> pressure;
  late final List<Measurement> fasting;
  late final List<Measurement> fed;
  static int? average(Iterable<int> values) {
    final list = values.toList();
    return list.isEmpty
        ? null
        : (list.reduce((a, b) => a + b) / list.length).round();
  }

  int? get systolic => average(pressure.map((r) => r.value));
  int? get diastolic => average(pressure.map((r) => r.diastolic!));
  int? get pulse => average(pressure.map((r) => r.pulse).whereType<int>());
  int? get fastingValue => average(fasting.map((r) => r.value));
  int? get fedValue => average(fed.map((r) => r.value));
}
