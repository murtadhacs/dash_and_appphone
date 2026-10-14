class ScheduleClass {
  final String grade, section;
  final int studentCount, periodCount, dayCount;
  const ScheduleClass({
    required this.grade,
    required this.section,
    required this.studentCount,
    required this.periodCount,
    required this.dayCount,
  });
  factory ScheduleClass.fromJson(Map<String, dynamic> j) => ScheduleClass(
    grade: j['grade'] as String,
    section: j['section'] as String,
    studentCount: (j['student_count'] as num).toInt(),
    periodCount: (j['period_count'] as num).toInt(),
    dayCount: (j['day_count'] as num).toInt(),
  );
  String get label => '$grade — $section';
}
