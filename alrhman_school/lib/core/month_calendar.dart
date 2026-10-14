import '../models/models.dart';
import '../models/holiday.dart';
import 'baghdad_time.dart';

/// حالة خانة يوم في تقويم الحضور.
enum DayState {
  present,
  absent,
  excused,

  /// الجمعة والسبت.
  weekend,
  holiday,

  /// يوم لم يأتِ بعد.
  future,

  /// يوم دراسي مضى بلا سجل (مثلاً قبل تسجيل الطالب).
  noRecord,
}

class CalendarCell {
  final DateTime date;
  final DayState state;
  final MonthlyRecord? record;
  final HolidayDay? holiday;
  const CalendarCell(this.date, this.state, [this.record, this.holiday]);
}

/// خانات شهر كامل بترتيب أعمدة (الأحد … السبت)، مع null للخانات الفارغة قبل اليوم الأول.
List<CalendarCell?> buildMonthGrid(
  DateTime month,
  List<MonthlyRecord> records,
  DateTime today, {
  List<HolidayDay> holidays = const [],
}) {
  final first = DateTime(month.year, month.month);
  final days = DateTime(month.year, month.month + 1, 0).day;
  final byDay = {for (final r in records) r.date.day: r};

  // DateTime.weekday: الإثنين=1 … الأحد=7 ← عمود الأحد = 0.
  final leading = first.weekday % 7;

  return [
    for (var i = 0; i < leading; i++) null,
    for (var d = 1; d <= days; d++)
      () {
        final date = DateTime(month.year, month.month, d);
        if (BaghdadTime.isWeekend(date)) {
          return CalendarCell(date, DayState.weekend);
        }
        final holiday = holidays
            .where((h) => BaghdadTime.sameDay(h.date, date))
            .firstOrNull;
        if (holiday != null) {
          return CalendarCell(date, DayState.holiday, null, holiday);
        }
        final record = byDay[d];
        if (record != null) {
          return CalendarCell(date, switch (record.status) {
            PresenceStatus.present => DayState.present,
            PresenceStatus.absent => DayState.absent,
            PresenceStatus.excused => DayState.excused,
          }, record);
        }
        if (date.isAfter(today)) return CalendarCell(date, DayState.future);
        return CalendarCell(date, DayState.noRecord);
      }(),
  ];
}

/// إحصاء الشهر من السجلات نفسها التي يعرضها التقويم.
class MonthStats {
  final int present;
  final int absent;
  final int excused;

  const MonthStats(this.present, this.absent, this.excused);

  factory MonthStats.of(List<MonthlyRecord> records) => MonthStats(
    records.where((r) => r.status == PresenceStatus.present).length,
    records.where((r) => r.status == PresenceStatus.absent).length,
    records.where((r) => r.status == PresenceStatus.excused).length,
  );

  int get schoolDays => present + absent + excused;

  /// نسبة الحضور من الأيام الدراسية المسجّلة، أو null إن لم توجد أيام.
  int? get rate =>
      schoolDays == 0 ? null : (present * 100 / schoolDays).round();
}
