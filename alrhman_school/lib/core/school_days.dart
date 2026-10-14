import '../models/models.dart';

/// أيام الأسبوع الدراسي بالترتيب: مفتاح ثابت + الاسم المعروض.
const schoolDays = [
  (key: 'sunday', name: 'الأحد'),
  (key: 'monday', name: 'الإثنين'),
  (key: 'tuesday', name: 'الثلاثاء'),
  (key: 'wednesday', name: 'الأربعاء'),
  (key: 'thursday', name: 'الخميس'),
];

/// يحوّل اسم اليوم كما خزّنته المدرسة إلى مفتاح ثابت، أو null إن لم يُعرف.
/// يقبل العربية بهمزة أو بدونها، والإنجليزية بأي حالة أحرف.
String? dayKeyOf(String stored) {
  final s = stored.trim().toLowerCase().replaceAll(RegExp('[أإآ]'), 'ا');
  const map = {
    'الاحد': 'sunday',
    'sunday': 'sunday',
    'الاثنين': 'monday',
    'monday': 'monday',
    'الثلاثاء': 'tuesday',
    'tuesday': 'tuesday',
    'الاربعاء': 'wednesday',
    'wednesday': 'wednesday',
    'الخميس': 'thursday',
    'thursday': 'thursday',
  };
  return map[s];
}

/// مفتاح يوم الأسبوع لتاريخ (DateTime.weekday)، أو null للجمعة والسبت.
String? dayKeyOfWeekday(int weekday) => switch (weekday) {
  DateTime.sunday => 'sunday',
  DateTime.monday => 'monday',
  DateTime.tuesday => 'tuesday',
  DateTime.wednesday => 'wednesday',
  DateTime.thursday => 'thursday',
  _ => null,
};

/// يجمّع حصص `GET /api/mobile/schedule` لكل طالب ثم لكل يوم.
///
/// الأيام المعروفة تأتي بترتيب الأسبوع الدراسي؛ الأيام غير المعروفة (أسماء
/// أدخلتها المدرسة بطريقة أخرى) تُلحق بعدها بالترتيب الذي وصلت به.
Map<int, List<DaySchedule>> groupSchedule(List<dynamic> entries) {
  final perStudent =
      <int, Map<String, ({String name, List<ClassPeriod> periods})>>{};

  for (final raw in entries) {
    final e = raw as Map<String, dynamic>;
    final studentId = (e['student_id'] as num).toInt();
    final storedDay = e['day_of_week'] as String? ?? '';
    final key = dayKeyOf(storedDay) ?? storedDay;
    final name =
        schoolDays.where((d) => d.key == key).firstOrNull?.name ?? storedDay;

    final days = perStudent.putIfAbsent(studentId, () => {});
    days
        .putIfAbsent(key, () => (name: name, periods: <ClassPeriod>[]))
        .periods
        .add(
          ClassPeriod(
            periodNumber: (e['period_number'] as num).toInt(),
            subject: e['subject_name'] as String? ?? '',
            subjectKey: e['subject_key'] as String? ?? 'other',
            teacher: e['teacher_name'] as String? ?? '',
          ),
        );
  }

  DaySchedule toDay(String key, ({String name, List<ClassPeriod> periods}) d) =>
      DaySchedule(
        dayKey: key,
        dayName: d.name,
        periods: d.periods
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber)),
      );

  return {
    for (final entry in perStudent.entries)
      entry.key: [
        // الأيام المعروفة بترتيب الأسبوع الدراسي...
        for (final day in schoolDays)
          if (entry.value.containsKey(day.key))
            toDay(day.key, entry.value[day.key]!),
        // ...ثم غير المعروفة بترتيب وصولها (Map يحفظ ترتيب الإدراج).
        for (final d in entry.value.entries)
          if (!schoolDays.any((x) => x.key == d.key)) toDay(d.key, d.value),
      ],
  };
}
