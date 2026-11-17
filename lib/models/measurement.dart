import '../core/validation/measurement_validators.dart';

enum MeasurementType { bloodPressure, bloodSugar }

class Measurement {
  const Measurement({
    required this.id,
    required this.type,
    required this.dateTime,
    required this.value,
    this.diastolic,
    this.pulse,
    this.fasting = true,
  });

  final String id;
  final MeasurementType type;
  final DateTime dateTime;
  final int value;
  final int? diastolic;
  final int? pulse;
  final bool fasting;
  bool get isPressure => type == MeasurementType.bloodPressure;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'dateTime': dateTime.toUtc().toIso8601String(),
    'value': value,
    'diastolic': diastolic,
    'pulse': pulse,
    'fasting': fasting,
  };

  factory Measurement.fromJson(Map<String, dynamic> json) {
    final record = Measurement(
      id: json['id'] as String,
      type: MeasurementType.values.byName(json['type'] as String),
      dateTime: DateTime.parse(json['dateTime'] as String).toLocal(),
      value: json['value'] as int,
      diastolic: json['diastolic'] as int?,
      pulse: json['pulse'] as int?,
      fasting: json['fasting'] as bool,
    );
    final invalid = record.isPressure
        ? MeasurementValidators.systolic(
                    '${record.value}',
                    '${record.diastolic}',
                  ) !=
                  null ||
              MeasurementValidators.diastolic(record.diastolic?.toString()) !=
                  null ||
              MeasurementValidators.pulse(record.pulse?.toString()) != null
        : MeasurementValidators.glucose('${record.value}') != null;
    if (record.id.isEmpty || invalid) {
      throw const FormatException('Geçersiz kayıt');
    }
    return record;
  }
}
