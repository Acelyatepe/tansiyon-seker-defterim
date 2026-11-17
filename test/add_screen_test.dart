import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/core/theme/app_theme.dart';
import 'package:tansiyon_seker_defterim/screens/add_screen.dart';

Future<void> mount(WidgetTester tester, {DateTime Function()? now}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: AddScreen(now: now ?? () => DateTime(2026, 9, 24, 12, 30)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byKey(ValueKey(label));
Future<void> save(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Kaydet');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Boş formda alan hataları gösterilir, başarı gösterilmez', (
    tester,
  ) async {
    await mount(tester);
    await save(tester);
    expect(find.text('Bu alanı doldurun.'), findsNWidgets(2));
    expect(find.text('Kayıt eklendi'), findsNothing);
  });

  testWidgets('Tansiyon ilişkisi ve isteğe bağlı nabız doğrulanır', (
    tester,
  ) async {
    await mount(tester);
    await tester.enterText(field('Büyük tansiyon'), '80');
    await tester.enterText(field('Küçük tansiyon'), '90');
    await tester.enterText(field('Nabız (isteğe bağlı)'), '221');
    await save(tester);
    expect(find.text('Büyük tansiyon küçükten büyük olmalı.'), findsOneWidget);
    expect(find.text('30–220 arasında girin.'), findsOneWidget);
    await tester.enterText(field('Büyük tansiyon'), '120');
    await tester.enterText(field('Nabız (isteğe bağlı)'), '');
    await save(tester);
    expect(find.text('Kayıt eklendi'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(field('Büyük tansiyon')).controller!.text,
      isEmpty,
    );
    expect(
      tester.widget<TextFormField>(field('Küçük tansiyon')).controller!.text,
      isEmpty,
    );
    expect(find.text('Bu alanı doldurun.'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Kayıt eklendi'), findsNothing);
  });

  testWidgets(
    'Şeker seçimi, sınır hatası ve başarılı kayıt sonrası sekme korunur',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Şeker'));
      await tester.pump();
      expect(field('Büyük tansiyon'), findsNothing);
      expect(field('Kan şekeri'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: field('Kan şekeri'),
                matching: find.byType(TextField),
              ),
            )
            .keyboardType,
        TextInputType.number,
      );
      await tester.enterText(field('Kan şekeri'), '601');
      await save(tester);
      expect(find.text('20–600 arasında girin.'), findsOneWidget);
      await tester.enterText(field('Kan şekeri'), '100');
      await tester.tap(find.text('Tok'));
      await save(tester);
      expect(find.text('Kayıt eklendi'), findsOneWidget);
      expect(field('Kan şekeri'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(field('Kan şekeri')).controller!.text,
        isEmpty,
      );
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'Tarih/saat geleceği reddeder, geçmişi uygular ve kayıtta şimdiye döner',
    (tester) async {
      var now = DateTime(2026, 9, 24, 12, 30);
      await mount(tester, now: () => now);
      await tester.tap(find.text('Şeker'));
      await tester.pump();
      await tester.ensureVisible(find.textContaining('12:30'));
      await tester.tap(find.textContaining('12:30'));
      await tester.pumpAndSettle();
      final inputs = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(inputs.at(1), '12:31');
      await tester.tap(find.text('Uygula'));
      await tester.pump();
      expect(find.text('Gelecek tarih veya saat seçilemez.'), findsOneWidget);
      await tester.enterText(inputs.at(0), '23.09.2026');
      await tester.tap(find.text('Uygula'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('23 Eylül'), findsOneWidget);
      await tester.enterText(field('Kan şekeri'), '110');
      now = DateTime(2026, 9, 24, 13, 45);
      await save(tester);
      expect(find.textContaining('13:45'), findsOneWidget);
      expect(find.textContaining('24 Eylül'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets('Küçük ekran, büyük yazı ve klavye ile form kaydırılabilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester);
    await tester.ensureVisible(field('Nabız (isteğe bağlı)'));
    await tester.enterText(field('Nabız (isteğe bağlı)'), '70');
    await save(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Bu alanı doldurun.'), findsNWidgets(2));
  });
}
