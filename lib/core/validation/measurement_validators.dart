/// Yalnızca giriş doğrulaması yapar; tıbbi değerlendirme içermez.
abstract final class MeasurementValidators {
  static String? _range(
    String? value,
    int min,
    int max, {
    bool optional = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return optional ? null : 'Bu alanı doldurun.';
    final number = RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
    if (number == null) return 'Tam sayı girin.';
    if (number < min || number > max) return '$min–$max arasında girin.';
    return null;
  }

  static String? systolic(String? value, String diastolic) {
    final error = _range(value, 50, 260);
    if (error != null) return error;
    if (_range(diastolic, 30, 160) == null &&
        int.parse(value!.trim()) <= int.parse(diastolic.trim())) {
      return 'Büyük tansiyon küçükten büyük olmalı.';
    }
    return null;
  }

  static String? diastolic(String? value) => _range(value, 30, 160);
  static String? pulse(String? value) => _range(value, 30, 220, optional: true);
  static String? glucose(String? value) => _range(value, 20, 600);

  static DateTime? parseDateTime(String date, String time) {
    if (!RegExp(r'^\d{2}\.\d{2}\.\d{4}$').hasMatch(date) ||
        !RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      return null;
    }
    final d = date.split('.').map(int.parse).toList();
    final t = time.split(':').map(int.parse).toList();
    if (d[2] < 1 || t[0] > 23 || t[1] > 59) return null;
    final result = DateTime(d[2], d[1], d[0], t[0], t[1]);
    return result.year == d[2] && result.month == d[1] && result.day == d[0]
        ? result
        : null;
  }

  static String? dateTime(DateTime? value, DateTime now) {
    if (value == null) return 'Geçerli tarih ve saat girin.';
    if (value.isAfter(now)) return 'Gelecek tarih veya saat seçilemez.';
    return null;
  }
}
