import 'package:flutter/material.dart';
import 'package:tansiyon_seker_defterim/services/measurement_store.dart';

import 'storage_fake.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/app.dart';
import 'package:tansiyon_seker_defterim/core/constants/app_strings.dart';
import 'package:tansiyon_seker_defterim/core/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          DeviceMeasurementStorage.channel,
          (call) async => call.method == 'appVersion' ? '1.0.0' : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(DeviceMeasurementStorage.channel, null);
  });
  testWidgets('Üç sekme ve ayarlar açılır', (tester) async {
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: seenPreferences(),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text('Büyük tansiyon'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Henüz kayıt yok'), findsNWidgets(3));
    expect(find.text('Büyük tansiyon'), findsNothing);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('Henüz kayıt yok'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('Büyük tansiyon'), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.settings));
    await tester.pumpAndSettle();
    expect(find.text('Uygulamaya destek ol'), findsOneWidget);
  });

  testWidgets('Sistem koyu olsa da Türkçe açık tema kullanılır', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: seenPreferences(),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(Localizations.localeOf(context).languageCode, 'tr');
    expect(MaterialLocalizations.of(context).backButtonTooltip, 'Geri');
  });

  testWidgets('Dar ekranda büyük yazılar taşmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: seenPreferences(),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Kaydet normal telefonda kaydırmadan görünür', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      TansiyonSekerDefterimApp(
        preferences: seenPreferences(),
        store: MeasurementStore(FakeStorage()),
      ),
    );
    await tester.pumpAndSettle();
    for (final category in ['Tansiyon', 'Şeker']) {
      await tester.tap(find.text(category));
      await tester.pump();
      final button = find.widgetWithText(FilledButton, 'Kaydet');
      final rect = tester.getRect(button);
      final navigation = tester.getRect(find.byType(NavigationBar));
      expect(button.hitTestable(), findsOneWidget);
      expect(rect.bottom, lessThanOrEqualTo(navigation.top));
      expect(rect.height, 56);
      expect(tester.takeException(), isNull);
    }
  });

  test('Metin ve kullanılan zeminlerde kontrast en az 4.5:1', () {
    final textLuminance = AppColors.text.computeLuminance();
    for (final background in [
      AppColors.background,
      AppColors.surface,
      AppColors.bloodPressure,
      AppColors.bloodSugar,
    ]) {
      final ratio =
          (background.computeLuminance() + 0.05) / (textLuminance + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });
}
