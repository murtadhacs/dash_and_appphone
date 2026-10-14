import 'dart:typed_data';
import '../core/school_day_info.dart';
import '../models/holiday.dart';
import '../models/activity_log.dart';
import '../models/broadcast.dart';

import '../core/baghdad_time.dart';
import '../models/school_banner.dart';
import '../models/attendance_entry.dart';
import '../models/dashboard_stats.dart';
import '../models/device.dart';
import '../models/student.dart';
import '../models/schedule_class.dart';
import '../models/schedule_period.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_store.dart';

String? _nonEmpty(String? v) => (v == null || v.isEmpty) ? null : v;

/// كل عمليات لوحة الإدارة (`/api/admin/*`) كما في عقد الـ API.
class AdminApi {
  AdminApi(this._client, this._store);

  final ApiClient _client;
  final TokenStore _store;

  String? username;

  bool get hasSession => _client.token != null;

  Future<ActivityLogPage> activityLog({int? before}) async =>
      ActivityLogPage.fromJson(
        await _client.getJson(
          '/api/admin/activity-log',
          query: before == null ? null : {'before': '$before'},
        ),
      );

  Future<BroadcastPage> broadcasts({int? before}) async =>
      BroadcastPage.fromJson(
        await _client.getJson(
          '/api/admin/broadcasts',
          query: before == null ? null : {'before': '$before'},
        ),
      );

  Future<int> sendBroadcast(
    BroadcastDraft draft, {
    required bool dryRun,
  }) async {
    final json = await _client.postJson(
      '/api/admin/broadcasts',
      draft.toJson(dryRun: dryRun),
    );
    return ((json['data'] as Map<String, dynamic>)['recipient_count'] as num)
        .toInt();
  }

