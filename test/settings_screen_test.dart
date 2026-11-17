import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/core/constants/legal_text.dart';
import 'package:tansiyon_seker_defterim/core/theme/app_theme.dart';
import 'package:tansiyon_seker_defterim/screens/settings_screen.dart';
import 'package:tansiyon_seker_defterim/services/measurement_store.dart';

import 'storage_fake.dart';
import 'support_controller_test.dart' show FakeAds;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      DeviceMeasurementStorage.channel,
      (call) async =>
          call.method == 'appVersion' ? '1.0.0' : null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      DeviceMeasurementStorage.channel,
      null,
    );
  });

  testWidgets(
    'Ayarlar açılışta reklam başlatmaz; ödül, sürüm ve gizlilik görünür',
    (tester) async {
      final prefs = seenPreferences();
      await prefs.load();

      final store = MeasurementStore(FakeStorage());
      await store.load();

      final ads = FakeAds()
        ..earn = true
        ..wait = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          localizationsDelegates:
              GlobalMaterialLocalizations.delegates,
          home: SettingsScreen(
            preferences: prefs,
            ads: ads,
            store: store,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(ads.calls, 0);
      expect(find.text('Destekçi'), findsNothing);
      expect(
        find.text('Uygulamaya destek ol'),
        findsOneWidget,
      );

      await tester.tap(find.text('Reklam izle'));
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsOneWidget,
      );

      ads.wait!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Destekçi'), findsOneWidget);
      expect(
        find.text('Desteğin için teşekkürler'),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Gizlilik Politikası'),
        200,
      );

      await tester.tap(
        find.text('Gizlilik Politikası'),
      );

      await tester.pumpAndSettle();

      expect(
        find.text(LegalText.privacy),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Geri'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Sürüm'),
        150,
      );

      expect(
        find.text('Sürüm'),
        findsOneWidget,
      );

      expect(
        find.text('1.0.0'),
        findsOneWidget,
      );

      expect(ads.calls, 1);
    },
  );

  testWidgets(
    'Ayarlar küçük ekranda büyük yazıyla kaydırılır',
    (tester) async {
      tester.view.physicalSize =
          const Size(320, 640);
      tester.view.devicePixelRatio = 1;

      tester.platformDispatcher
          .textScaleFactorTestValue = 2;

      addTearDown(
        tester.view.resetPhysicalSize,
      );

      addTearDown(
        tester.view.resetDevicePixelRatio,
      );

      addTearDown(
        tester.platformDispatcher
            .clearTextScaleFactorTestValue,
      );

      final prefs = seenPreferences();
      await prefs.load();

      final store =
          MeasurementStore(FakeStorage());
      await store.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: const [
            Locale('tr'),
          ],
          localizationsDelegates:
              GlobalMaterialLocalizations
                  .delegates,
          home: SettingsScreen(
            preferences: prefs,
            ads: FakeAds(),
            store: store,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Sürüm'),
        300,
      );

      expect(
        find.text('Sürüm'),
        findsOneWidget,
      );

      expect(
        find.text('1.0.0'),
        findsOneWidget,
      );

      expect(
        tester.takeException(),
        isNull,
      );
    },
  );
}