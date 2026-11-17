import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/diagnostics/app_log.dart';
import 'measurement_store.dart';

class DevicePreferencesStorage implements MeasurementStorage {
  @override
  Future<String?> read() =>
      DeviceMeasurementStorage.channel.invokeMethod<String>('readPreferences');

  @override
  Future<void> write(String data) =>
      DeviceMeasurementStorage.channel.invokeMethod<void>(
        'writePreferences',
        data,
      );
}

class AppPreferences extends ChangeNotifier {
  AppPreferences(this.storage);

  final MeasurementStorage storage;

  bool welcomeSeen = false;
  bool supporter = false;

  bool _loaded = false;
  bool _disposed = false;

  Future<void> _pending = Future.value();

  Future<void> load() async {
    if (_loaded) return;

    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final raw = await storage
            .read()
            .timeout(const Duration(seconds: 2));

        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);

          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Tercih verisi geçersiz');
          }

          if (decoded['version'] != 1) {
            throw const FormatException(
              'Tercih sürümü desteklenmiyor',
            );
          }

          welcomeSeen = decoded['welcomeSeen'] == true;
          supporter = decoded['supporter'] == true;
        }

        _loaded = true;
        return;
      } catch (error, stack) {
        lastError = error;
        lastStack = stack;

        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
        }
      }
    }

    logFailure(
      'Tercihleri yükleme',
      lastError ?? StateError('Bilinmeyen hata'),
      lastStack ?? StackTrace.current,
    );

    Error.throwWithStackTrace(
      lastError ?? StateError('Tercihler yüklenemedi'),
      lastStack ?? StackTrace.current,
    );
  }

  Future<void> acknowledgeWelcome() => _save(welcome: true);

  Future<void> awardSupporter() => _save(award: true);

  Future<void> _save({
    bool welcome = false,
    bool award = false,
  }) {
    final operation = _pending.then((_) async {
      if (!_loaded) {
        throw StateError('Tercihler yüklenmedi');
      }

      final nextWelcome = welcomeSeen || welcome;
      final nextSupporter = supporter || award;

      await storage.write(
        jsonEncode({
          'version': 1,
          'welcomeSeen': nextWelcome,
          'supporter': nextSupporter,
        }),
      );

      welcomeSeen = nextWelcome;
      supporter = nextSupporter;

      if (!_disposed) {
        notifyListeners();
      }
    });

    _pending = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        logFailure('Tercihleri kaydetme', error, stack);
      },
    );

    return operation;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}