class HolidayDay {
  final DateTime date;
  final String kind, title;
  final String? notes;
  const HolidayDay({
    required this.date,
    required this.kind,
    required this.title,
    this.notes,
  });
  factory HolidayDay.fromJson(Map<String, dynamic> j) => HolidayDay(
    date: DateTime.parse(j['date'] as String),
    kind: j['kind'] as String,
    title: j['title'] as String,
    notes: j['notes'] as String?,
  );
}
