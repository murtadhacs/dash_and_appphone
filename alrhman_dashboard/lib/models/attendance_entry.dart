import '../core/baghdad_time.dart';
import '../core/school_day_info.dart';

/// حالات الحضور في النظام: حاضر، غائب، مجاز (لا توجد حالة "متأخر").
enum PresenceStatus {
  present,
  absent,
  excused;

  static PresenceStatus parse(String? value) => switch (value) {
    'Present' => PresenceStatus.present,
    'Excused' => PresenceStatus.excused,
    _ => PresenceStatus.absent,
  };

  String get label => switch (this) {
    PresenceStatus.present => 'حاضر',
    PresenceStatus.absent => 'غائب',
    PresenceStatus.excused => 'مجاز',
  };
}

/// سطر حضور طالب في يوم واحد (`DailyAttendanceDTO`).
class AttendanceEntry {
  final int studentId;
  final String fullName;
  final PresenceStatus status;

  /// `07:15 AM` أو null.
  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInSource;
  final String? checkOutSource;

  const AttendanceEntry({
    required this.studentId,
    required this.fullName,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.checkInSource,
    this.checkOutSource,
  });

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceEntry(
      studentId: (json['student_id'] as num).toInt(),
      fullName: json['full_name'] as String? ?? '',
      status: PresenceStatus.parse(json['status'] as String?),
      checkInTime: json['check_in_time'] as String?,
      checkOutTime: json['check_out_time'] as String?,
      checkInSource: json['check_in_source'] as String?,
      checkOutSource: json['check_out_source'] as String?,
    );
  }

  int? get checkInMinutes => BaghdadTime.minutesOfDay(checkInTime);
}

/// حضور يوم كامل.
class AttendanceDay {
  final String date;
  final List<AttendanceEntry> _entries;
  final SchoolDayInfo dayInfo;
  const AttendanceDay(
    this.date,
    this._entries, {
    this.dayInfo = const SchoolDayInfo(),
  });
  List<AttendanceEntry> get entries => dayInfo.isSchool ? _entries : const [];

  int count(PresenceStatus s) => entries.where((e) => e.status == s).length;

  /// الطلاب الذين لديهم وقت دخول، الأحدث أولاً.
  List<AttendanceEntry> get arrivals {
    final list = entries.where((e) => e.checkInMinutes != null).toList()
      ..sort((a, b) => b.checkInMinutes!.compareTo(a.checkInMinutes!));
    return list;
  }

  /// كل الطلاب: الحاضرون بترتيب الدخول (الأحدث أولاً)، ثم المجازون، ثم الغائبون.
  List<AttendanceEntry> get ordered {
    int rank(PresenceStatus s) => switch (s) {
      PresenceStatus.present => 0,
      PresenceStatus.excused => 1,
      PresenceStatus.absent => 2,
    };
    final list = List.of(entries);
    list.sort((a, b) {
      final r = rank(a.status).compareTo(rank(b.status));
      if (r != 0) return r;
      if (a.status == PresenceStatus.present) {
        final am = a.checkInMinutes ?? -1;
        final bm = b.checkInMinutes ?? -1;
        final t = bm.compareTo(am);
        if (t != 0) return t;
      }
      return a.fullName.compareTo(b.fullName);
    });
    return list;
  }
}
