const scheduleWeekdays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];

String canonicalScheduleDay(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا');
  const aliases = {
    'الاحد': 'الأحد',
    'sunday': 'الأحد',
    'الاثنين': 'الإثنين',
    'monday': 'الإثنين',
    'الثلاثاء': 'الثلاثاء',
    'tuesday': 'الثلاثاء',
    'الاربعاء': 'الأربعاء',
    'wednesday': 'الأربعاء',
    'الخميس': 'الخميس',
    'thursday': 'الخميس',
  };
  return aliases[normalized] ?? value;
}

class SchedulePeriod {
  final String day, subject;
  final String? teacher;
  final String subjectKey;
  final int number;
  const SchedulePeriod({
    required this.day,
    required this.number,
    required this.subject,
    this.teacher,
    this.subjectKey = 'other',
  });
  factory SchedulePeriod.fromJson(Map<String, dynamic> json) => SchedulePeriod(
    day: canonicalScheduleDay(json['day_of_week'] as String),
    number: (json['period_number'] as num).toInt(),
    subject: json['subject_name'] as String,
    teacher: json['teacher_name'] as String?,
    subjectKey: json['subject_key'] as String? ?? 'other',
  );
  Map<String, dynamic> toJson() => {
    'day_of_week': day,
    'period_number': number,
    'subject_name': subject.trim(),
    'teacher_name': teacher == null || teacher!.trim().isEmpty
        ? null
        : teacher!.trim(),
  };
}
