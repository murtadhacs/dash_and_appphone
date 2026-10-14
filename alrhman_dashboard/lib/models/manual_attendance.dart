/// Form data only. The API adapter will map these values to the server contract.
class ManualAttendanceDraft {
  final int studentId;
  final DateTime date;
  final String kind, time, notes;
  final bool notify;
  const ManualAttendanceDraft({
    required this.studentId,
    required this.date,
    required this.kind,
    required this.time,
    required this.notify,
    required this.notes,
  });
}

/// Identity must come from the server's dry-run response before committing.
class ManualAttendancePreview {
  final String studentName;
  final String? grade, section;
  const ManualAttendancePreview({
    required this.studentName,
    this.grade,
    this.section,
  });
}
