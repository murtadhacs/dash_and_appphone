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
import '../models/expense.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/tuition.dart';
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
  // ---------------------------------------------------------------- المعلمون

  Future<List<Teacher>> teachers({String? search, TeacherStatus? status}) async {
    final json = await _client.getJson(
      '/api/admin/teachers',
      query: {
        if (_nonEmpty(search?.trim()) != null) 'search': search!.trim(),
        if (status != null) 'status': status.api,
      },
    );
    return [
      for (final t in json['data'] as List)
        Teacher.fromJson(t as Map<String, dynamic>),
    ];
  }

  /// `GET ?id` يرجع قائمة من عنصر واحد.
  Future<Teacher> teacher(int id) async {
    final json = await _client.getJson(
      '/api/admin/teachers',
      query: {'id': '$id'},
    );
    return Teacher.fromJson((json['data'] as List).first as Map<String, dynamic>);
  }

  Future<Teacher> createTeacher(TeacherInput input) async {
    final json = await _client.postJson('/api/admin/teachers', input.toJson());
    return Teacher.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// PUT يستبدل السجل كله: كل الحقول تُرسل، والاختياري الفارغ يُمسح.
  Future<Teacher> updateTeacher(int id, TeacherInput input) async {
    final json = await _client.putJson(
      '/api/admin/teachers',
      input.toJson(id: id),
    );
    return Teacher.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<String>> teacherSpecializations() async {
    final json = await _client.getJson('/api/admin/teachers/specializations');
    return [for (final s in json['data'] as List) '$s'];
  }

  Future<TeacherAttendanceDay> teachersAttendance(DateTime date) async =>
      TeacherAttendanceDay.fromJson(
        await _client.getJson(
          '/api/admin/teachers/attendance',
          query: {'date': BaghdadTime.apiDate(date)},
        ),
      );

  // ----------------------------------------------------------------- الأقساط

  Future<TuitionList> tuition({
    String? grade,
    String? section,
    String? search,
    bool hasRemaining = false,
  }) async => TuitionList.fromJson(
    await _client.getJson(
      '/api/admin/tuition',
      query: {
        if (_nonEmpty(grade) != null) 'grade': grade!,
        if (_nonEmpty(section) != null) 'section': section!,
        if (_nonEmpty(search?.trim()) != null) 'search': search!.trim(),
        if (hasRemaining) 'has_remaining': 'true',
      },
    ),
  );

  Future<TuitionDetail> studentTuition(int studentId) async {
    final json = await _client.getJson(
      '/api/admin/tuition/student',
      query: {'student_id': '$studentId'},
    );
    return TuitionDetail.fromJson(
      json['data'] as Map<String, dynamic>,
      academicYear: json['academic_year'] as String? ?? '',
    );
  }

  Future<GradeFees> tuitionFees() async =>
      GradeFees.fromJson(await _client.getJson('/api/admin/tuition/fees'));

  /// يرجع عدد الحسابات التي أُعيد تسعيرها (0 دون `apply_to_existing`).
  Future<int> setTuitionFee({
    required String grade,
    required int fee,
    bool applyToExisting = false,
  }) async {
    final json = await _client.putJson('/api/admin/tuition/fees', {
      'grade': grade,
      'fee': fee,
      'apply_to_existing': applyToExisting,
    });
    return ((json['data'] as Map<String, dynamic>)['updated_accounts'] as num?)
            ?.toInt() ??
        0;
  }

  Future<TuitionDetail> setTuitionDiscount({
    required int studentId,
    required int discount,
    String? note,
  }) async => _detail(
    await _client.putJson('/api/admin/tuition/discount', {
      'student_id': studentId,
      'discount': discount,
      'note': _nonEmpty(note?.trim()),
    }),
  );

  Future<TuitionDetail> recordPayment({
    required int studentId,
    required int amount,
    required DateTime paidAt,
    String? note,
  }) async => _detail(
    await _client.postJson('/api/admin/tuition/payments', {
      'student_id': studentId,
      'amount': amount,
      'paid_at': BaghdadTime.apiDate(paidAt),
      'note': _nonEmpty(note?.trim()),
    }),
  );

  Future<TuitionDetail> voidPayment({
    required int id,
    required String reason,
  }) async => _detail(
    await _client.postJson('/api/admin/tuition/payments/void', {
      'id': id,
      'reason': reason.trim(),
    }),
  );

  TuitionDetail _detail(Map<String, dynamic> json) => TuitionDetail.fromJson(
    json['data'] as Map<String, dynamic>,
    academicYear: json['academic_year'] as String? ?? '',
  );

  /// السنة الدراسية الحالية. تغييرها يجمّد أرصدة كل الطلاب، فلها شاشة منفصلة
  /// بتأكيد صريح ولا تظهر كحقل عادي في الإعدادات.
  Future<void> changeAcademicYear(String year) async {
    await _client.putJson('/api/admin/settings', {
      'key': 'academic_year',
      'value': year,
    });
  }

  // --------------------------------------------------------------- المصروفات

  Future<ExpenseList> expenses({
    int? categoryId,
    String? month,
    int? teacherId,
  }) async => ExpenseList.fromJson(
    await _client.getJson(
      '/api/admin/expenses',
      query: {
        if (categoryId != null) 'category_id': '$categoryId',
        'month': ?month,
        if (teacherId != null) 'teacher_id': '$teacherId',
      },
    ),
  );

  Future<void> createExpense({
    required int categoryId,
    required int amount,
    required DateTime date,
    String? note,
    int? teacherId,
  }) async {
    await _client.postJson('/api/admin/expenses', {
      'category_id': categoryId,
      'amount': amount,
      'expense_date': BaghdadTime.apiDate(date),
      'note': _nonEmpty(note?.trim()),
      'teacher_id': teacherId,
    });
  }

  Future<void> voidExpense({required int id, required String reason}) async {
    await _client.postJson('/api/admin/expenses/void', {
      'id': id,
      'reason': reason.trim(),
    });
  }

  Future<List<ExpenseCategory>> expenseCategories() async {
    final json = await _client.getJson('/api/admin/expenses/categories');
    return [
      for (final c in json['data'] as List)
        ExpenseCategory.fromJson(c as Map<String, dynamic>),
    ];
  }

  Future<void> createExpenseCategory(String name) async {
    await _client.postJson('/api/admin/expenses/categories', {
      'name': name.trim(),
    });
  }

  Future<ExpenseSummary> expenseSummary({int? categoryId}) async =>
      ExpenseSummary.fromJson(
        await _client.getJson(
          '/api/admin/expenses/summary',
          query: {if (categoryId != null) 'category_id': '$categoryId'},
        ),
      );
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
