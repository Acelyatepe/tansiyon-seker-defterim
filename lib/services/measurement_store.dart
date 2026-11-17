import 'dart:convert';

import '../core/diagnostics/app_log.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/measurement.dart';

abstract interface class MeasurementStorage {
  Future<String?> read();
  Future<void> write(String data);
}

/// Android'in uygulamaya özel alanında atomik dosya okuma/yazma.
class DeviceMeasurementStorage implements MeasurementStorage {
  static const channel =
      MethodChannel('com.tansiyonsekerdefterim.app/storage');

  @override
  Future<String?> read() =>
      channel.invokeMethod<String>('read');

  @override
  Future<void> write(String data) =>
      channel.invokeMethod<void>('write', data);
}

class MeasurementStore extends ChangeNotifier {
  MeasurementStore(
    this.storage, {
    this.loadTimeout = const Duration(seconds: 5),
  });

  final Duration loadTimeout;
  Future<void>? _loading;
  final MeasurementStorage storage;

  List<Measurement> _records = [];
  bool _loaded = false;
  bool _disposed = false;

  Future<void> _pending = Future.value();

  List<Measurement> get records =>
      List.unmodifiable(_records);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() {
    if (_loaded) return Future.value();

    return _loading ??=
        _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final raw =
          await storage.read().timeout(loadTimeout);

      if (raw == null) {
        _records = [];
      } else {
        final document =
            jsonDecode(raw) as Map<String, dynamic>;

        if (document['version'] != 1) {
          throw const FormatException(
            'Bilinmeyen veri sürümü',
          );
        }

        final records =
            (document['records'] as List)
                .map(
                  (v) => Measurement.fromJson(
                    v as Map<String, dynamic>,
                  ),
                )
                .toList();

        if (records.map((r) => r.id).toSet().length !=
            records.length) {
          throw const FormatException(
            'Tekrarlanan kayıt kimliği',
          );
        }

        _records = records;
      }

      _loaded = true;

      if (!_disposed) {
        notifyListeners();
      }
    } catch (error, stack) {
      logFailure(
        'Yerel kayıtları yükleme',
        error,
        stack,
      );
      rethrow;
    }
  }

  Future<void> _change(
    List<Measurement> Function() change,
  ) {
    final operation = _pending.then((_) async {
      if (!_loaded) {
        throw StateError(
          'Kayıtlar henüz yüklenmedi',
        );
      }

      final next = change();

      await storage.write(
        jsonEncode({
          'version': 1,
          'records':
              next.map((r) => r.toJson()).toList(),
        }),
      );

      _records = next;

      if (!_disposed) {
        notifyListeners();
      }
    });

    _pending = operation.then<void>(
      (_) {},
      onError: (
        Object error,
        StackTrace stack,
      ) {
        logFailure(
          'Yerel kaydı değiştirme',
          error,
          stack,
        );
      },
    );

    return operation;
  }

  Future<void> add(Measurement record) =>
      _change(() {
        if (_records.any(
          (r) => r.id == record.id,
        )) {
          throw StateError('Kayıt zaten var');
        }

        return [..._records, record];
      });

  Future<void> update(Measurement record) =>
      _change(() {
        if (!_records.any(
          (r) => r.id == record.id,
        )) {
          throw StateError('Kayıt bulunamadı');
        }

        return [
          for (final current in _records)
            current.id == record.id
                ? record
                : current,
        ];
      });

  Future<void> delete(String id) =>
    _change(
      () => _records
          .where((r) => r.id != id)
          .toList(),
    );

Future<void> deleteAll() =>
    _change(() => []);
}
