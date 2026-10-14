import '../core/school_day_info.dart';

/// أرقام اليوم من `GET /api/admin/dashboard`.
class DashboardStats {
  final String date;
  final SchoolDayInfo dayInfo;
  final int totalStudents;
  final int totalParents;
  final int presentToday;
  final int excusedToday;
  final int absentToday;

  const DashboardStats({
    required this.date,
    this.dayInfo = const SchoolDayInfo(),
    required this.totalStudents,
    required this.totalParents,
    required this.presentToday,
    required this.excusedToday,
    required this.absentToday,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    final info = SchoolDayInfo.fromJson(json);
    int n(String k) => (d[k] as num?)?.toInt() ?? 0;
    return DashboardStats(
      date: json['date'] as String? ?? '',
      dayInfo: info,
      totalStudents: n('total_students'),
      totalParents: n('total_parents'),
      presentToday: info.isSchool ? n('present_today') : 0,
      excusedToday: info.isSchool ? n('excused_today') : 0,
      absentToday: info.isSchool ? n('absent_today') : 0,
    );
  }

  /// نسبة من إجمالي الطلاب (0..100)، أو 0 إن لم يوجد طلاب.
  double percentOf(int value) =>
      totalStudents == 0 ? 0 : value * 100 / totalStudents;
}
