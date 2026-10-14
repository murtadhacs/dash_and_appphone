import 'package:intl/intl.dart';

/// كل تواريخ النظام بتوقيت بغداد (UTC+03:00 بلا توقيت صيفي).
class BaghdadTime {
  BaghdadTime._();
  static DateTime Function() clock = DateTime.now;

  static final _apiDate = DateFormat('yyyy-MM-dd', 'en');

  /// "الآن" بتوقيت بغداد، مُمثَّل كـ DateTime بدون منطقة (القيم تطابق ساعة بغداد).
  static DateTime now() {
    final utc = clock().toUtc().add(const Duration(hours: 3));
    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
    );
  }

  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  static String apiDate(DateTime d) => _apiDate.format(d);

  static DateTime parseApiDate(String s) => _apiDate.parseStrict(s);

  /// يحوّل `07:15 AM` إلى دقائق منذ منتصف الليل للترتيب، أو null.
  static int? minutesOfDay(String? hhmmAmPm) {
    if (hhmmAmPm == null) return null;
    final m = RegExp(r'^(\d{2}):(\d{2}) (AM|PM)$').firstMatch(hhmmAmPm.trim());
    if (m == null) return null;
    var h = int.parse(m.group(1)!) % 12;
    if (m.group(3) == 'PM') h += 12;
    return h * 60 + int.parse(m.group(2)!);
  }

  /// `2026-09-21 07:00:00` ← من الخادم، يعاد كنص مقروء `2026-09-21 07:00`.
  static String shortDateTime(String serverValue) {
    return serverValue.length >= 16
        ? serverValue.substring(0, 16)
        : serverValue;
  }
}
