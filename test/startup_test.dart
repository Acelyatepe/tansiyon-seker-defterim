import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/app.dart';
import 'package:tansiyon_seker_defterim/core/constants/legal_text.dart';
import 'package:tansiyon_seker_defterim/services/app_preferences.dart';
import 'package:tansiyon_seker_defterim/services/measurement_store.dart';
import 'storage_fake.dart';

class HangingStorage implements MeasurementStorage {
  final pending = Completer<String?>();
  @override
  Future<String?> read() => pending.future;
  @override
  Future<void> write(String data) async {}
}

void main() {
  testWidgets('Karşılama yalnızca bir kez gösterilir ve cihazda saklanır', (
    tester,
  ) async {
    final disk = FakeStorage();
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: AppPreferences(disk),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(LegalText.medicalNotice), findsOneWidget);
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.text('Büyük tansiyon'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: AppPreferences(disk),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Devam et'), findsNothing);
    expect(find.text('Büyük tansiyon'), findsOneWidget);
  });

  testWidgets('Dosya yoksa boş kayıtlarla açılır', (tester) async {
    final store = MeasurementStore(FakeStorage());
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(preferences: seenPreferences(), store: store),
    );
    await tester.pumpAndSettle();
    expect(find.text('Büyük tansiyon'), findsOneWidget);
    expect(store.records, isEmpty);
  });

  testWidgets('Yanıtsız servis sonlanır; geç gelen yanıt dosyayı boşaltmaz', (
    tester,
  ) async {
    final disk = HangingStorage();
    final store = MeasurementStore(
      disk,
      loadTimeout: const Duration(seconds: 1),
    );
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(preferences: seenPreferences(), store: store),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Kayıtlar yükleniyor…'), findsNothing);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.text('Büyük tansiyon'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('Henüz kayıt yok'), findsOneWidget);
    disk.pending.complete(null);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('Tekrar dene'), findsNothing);
  });

  testWidgets('Bozuk ve eski veri yüklemeyi kilitlemez; veri korunur', (
    tester,
  ) async {
    for (final raw in ['broken', '{"version":0,"records":[]}']) {
      final disk = FakeStorage()..data = raw;
      await tester.pumpWidget(
        TansiyonSekerDefterimApp(
          key: ValueKey(raw),
          preferences: seenPreferences(),
          store: MeasurementStore(disk),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kayıtlar yükleniyor…'), findsNothing);
      expect(find.text('Tekrar dene'), findsOneWidget);
      expect(find.text('Büyük tansiyon'), findsOneWidget);
      expect(disk.data, raw);
    }
  });

  testWidgets('Karşılama kaydedilemezse yanlışlıkla tamamlandı sayılmaz', (
    tester,
  ) async {
    final disk = FakeStorage()..failWrite = true;
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: AppPreferences(disk),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tercihiniz kaydedilemedi'), findsOneWidget);
    expect(disk.data, isNull);
  });
}
