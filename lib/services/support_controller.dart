import 'package:flutter/foundation.dart';
import 'app_preferences.dart';
import 'rewarded_ads.dart';

class SupportController extends ChangeNotifier {
  SupportController(this.preferences, this.ads);
  final AppPreferences preferences;
  final RewardedAds ads;
  bool busy = false;
  bool _disposed = false;
  String? message;
  static const unavailable = 'Şu an reklam bulunamadı, sonra tekrar dene';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> watch() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    Future<void>? rewardSave;
    Object? saveError;
    try {
      await ads.watch(() {
        rewardSave ??= preferences.awardSupporter().catchError((
          Object error,
          StackTrace stack,
        ) {
          saveError = error;
          logAdFailure(error, stack);
        });
      });
      await rewardSave;
      if (rewardSave != null) {
        message = saveError == null
            ? 'Desteğin için teşekkürler'
            : 'Rozet kaydedilemedi. Lütfen sonra tekrar deneyin.';
      }
    } catch (error, stack) {
      logAdFailure(error, stack);
      await rewardSave;
      message = rewardSave != null && saveError == null
          ? 'Desteğin için teşekkürler'
          : unavailable;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> privacyOptions() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await ads.privacyOptions();
      message = 'Reklam gizlilik tercihleri kontrol edildi.';
    } catch (error, stack) {
      logAdFailure(error, stack);
      message = 'Gizlilik tercihleri açılamadı. Lütfen tekrar deneyin.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ads.dispose();
    super.dispose();
  }
}
