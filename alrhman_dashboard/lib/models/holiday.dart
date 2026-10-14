class Holiday {
  final int id;
  final String kind, title, startDate;
  final String? endDate, notes;
  final bool active;
  const Holiday({
    required this.id,
    required this.kind,
    required this.title,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.active,
  });
  factory Holiday.fromJson(Map<String, dynamic> j) => Holiday(
    id: (j['id'] as num).toInt(),
    kind: j['kind'] as String,
    title: j['title'] as String,
    startDate: j['start_date'] as String,
    endDate: j['end_date'] as String?,
    notes: j['notes'] as String?,
    active: j['active'] == true,
  );
}
