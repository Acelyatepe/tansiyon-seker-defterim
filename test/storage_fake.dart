import 'package:tansiyon_seker_defterim/services/measurement_store.dart';
import 'package:tansiyon_seker_defterim/services/app_preferences.dart';

class FakeStorage implements MeasurementStorage {
  String? data;
  bool failWrite = false;
  bool failRead = false;
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read failed');
    return data;
  }

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('write failed');
    data = value;
  }
}

AppPreferences seenPreferences() => AppPreferences(
  FakeStorage()..data = '{"version":1,"welcomeSeen":true,"supporter":false}',
);
