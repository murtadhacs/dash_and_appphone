import 'baghdad_time.dart';

bool isSchoolDay(DateTime date) =>
    date.weekday != DateTime.friday && date.weekday != DateTime.saturday;

class AttendancePolicy {
  final DateTime date;
  final DateTime now;
  AttendancePolicy(this.date, {DateTime? baghdadNow})
    : now = baghdadNow ?? BaghdadTime.now();
  bool get weekend => !isSchoolDay(date);
  bool get awaitingArrival =>
      !weekend &&
      date.year == now.year &&
      date.month == now.month &&
      date.day == now.day &&
      now.hour * 60 + now.minute < 571;
  bool get hideAbsence => weekend || awaitingArrival;
}

List<DateTime> leaveSchoolDays(DateTime start, DateTime end) => [
  for (
    var d = DateTime(start.year, start.month, start.day);
    !d.isAfter(end);
    d = DateTime(d.year, d.month, d.day + 1)
  )
    if (isSchoolDay(d)) d,
];

DateTime nextSchoolDay(DateTime date) {
  var next = DateTime(date.year, date.month, date.day + 1);
  while (!isSchoolDay(next)) {
    next = DateTime(next.year, next.month, next.day + 1);
  }
  return next;
}
