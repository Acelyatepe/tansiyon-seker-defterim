import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/diagnostics/app_log.dart';

abstract interface class RewardedAds {
  Future<void> watch(VoidCallback onEarned);
  Future<void> privacyOptions();
  void dispose();
}

/// Hiçbir SDK çağrısı kurucuda veya uygulama açılışında yapılmaz.
class GoogleRewardedAds implements RewardedAds {
  bool _disposed = false;
  static bool _initialized = false;
  RewardedAd? _ad;

  Future<void> _consent() async {
    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!update.isCompleted) update.complete();
      },
      (error) {
        if (!update.isCompleted) {
          update.completeError(
            StateError('UMP ${error.errorCode}: ${error.message}'),
          );
        }
      },
    );
    await update.future.timeout(const Duration(seconds: 20));
    if (_disposed) throw StateError('Reklam isteği iptal edildi');
    FormError? formError;
    await ConsentForm.loadAndShowConsentFormIfRequired(
      (error) => formError = error,
    );
    if (formError != null) {
      throw StateError('UMP ${formError!.errorCode}: ${formError!.message}');
    }
    if (!await ConsentInformation.instance.canRequestAds()) {
      throw StateError('Reklam isteğine izin verilmedi');
    }
  }

  @override
  Future<void> watch(VoidCallback onEarned) async {
    await _consent();
    if (_disposed) return;
    if (!_initialized) {
      await MobileAds.instance.initialize().timeout(
        const Duration(seconds: 20),
      );
      _initialized = true;
    }
    if (_disposed) return;
    final config =
        jsonDecode(await rootBundle.loadString('assets/config/admob.json'))
            as Map<String, dynamic>;
    final production = kReleaseMode && config['useProductionAds'] == true;
    final id =
        config[production
                ? 'androidProductionRewardedId'
                : 'androidTestRewardedId']
            as String;
    if (id.isEmpty) throw StateError('Ödüllü reklam ID eksik');
    final loaded = Completer<RewardedAd>();
    var expired = false;
    try {
      await RewardedAd.load(
        adUnitId: id,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (expired || _disposed) {
              ad.dispose();
              return;
            }
            if (!loaded.isCompleted) loaded.complete(ad);
          },
          onAdFailedToLoad: (error) {
            if (!loaded.isCompleted) {
              loaded.completeError(
                StateError('AdMob ${error.code}: ${error.message}'),
              );
            }
          },
        ),
      );
      final ad = await loaded.future.timeout(const Duration(seconds: 30));
      if (_disposed) {
        ad.dispose();
        return;
      }
      _ad = ad;
      final closed = Completer<void>();
      var rewarded = false;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _ad = null;
          if (!closed.isCompleted) closed.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _ad = null;
          if (!closed.isCompleted) {
            closed.completeError(
              StateError('AdMob gösterim ${error.code}: ${error.message}'),
            );
          }
        },
      );
      await ad.show(
        onUserEarnedReward: (_, _) {
          if (!rewarded) {
            rewarded = true;
            onEarned();
          }
        },
      );
      await closed.future;
    } finally {
      expired = true;
      _ad?.dispose();
      _ad = null;
    }
  }

  @override
  Future<void> privacyOptions() async {
    // Kullanıcının bu seçeneğe dokunması dışında UMP başlatılmaz.
    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!update.isCompleted) update.complete();
      },
      (error) {
        if (!update.isCompleted) {
          update.completeError(
            StateError('UMP ${error.errorCode}: ${error.message}'),
          );
        }
      },
    );
    await update.future.timeout(const Duration(seconds: 20));
    if (_disposed) return;
    final requirement = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    if (requirement != PrivacyOptionsRequirementStatus.required) return;
    FormError? failure;
    await ConsentForm.showPrivacyOptionsForm((error) => failure = error);
    if (failure != null) {
      throw StateError('UMP ${failure!.errorCode}: ${failure!.message}');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ad?.dispose();
  }
}

void logAdFailure(Object error, StackTrace stack) =>
    logFailure('Ödüllü reklam', error, stack);
