import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/app.dart';
import 'package:tansiyon_seker_defterim/models/measurement.dart';
import 'package:tansiyon_seker_defterim/services/measurement_store.dart';

import 'storage_fake.dart';

void main() {
  testWidgets('Ekle, geçmişten düzenle, ortalamayı gör ve onayla sil', (
    tester,
  ) async {
    final disk = FakeStorage();
    final store = MeasurementStore(disk);
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(preferences: seenPreferences(), store: store),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('Büyük tansiyon')), '120');
    await tester.enterText(find.byKey(const ValueKey('Küçük tansiyon')), '80');
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(store.records.single.value, 120);
    expect(find.text('Kayıt eklendi'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('120/80 mmHg'), findsOneWidget);
    await tester.tap(find.text('120/80 mmHg'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('Büyük tansiyon')))
          .controller!
          .text,
      '120',
    );
    await tester.enterText(find.byKey(const ValueKey('Büyük tansiyon')), '130');
    await tester.ensureVisible(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(find.text('130/80 mmHg'), findsOneWidget);
    expect(store.records.length, 1);
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('130/80'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kaydı sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(store.records.length, 1);
    await tester.tap(find.byTooltip('Kaydı sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(store.records, isEmpty);
    expect(find.text('Henüz kayıt yok'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Henüz kayıt yok'), findsNWidgets(3));
    final reopened = MeasurementStore(disk);
    await reopened.load();
    expect(reopened.records, isEmpty);
  });

  testWidgets('Kayıt hatasında form korunur ve tekrar kaydedilebilir', (
    tester,
  ) async {
    final disk = FakeStorage()..failWrite = true;
    final store = MeasurementStore(disk);
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(preferences: seenPreferences(), store: store),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Şeker'));
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('Kan şekeri')), '100');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kayıt kaydedilemedi. Lütfen tekrar deneyin.'),
      findsOneWidget,
    );
    expect(store.records, isEmpty);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('Kan şekeri')))
          .controller!
          .text,
      '100',
    );
    disk.failWrite = false;
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(store.records.single.value, 100);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
    'Geçmiş sırası, gün grupları ve filtreler; küçük ekranda taşma yok',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final disk = FakeStorage();
      final seed = MeasurementStore(disk);
      await seed.load();
      await seed.add(
        Measurement(
          id: 'old',
          type: MeasurementType.bloodPressure,
          dateTime: DateTime(2026, 9, 23),
          value: 120,
          diastolic: 80,
        ),
      );
      await seed.add(
        Measurement(
          id: 'new',
          type: MeasurementType.bloodSugar,
          dateTime: DateTime(2026, 9, 24),
          value: 100,
        ),
      );
      await tester.pumpWidget(
        TansiyonSekerDefterimApp(
          preferences: seenPreferences(),
          store: MeasurementStore(disk),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('24 Eylül 2026'), findsOneWidget);
      expect(find.text('100 mg/dL'), findsOneWidget);
      await tester.tap(find.text('Tansiyon'));
      await tester.pumpAndSettle();
      expect(find.text('100 mg/dL'), findsNothing);
      expect(find.text('23 Eylül 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.bar_chart_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tüm zamanlar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
