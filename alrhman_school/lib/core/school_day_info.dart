import 'baghdad_time.dart';

class SchoolDayInfo {
  final String type;
  final String? title;
  final String? notes;
  const SchoolDayInfo({this.type = 'school', this.title, this.notes});
  factory SchoolDayInfo.fromJson(Map<String, dynamic> json) {
    final date =
        DateTime.tryParse(json['date'] as String? ?? '') ?? BaghdadTime.today();
    final weekend =
        date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
    return SchoolDayInfo(
      type: weekend ? 'weekend' : json['day_type'] as String? ?? 'school',
      title: json['day_title'] as String?,
      notes: json['day_notes'] as String?,
    );
  }
  bool get isSchool => type == 'school';
  String get label => type == 'weekend'
      ? 'عطلة نهاية الأسبوع'
      : title ?? (type == 'pause' ? 'إيقاف الدوام' : 'عطلة');
}
