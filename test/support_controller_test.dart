import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tansiyon_seker_defterim/services/app_preferences.dart';
import 'package:tansiyon_seker_defterim/services/rewarded_ads.dart';
import 'package:tansiyon_seker_defterim/services/support_controller.dart';
import 'storage_fake.dart';

class FakeAds implements RewardedAds {
  bool earn = false;
  bool fail = false;
  int calls = 0;
  Completer<void>? wait;
  @override
  Future<void> watch(VoidCallback onEarned) async {
    calls++;
    await wait?.future;
    if (fail) throw StateError('no fill');
    if (earn) {
      onEarned();
      onEarned();
    }
  }

  @override
  Future<void> privacyOptions() async {}
  @override
  void dispose() {}
}

void main() {
  test('Başlatmada reklam çağrısı yok; ödül olmadan rozet verilmez', () async {
    final prefs = AppPreferences(FakeStorage());
    await prefs.load();
    final ads = FakeAds();
    final support = SupportController(prefs, ads);
    expect(ads.calls, 0);
    await support.watch();
    expect(prefs.supporter, false);
    expect(support.busy, false);
  });

  test(
    'Yalnızca ödül callbacki rozet verir ve yeniden açılışta korunur',
    () async {
      final disk = FakeStorage();
      final prefs = AppPreferences(disk);
      await prefs.load();
      await prefs.acknowledgeWelcome();
      final support = SupportController(prefs, FakeAds()..earn = true);
      await support.watch();
      expect(prefs.supporter, true);
      expect(support.message, 'Desteğin için teşekkürler');
      final reopened = AppPreferences(disk);
      await reopened.load();
      expect(reopened.supporter, true);
      expect(reopened.welcomeSeen, true);
    },
  );

  test('Reklam hatası doğru mesajı verir ve beklemeyi sonlandırır', () async {
    final prefs = AppPreferences(FakeStorage());
    await prefs.load();
    final support = SupportController(prefs, FakeAds()..fail = true);
    await support.watch();
    expect(support.message, SupportController.unavailable);
    expect(support.busy, false);
    expect(prefs.supporter, false);
  });

  test('Çift dokunma tek reklam açar, kayıt hatası başarı göstermez', () async {
    final disk = FakeStorage()..failWrite = true;
    final prefs = AppPreferences(disk);
    await prefs.load();
    final ads = FakeAds()
      ..earn = true
      ..wait = Completer<void>();
    final support = SupportController(prefs, ads);
    final first = support.watch();
    await support.watch();
    expect(ads.calls, 1);
    ads.wait!.complete();
    await first;
    expect(prefs.supporter, false);
    expect(support.message, contains('Rozet kaydedilemedi'));
  });
}