  Future<List<ScheduleClass>> scheduleClasses() async {
    final json = await _client.getJson('/api/admin/schedule/classes');
    return [
      for (final item in json['data'] as List)
        ScheduleClass.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<SchedulePeriod>> schedule(ScheduleClass schoolClass) async {
    final json = await _client.getJson(
      '/api/admin/schedule',
      query: {'grade': schoolClass.grade, 'section': schoolClass.section},
    );
    return [
      for (final item in json['data'] as List)
        SchedulePeriod.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<List<SchedulePeriod>> saveSchedule(
    ScheduleClass schoolClass,
    List<SchedulePeriod> periods,
  ) async {
    final json = await _client.putJson('/api/admin/schedule', {
      'grade': schoolClass.grade,
      'section': schoolClass.section,
      'periods': [for (final period in periods) period.toJson()],
    });
    return [
      for (final item in json['data'] as List)
        SchedulePeriod.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<ApiFile> exportSchedule(ScheduleClass c) => _client.getFile(
    '/api/admin/schedule/export',
    query: {'grade': c.grade, 'section': c.section},
  );

  Future<Map<String, dynamic>> importSchedule(
    ScheduleClass c,
    Uint8List bytes,
    String name, {
    required bool dryRun,
  }) => _client.sendMultipart(
    method: 'POST',
    path: '/api/admin/schedule/import',
    fields: {
      'grade': c.grade,
      'section': c.section,
      if (dryRun) 'dry_run': 'true',
    },
    image: bytes,
    fileName: name,
    fileField: 'file',
  );

  Future<void> clearSchedule(ScheduleClass c) async {
    await _client.putJson('/api/admin/schedule', {
      'grade': c.grade,
      'section': c.section,
      'periods': <Object>[],
    });
  }

  Future<List<SchoolBanner>> banners() async {
    final json = await _client.getJson('/api/admin/banners');
    return [
      for (final item in json['data'] as List)
        SchoolBanner.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> saveBanner({
    int? id,
    required String title,
    required bool isActive,
    Uint8List? image,
    String? fileName,
  }) async {
    await _client.sendMultipart(
      method: id == null ? 'POST' : 'PUT',
      path: '/api/admin/banners',
      query: id == null ? null : {'id': '$id'},
      fields: {
        'title': title.trim(),
        'is_active': '$isActive',
        'action_link': '',
      },
      image: image,
      fileName: fileName,
    );
  }

  Future<void> deleteBanner(int id) async {
    await _client.deleteJson('/api/admin/banners', query: {'id': '$id'});
  }

  Future<Uint8List> bannerImage(SchoolBanner banner) async {
    if (!banner.hasUploadedImage) {
      return _client.getPublicImage(banner.imageUrl);
    }
    final file = await _client.getFile(
      '/api/admin/banners/image',
      query: {'id': '${banner.id}'},
    );
    return file.bytes;
  }

  // ---------------------------------------------------------------- الجلسة

  /// يستعيد الجلسة المحفوظة إن وُجدت. يرجع true عند وجود توكن.
  Future<bool> restoreSession() async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return false;
    _client.token = token;
    username = await _store.readUsername();
    return true;
  }

  Future<void> login(String user, String password) async {
    final json = await _client.postJson('/api/admin/login', {
      'username': user,
      'password': password,
    }, auth: false);
    final token = (json['data'] as Map<String, dynamic>)['token'] as String;
    _client.token = token;
    username = user;
    await _store.save(token: token, username: user);
  }

  Future<void> logout() async {
    _client.token = null;
    username = null;
    await _store.clear();
  }

  // ------------------------------------------------------------ لوحة التحكم

  Future<DashboardStats> dashboard() async =>
      DashboardStats.fromJson(await _client.getJson('/api/admin/dashboard'));

  // ----------------------------------------------------------------- الطلاب

  Future<List<Student>> students() async {
    final json = await _client.getJson('/api/admin/students');
    return [
      for (final s in json['data'] as List<dynamic>)
        Student.fromJson(s as Map<String, dynamic>),
    ];
  }

  Future<Student> createStudent({
    required String name,
    required String parentName,
    required String parentPhone,
    String? parentPin,
    required String rfidTag,
    String? grade,
    String? section,
  }) async {
    final json = await _client.postJson('/api/admin/students', {
      'name': name,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_pin': ?_nonEmpty(parentPin),
      'rfid_tag': rfidTag.trim(),
      'grade': ?grade,
      'section': ?section,
    });
    return Student.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> updateStudent({
    required int id,
    required String name,
    required String parentName,
    required String parentPhone,
    String? parentPin,
    String? rfidTag,
    String? grade,
    String? section,
  }) async {
    await _client.putJson('/api/admin/students', {
      'id': id,
      'name': name,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_pin': ?_nonEmpty(parentPin),
      'rfid_tag': ?_nonEmpty(rfidTag),
      'grade': ?grade,
      'section': ?section,
    });
  }

  /// تعطيل الطالب (`is_active=false`)، السجلات تبقى.
  Future<void> deactivateStudent(int id) async {
    await _client.deleteJson('/api/admin/students', query: {'id': '$id'});
  }

  // ------------------------------------------------------------------ الحضور

  Future<AttendanceDay> attendance(DateTime date) async {
    final d = BaghdadTime.apiDate(date);
    final json = await _client.getJson(
      '/api/admin/attendance',
      query: {'date': d},
    );
    return AttendanceDay(json['date'] as String? ?? d, [
      for (final e in json['data'] as List<dynamic>)
        AttendanceEntry.fromJson(e as Map<String, dynamic>),
    ], dayInfo: SchoolDayInfo.fromJson(json));
  }

  Future<List<Holiday>> holidays() async {
    final json = await _client.getJson('/api/admin/holidays');
    return [
      for (final item in json['data'] as List)
        Holiday.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<Map<String, dynamic>> createHoliday(
    Map<String, dynamic> draft, {
    required bool dryRun,
  }) async {
    final json = await _client.postJson('/api/admin/holidays', {
      ...draft,
      if (dryRun) 'dry_run': true,
      if (!dryRun && draft['kind'] == 'pause') 'confirm': true,
    });
    return json['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelHoliday(
    int id, {
    required bool dryRun,
    bool notify = true,
    String? notes,
  }) async {
    final json = await _client.postJson('/api/admin/holidays/cancel', {
      'id': id,
      'notify': notify,
      'notes': ?notes,
      if (dryRun) 'dry_run': true,
    });
    return json['data'] as Map<String, dynamic>;
  }

  /// تقرير Excel جاهز من الخادم لليوم المحدد.
  Future<ApiFile> exportAttendanceExcel(DateTime date) => _client.getFile(
    '/api/admin/export/excel',
    query: {'date': BaghdadTime.apiDate(date)},
  );

  // ---------------------------------------------------------------- الإجازات

  /// يسجّل إجازة ليوم واحد؛ إعادة الإرسال لنفس اليوم تحدّث الملاحظة فقط.
  Future<int> createLeave({
    required int studentId,
    required DateTime date,
    String notes = '',
  }) async {
    final json = await _client.postJson('/api/admin/leaves', {
      'student_id': studentId,
      'leave_date': BaghdadTime.apiDate(date),
      'notes': notes,
    });
    return ((json['data'] as Map<String, dynamic>)['leave_id'] as num).toInt();
  }

  /// يلغي إجازة طالب في يوم محدد. الخادم يجيب 200 دائماً (حتى لو لم توجد إجازة)،
  /// فلا نعتبر النجاح دليلاً على وجودها؛ بعد الإلغاء يُعاد تحميل التقرير.
  Future<void> cancelLeave({
    required int studentId,
    required DateTime date,
  }) async {
    await _client.deleteJson(
      '/api/admin/leaves',
      query: {'student_id': '$studentId', 'date': BaghdadTime.apiDate(date)},
    );
  }

  // --------------------------------------------------------------- الإعدادات

  Future<Map<String, String>> settings() async {
    final json = await _client.getJson('/api/admin/settings');
    final data = json['data'] as Map<String, dynamic>;
    return {for (final e in data.entries) e.key: '${e.value}'};
  }

  Future<void> saveSetting(String key, String value) async {
    await _client.putJson('/api/admin/settings', {'key': key, 'value': value});
  }

  // ----------------------------------------------------------------- الأجهزة

  Future<List<Device>> devices() async {
    final json = await _client.getJson('/api/admin/devices');
    return [
      for (final d in json['data'] as List<dynamic>)
        Device.fromJson(d as Map<String, dynamic>),
    ];
  }

  /// يضيف جهازاً (يُنشأ مفعّلاً افتراضياً).
  Future<void> createDevice({
    required String serialNumber,
    required String locationName,
    bool isActive = true,
  }) async {
    await _client.postJson('/api/admin/devices', {
      'serial_number': serialNumber,
      'location_name': locationName,
      'is_active': isActive,
    });
  }

  /// يعدّل الحقول المرسلة فقط؛ الحقل المحذوف يحتفظ بقيمته في الخادم.
  /// لا بد من إرسال حقل واحد على الأقل.
  Future<void> updateDevice({
    required String serialNumber,
    String? locationName,
    bool? isActive,
  }) async {
    assert(locationName != null || isActive != null);
    await _client.putJson('/api/admin/devices', {
      'serial_number': serialNumber,
      'location_name': ?locationName,
      'is_active': ?isActive,
    });
  }
}

/// أخطاء خاصة بسياق العملية، لرسائل أوضح من الرسالة العامة.
extension StudentErrors on ApiException {
  String get studentSaveMessage {
    if (statusCode == 409) {
      return 'معرّف البصمة هذا مستخدم لطالب آخر، اختر معرّفاً مختلفاً';
    }
    if (statusCode == 400) {
      return serverMessage ?? message;
    }
    return message;
  }
}
