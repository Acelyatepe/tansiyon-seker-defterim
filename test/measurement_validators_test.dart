import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/core/validation/measurement_validators.dart';

void main() {
  group('Sayısal ölçümler', () {
    final validators = <String, (String? Function(String?), int, int)>{
      'Büyük tansiyon': (
        (v) => MeasurementValidators.systolic(v, '30'),
        50,
        260,
      ),
      'Küçük tansiyon': (MeasurementValidators.diastolic, 30, 160),
      'Nabız': (MeasurementValidators.pulse, 30, 220),
      'Kan şekeri': (MeasurementValidators.glucose, 20, 600),
    };
    for (final entry in validators.entries) {
      final (validate, min, max) = entry.value;
      test(
        '${entry.key}: sınırlar kabul edilir, dışındaki değerler reddedilir',
        () {
          for (final value in [min, max]) {
            expect(validate('$value'), isNull);
          }
          for (final value in [min - 1, max + 1]) {
            expect(validate('$value'), isNotNull);
          }
          for (final value in ['abc', '12.5', '12,5', '-50', '1e2']) {
            expect(validate(value), isNotNull);
          }
        },
      );
    }
    test('Zorunlu alanlar boş bırakılamaz, nabız isteğe bağlıdır', () {
      for (final value in [null, '', '  ']) {
        expect(MeasurementValidators.systolic(value, '80'), isNotNull);
        expect(MeasurementValidators.diastolic(value), isNotNull);
        expect(MeasurementValidators.glucose(value), isNotNull);
        expect(MeasurementValidators.pulse(value), isNull);
      }
    });
    test('Büyük tansiyon küçük tansiyondan kesinlikle büyük olmalıdır', () {
      expect(MeasurementValidators.systolic('80', '80'), isNotNull);
      expect(MeasurementValidators.systolic('79', '80'), isNotNull);
      expect(MeasurementValidators.systolic('81', '80'), isNull);
    });
  });
  group('Tarih ve saat', () {
    test('Takvim ve saat değerleri doğrulanır', () {
      expect(
        MeasurementValidators.parseDateTime('29.02.2024', '23:59'),
        DateTime(2024, 2, 29, 23, 59),
      );
      for (final date in [
        '29.02.2025',
        '31.04.2026',
        '00.01.2026',
        '01.13.2026',
        '01.01.0000',
        'abc',
      ]) {
        expect(MeasurementValidators.parseDateTime(date, '12:00'), isNull);
      }
      for (final time in ['24:00', '12:60', '-1:00', 'abc']) {
        expect(MeasurementValidators.parseDateTime('24.09.2026', time), isNull);
      }
    });
    test(
      'Gelecek dakika ve tarih reddedilir, geçmiş ve şimdi kabul edilir',
      () {
        final now = DateTime(2026, 9, 24, 12, 30);
        expect(MeasurementValidators.dateTime(now, now), isNull);
        expect(
          MeasurementValidators.dateTime(
            now.subtract(const Duration(days: 1)),
            now,
          ),
          isNull,
        );
        expect(
          MeasurementValidators.dateTime(
            now.add(const Duration(minutes: 1)),
            now,
          ),
          isNotNull,
        );
        expect(
          MeasurementValidators.dateTime(now.add(const Duration(days: 1)), now),
          isNotNull,
        );
        expect(MeasurementValidators.dateTime(null, now), isNotNull);
      },
    );
  });
}
