import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/models/measurement.dart';
import 'package:tansiyon_seker_defterim/services/measurement_store.dart';

import 'storage_fake.dart';

Measurement record(String id, {int value = 120, DateTime? date}) => Measurement(
  id: id,
  type: MeasurementType.bloodPressure,
  dateTime: date ?? DateTime(2026, 9, 24, 12),
  value: value,
  diastolic: 80,
  pulse: 70,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Kayıt, yeniden açılış, düzenleme ve silme depoya yansır', () async {
    final disk = FakeStorage();
    final store = MeasurementStore(disk);
    await store.load();
    await store.add(record('1'));
    await store.add(
      Measurement(
        id: '2',
        type: MeasurementType.bloodSugar,
        dateTime: DateTime(2026, 9, 24),
        value: 101,
        fasting: false,
      ),
    );
    final reopened = MeasurementStore(disk);
    await reopened.load();
    expect(reopened.records.length, 2);
    expect(reopened.records.first.pulse, 70);
    expect(reopened.records.last.fasting, false);
    await reopened.update(record('1', value: 130));
    expect(reopened.records.first.value, 130);
    await reopened.delete('2');
    final finalStore = MeasurementStore(disk);
    await finalStore.load();
    expect(finalStore.records.single.value, 130);
    expect(finalStore.records.single.id, '1');
  });

  test(
    'Yazma hatası önceki kaydı korur ve dinleyicilere başarı bildirmez',
    () async {
      final disk = FakeStorage();
      final store = MeasurementStore(disk);
      await store.load();
      await store.add(record('1'));
      final before = disk.data;
      var changes = 0;
      store.addListener(() => changes++);
      disk.failWrite = true;
      await expectLater(
        store.update(record('1', value: 130)),
        throwsStateError,
      );
      await expectLater(store.delete('1'), throwsStateError);
      expect(store.records.single.value, 120);
      expect(disk.data, before);
      expect(changes, 0);
      disk.failWrite = false;
      await store.update(record('1', value: 140));
      expect(changes, 1);
      expect(store.records.single.value, 140);
    },
  );

  test('Bozuk ölçüm içerikleri yüklenmez ve zaman damgası korunur', () async {
    final original = record('1');
    final encoded = original.toJson();
    expect(Measurement.fromJson(encoded).dateTime, original.dateTime);
    final disk = FakeStorage()
      ..data = jsonEncode({
        'version': 1,
        'records': [
          {...encoded, 'diastolic': null},
        ],
      });
    await expectLater(
      MeasurementStore(disk).load(),
      throwsA(isA<FormatException>()),
    );
  });

  test('Eşzamanlı eklemeler kaybolmaz', () async {
    final store = MeasurementStore(FakeStorage());
    await store.load();
    await Future.wait([store.add(record('1')), store.add(record('2'))]);
    expect(store.records.length, 2);
  });

  test('Bozuk dosya veya bilinmeyen sürüm sıfırlanmaz', () async {
    for (final raw in [
      'broken',
      jsonEncode({'version': 2, 'records': []}),
    ]) {
      final disk = FakeStorage()..data = raw;
      final store = MeasurementStore(disk);
      await expectLater(store.load(), throwsA(isA<FormatException>()));
      await expectLater(store.add(record('1')), throwsStateError);
      expect(disk.data, raw);
    }
  });

  test(
    'Android depolama kanalı veriyi yeniden okur ve hatayı iletir',
    () async {
      String? persisted;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(DeviceMeasurementStorage.channel, (
        call,
      ) async {
        if (call.method == 'read') return persisted;
        persisted = call.arguments as String;
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          DeviceMeasurementStorage.channel,
          null,
        ),
      );
      final store = MeasurementStore(DeviceMeasurementStorage());
      await store.load();
      await store.add(record('native'));
      final reopened = MeasurementStore(DeviceMeasurementStorage());
      await reopened.load();
      expect(reopened.records.single.id, 'native');
      messenger.setMockMethodCallHandler(DeviceMeasurementStorage.channel, (
        _,
      ) async {
        throw PlatformException(code: 'storage_error');
      });
      await expectLater(
        reopened.delete('native'),
        throwsA(isA<PlatformException>()),
      );
      expect(reopened.records.single.id, 'native');
    },
  );
}
