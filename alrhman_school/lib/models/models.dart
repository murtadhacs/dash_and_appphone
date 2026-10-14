import '../core/baghdad_time.dart';

/// حالات الحضور في النظام. `absent` تشمل طالباً لم يصل بعد اليوم.
enum PresenceStatus {
  present,
  absent,
  excused;

  static PresenceStatus parse(String? value) => switch (value) {
    'Present' => PresenceStatus.present,
    'Excused' => PresenceStatus.excused,
    _ => PresenceStatus.absent,
  };
}

/// بيانات ولي الأمر من استجابة الدخول.
class ParentProfile {
  final int id;
  final String name;

  /// بالصيغة القياسية `+9647XXXXXXXXX`.
  final String phone;

  const ParentProfile({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) => ParentProfile(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  /// `+9647701234567` ← `07701234567`.
  String get localPhone =>
      phone.startsWith('+964') ? '0${phone.substring(4)}' : phone;
}

/// حضور اليوم لطالب (`DailyAttendanceDTO`).
class TodayAttendance {
  final PresenceStatus status;

  /// `07:15 AM` أو null.
  final String? checkIn;
  final String? checkOut;

  const TodayAttendance({required this.status, this.checkIn, this.checkOut});

  factory TodayAttendance.fromJson(Map<String, dynamic> json) =>
      TodayAttendance(
        status: PresenceStatus.parse(json['status'] as String?),
        checkIn: json['check_in_time'] as String?,
        checkOut: json['check_out_time'] as String?,
      );
}

/// ابن ولي الأمر (`MobileStudent`) مع حضور اليوم إن توفّر.
class Student {
  final int id;
  final String name;

  /// قد يكون نصاً فارغاً.
  final String grade;
  final String section;
  final String avatarUrl;
  final TodayAttendance? today;

  const Student({
    required this.id,
    required this.name,
    this.grade = '',
    this.section = '',
    this.avatarUrl = '',
    this.today,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: (json['id'] as num).toInt(),
    name: json['full_name'] as String? ?? '',
    grade: json['grade'] as String? ?? '',
    section: json['section'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String? ?? '',
  );

  Student withToday(TodayAttendance? t) => Student(
    id: id,
    name: name,
    grade: grade,
    section: section,
    avatarUrl: avatarUrl,
    today: t,
  );

  String get firstName => name.split(' ').first;

  String get avatarLetter => name.isEmpty ? '؟' : name.substring(0, 1);

  /// وصف قصير لحالة اليوم (لقائمة تبديل الأبناء).
  String get todayLabel => switch (today?.status) {
    PresenceStatus.present => 'حاضر اليوم',
    PresenceStatus.excused => 'مجاز اليوم',
    PresenceStatus.absent => 'لم يُسجَّل حضوره',
    null => '—',
  };

  /// "G3 — A"، أو ما توفّر منهما.
  String get classLabel {
    if (grade.isEmpty && section.isEmpty) return 'لم يُحدَّد الصف';
    if (section.isEmpty) return grade;
    if (grade.isEmpty) return section;
    return '$grade — $section';
  }
}

/// يوم دراسي في سجل الشهر (`MonthlyRecord`).
class MonthlyRecord {
  final DateTime date;
  final PresenceStatus status;
  final String? checkIn;
  final String? checkOut;

  const MonthlyRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
  });

  factory MonthlyRecord.fromJson(Map<String, dynamic> json) => MonthlyRecord(
    date: BaghdadTime.parseDate(json['date'] as String),
    status: PresenceStatus.parse(json['status'] as String?),
    checkIn: json['check_in_time'] as String?,
    checkOut: json['check_out_time'] as String?,
  );
}

/// حصة في الجدول الأسبوعي. لا يوفّر الخادم أوقات الحصص.
class ClassPeriod {
  final int periodNumber;
  final String subject;
  final String subjectKey;

  /// قد يكون نصاً فارغاً.
  final String teacher;

  const ClassPeriod({
    required this.periodNumber,
    required this.subject,
    this.subjectKey = 'other',
    this.teacher = '',
  });
}

/// حصص يوم واحد لطالب.
class DaySchedule {
  /// مفتاح ثابت (`sunday` … `thursday`) أو اسم اليوم كما خزّنته المدرسة إن لم يُعرف.
  final String dayKey;
  final String dayName;
  final List<ClassPeriod> periods;

  const DaySchedule({
    required this.dayKey,
    required this.dayName,
    required this.periods,
  });
}

/// نوع الإشعار، مستنتَج من عنوانه (لا يرسل الخادم نوعاً).
enum NotificationCategory { checkIn, checkOut, absence, general }

/// إشعار من سجل ولي الأمر (`Notification`).
class AppNotification {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        // RFC 3339 بإزاحة +03:00؛ نحوّله إلى ساعة بغداد.
        createdAt: BaghdadTime.fromInstant(
          DateTime.parse(json['created_at'] as String),
        ),
      );

  AppNotification markedRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    isRead: true,
    createdAt: createdAt,
  );

  NotificationCategory get category {
    if (title.contains('دخول')) return NotificationCategory.checkIn;
    if (title.contains('خروج')) return NotificationCategory.checkOut;
    if (title.contains('غياب')) return NotificationCategory.absence;
    return NotificationCategory.general;
  }
}

/// إعلان مدرسي (`Banner`).
class SchoolBanner {
  final int id;
  final String title;

  /// رابط كامل جاهز للعرض (المسارات النسبية تُكمَّل بعنوان الخادم).
  final String imageUrl;
  final String actionLink;

  const SchoolBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.actionLink,
  });
}

enum AppTab { home, attendance, schedule, notifications, settings }
