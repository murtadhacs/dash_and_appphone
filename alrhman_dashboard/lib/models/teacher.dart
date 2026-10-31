import '../core/school_day_info.dart';

enum TeacherStatus {
  active('active', 'على رأس العمل'),
  onLeave('on_leave', 'في إجازة'),
  transferred('transferred', 'منقول'),
  retired('retired', 'متقاعد');

  final String api;
  final String label;
  const TeacherStatus(this.api, this.label);

  static TeacherStatus parse(String? v) => TeacherStatus.values.firstWhere(
    (s) => s.api == v,
    orElse: () => TeacherStatus.active,
  );
}

/// معلم كما يرجعه `GET /api/admin/teachers`.
class Teacher {
  final int id;
  final String firstName, fatherName, grandfatherName, fullName;

  /// الرقم القياسي `+9647XXXXXXXXX`.
  final String phone;
  final String gender;
  final TeacherStatus status;
  final String? specialization, notes;

  /// رقم المعلم في جهاز البصمة (1 إلى 99)، أو null إن لم يُسجَّل بعد.
  final String? rfidTag;

  const Teacher({
    required this.id,
    required this.firstName,
    required this.fatherName,
    required this.grandfatherName,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.status,
    this.specialization,
    this.notes,
    this.rfidTag,
  });

  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
    id: (j['id'] as num).toInt(),
    firstName: j['first_name'] as String? ?? '',
    fatherName: j['father_name'] as String? ?? '',
    grandfatherName: j['grandfather_name'] as String? ?? '',
    fullName: j['full_name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    gender: j['gender'] as String? ?? 'male',
    status: TeacherStatus.parse(j['status'] as String?),
    specialization: j['specialization'] as String?,
    notes: j['notes'] as String?,
    rfidTag: j['rfid_tag'] as String?,
  );
}

/// ما يُرسل عند الإضافة أو التعديل. PUT يستبدل السجل كله، فكل الحقول تُرسل دائماً،
/// والحقل الاختياري الفارغ يُرسل null ليُمسح.
class TeacherInput {
  final String firstName, fatherName, grandfatherName, phone, gender;
  final TeacherStatus status;
  final String? specialization, notes, rfidTag;

  const TeacherInput({
    required this.firstName,
    required this.fatherName,
    required this.grandfatherName,
    required this.phone,
    required this.gender,
    required this.status,
    this.specialization,
    this.notes,
    this.rfidTag,
  });

  Map<String, dynamic> toJson({int? id}) => {
    'id': ?id,
    'first_name': firstName.trim(),
    'father_name': fatherName.trim(),
    'grandfather_name': grandfatherName.trim(),
    'phone': phone,
    'gender': gender,
    'status': status.api,
    'specialization': _blankToNull(specialization),
    'notes': _blankToNull(notes),
    'rfid_tag': _blankToNull(rfidTag),
  };
}

String? _blankToNull(String? v) =>
    (v == null || v.trim().isEmpty) ? null : v.trim();

/// بصمات معلم في يوم واحد.
class TeacherPunch {
  final int teacherId;
  final String fullName;
  final TeacherStatus status;
  final String? firstPunch, lastPunch;
  final int punchCount;

  /// معلم فعّال لم يبصم في يوم دراسي حتى اليوم: "لم يبصم".
  final bool notPunched;

  const TeacherPunch({
    required this.teacherId,
    required this.fullName,
    required this.status,
    required this.firstPunch,
    required this.lastPunch,
    required this.punchCount,
    required this.notPunched,
  });

  factory TeacherPunch.fromJson(Map<String, dynamic> j) => TeacherPunch(
    teacherId: (j['teacher_id'] as num).toInt(),
    fullName: j['full_name'] as String? ?? '',
    status: TeacherStatus.parse(j['status'] as String?),
    firstPunch: j['first_punch'] as String?,
    lastPunch: j['last_punch'] as String?,
    punchCount: (j['punch_count'] as num?)?.toInt() ?? 0,
    notPunched: j['not_punched'] as bool? ?? false,
  );
}

class TeacherAttendanceDay {
  final String date;
  final SchoolDayInfo dayInfo;
  final bool schoolDay;
  final List<TeacherPunch> entries;

  const TeacherAttendanceDay(
    this.date,
    this.dayInfo,
    this.schoolDay,
    this.entries,
  );

  factory TeacherAttendanceDay.fromJson(Map<String, dynamic> j) =>
      TeacherAttendanceDay(
        j['date'] as String? ?? '',
        SchoolDayInfo.fromJson(j),
        j['school_day'] as bool? ?? true,
        [
          for (final e in j['data'] as List? ?? const [])
            TeacherPunch.fromJson(e as Map<String, dynamic>),
        ],
      );

  int get punched => entries.where((e) => e.punchCount > 0).length;
  int get missing => entries.where((e) => e.notPunched).length;
}
