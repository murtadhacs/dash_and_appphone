/// كل تواريخ النظام بتوقيت بغداد (UTC+03:00 بلا توقيت صيفي).
/// "اليوم" هو يوم بغداد لا يوم الهاتف.
class BaghdadTime {
  BaghdadTime._();

  /// للاختبارات: لتثبيت "الآن".
  static DateTime Function() clock = DateTime.now;

  /// لحظة زمنية ← ساعة بغداد كـ DateTime محلي بلا منطقة.
  static DateTime fromInstant(DateTime instant) {
    final b = instant.toUtc().add(const Duration(hours: 3));
    return DateTime(b.year, b.month, b.day, b.hour, b.minute, b.second);
  }

  static DateTime now() => fromInstant(clock());

  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// `YYYY-MM-DD`
  static String apiDate(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// `YYYY-MM`
  static String apiMonth(DateTime d) => '${d.year}-${_two(d.month)}';

  static DateTime parseDate(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// الجمعة والسبت عطلة؛ الأسبوع الدراسي من الأحد إلى الخميس.
  static bool isWeekend(DateTime d) =>
      d.weekday == DateTime.friday || d.weekday == DateTime.saturday;

  static const monthNames = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  /// الاثنين=1 … الأحد=7 (كما في Dart).
  static const weekdayNames = {
    DateTime.sunday: 'الأحد',
    DateTime.monday: 'الإثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
    DateTime.saturday: 'السبت',
  };

  static String monthTitle(DateTime d) =>
      '${monthNames[d.month - 1]} ${d.year}';

  /// "الأحد 5 تشرين الأول"
  static String dayTitle(DateTime d) =>
      '${weekdayNames[d.weekday]} ${d.day} ${monthNames[d.month - 1]}';

  /// وقت منذ [t] بالعربية: "الآن"، "قبل 5 دقائق"، "أمس 08:30"...
  static String relative(DateTime t) {
    final n = now();
    final diff = n.difference(t);
    final hhmm = '${_two(t.hour)}:${_two(t.minute)}';
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} دقيقة';
    if (sameDay(n, t)) return 'اليوم $hhmm';
    if (sameDay(n.subtract(const Duration(days: 1)), t)) return 'أمس $hhmm';
    return '${t.day} ${monthNames[t.month - 1]} $hhmm';
  }

  /// `07:15 AM` ← "07:15 ص".
  static String arabicTime(String? hhmmAmPm) {
    if (hhmmAmPm == null) return '—';
    return hhmmAmPm.replaceAll('AM', 'ص').replaceAll('PM', 'م');
  }
}
