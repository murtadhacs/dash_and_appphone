import 'dart:async';

import '../services/push_device.dart';
import '../core/baghdad_time.dart';
import '../core/school_day_info.dart';
import '../models/holiday.dart';
import '../core/school_days.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'session_store.dart';

class TodayResponse {
  final SchoolDayInfo dayInfo;
  final Map<int, TodayAttendance> entries;
  const TodayResponse(this.dayInfo, this.entries);
}

/// صفحة من سجل الإشعارات.
class NotificationPage {
  final List<AppNotification> items;
  final bool hasMore;
  final int? nextBefore;

  /// إجمالي غير المقروء عبر كل الصفحات (للشارة)، من الخادم مباشرة.
  final int unreadCount;

  const NotificationPage(
    this.items,
    this.hasMore,
    this.nextBefore,
    this.unreadCount,
  );
}

/// الإعدادات العامة (لا تحتاج تسجيل دخول). الحقول قد تغيب إن لم تضبطها المدرسة.
class PublicSettings {
  final String? schoolName;
  final String? whatsappNumber;
  const PublicSettings({this.schoolName, this.whatsappNumber});
}

/// عمليات تطبيق ولي الأمر (`/api/mobile/*`) حسب عقد الـ API.
class ParentApi {
  ParentApi(this.client, this._store, {PushDevice? pushDevice})
    : pushDevice = pushDevice ?? UnavailablePushDevice();

  final ApiClient client;
  final SessionStore _store;
  final PushDevice pushDevice;
  StreamSubscription<String>? _tokenSubscription;
  bool? deviceRegistered;
  void Function()? onSessionCleared;

  ParentProfile? parent;

  // ---------------------------------------------------------------- الجلسة

  Future<bool> restoreSession() async {
    final s = await _store.read();
    if (s == null) return false;
    client.token = s.token;
    parent = s.parent;
    unawaited(_startPush());
    return true;
  }

  /// [phone] يُرسل كما كتبه ولي الأمر؛ الخادم يقبل كل الصيغ العراقية.
  /// [pin] كلمة المرور كما كتبها المستخدم، دون تغيير أو تحقق من صيغة:
  /// كلمات المرور الجديدة والرموز القديمة مقبولة عند الدخول.
  Future<ParentProfile> login(String phone, String pin) async {
    final json = await client.postJson('/api/mobile/login', {
      'phone': phone.trim(),
      'pin': pin,
    }, auth: false);
    final data = json['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final profile = ParentProfile.fromJson(
      data['parent'] as Map<String, dynamic>,
    );
    client.token = token;
    parent = profile;
    await _store.save(StoredSession(token, profile));
    unawaited(_startPush());
    return profile;
  }

  Future<void> logout() async {
    final subscription = _tokenSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    _tokenSubscription = null;
    try {
      final token = await pushDevice.token();
      if (token != null && client.token != null) await removeDeviceToken(token);
    } catch (_) {
      // Local sign-out must still succeed when offline or unauthorized.
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    final subscription = _tokenSubscription;
    _tokenSubscription = null;
    client.token = null;
    parent = null;
    deviceRegistered = null;
    onSessionCleared?.call();
    await _store.clear();
    if (subscription != null) unawaited(subscription.cancel());
  }

  Future<void> deleteAccount(String pin) async {
    await client.postJson('/api/mobile/account/delete', {'pin': pin});
    await clearSession();
    try {
      await pushDevice.deleteToken();
    } catch (_) {}
  }

  Future<void> _startPush() async {
    final session = client.token;
    await _tokenSubscription?.cancel();
    if (session == null || client.token != session) return;
    _tokenSubscription = pushDevice.tokenRefresh.listen((token) async {
      if (client.token != session) return;
      try {
        final registered = await registerDeviceToken(token);
        if (client.token == session) deviceRegistered = registered;
      } catch (_) {}
    }, onError: (Object _) {});
    try {
      await pushDevice.requestPermission();
      await refreshDeviceRegistration();
    } catch (_) {}
  }

  Future<bool?> refreshDeviceRegistration() async {
    final session = client.token;
    final token = await pushDevice.token();
    if (session == null || client.token != session || token == null) {
      return null;
    }
    final registered = await registerDeviceToken(token);
    if (client.token == session) deviceRegistered = registered;
    return registered;
  }

  Future<bool> notificationSettings() async {
    final json = await client.getJson('/api/mobile/notification-settings');
    return (json['data'] as Map<String, dynamic>)['push_enabled'] as bool;
  }

  Future<bool> updateNotificationSettings(bool enabled) async {
    final json = await client.putJson(
      '/api/mobile/notification-settings',
      body: {'push_enabled': enabled},
    );
    return (json['data'] as Map<String, dynamic>)['push_enabled'] as bool;
  }

  Future<bool> registerDeviceToken(String token) async {
    final json = await client.putJson(
      '/api/mobile/device-token',
      body: {'token': token},
    );
    return json['registered'] as bool;
  }

  Future<void> removeDeviceToken(String token) async {
    await client.deleteJson('/api/mobile/device-token', {'token': token});
  }

  // ------------------------------------------------------------- القراءة

  Future<PublicSettings> publicSettings() async {
    final json = await client.getJson('/api/mobile/settings', auth: false);
    final data = json['data'] as Map<String, dynamic>? ?? const {};
    return PublicSettings(
      schoolName: data['school_name'] as String?,
      whatsappNumber: data['whatsapp_number'] as String?,
    );
  }

  Future<List<Student>> students() async {
    final json = await client.getJson('/api/mobile/students');
    return [
      for (final s in json['data'] as List<dynamic>)
        Student.fromJson(s as Map<String, dynamic>),
    ];
  }

  /// حضور اليوم مفهرساً بمعرّف الطالب.
  Future<Map<int, TodayAttendance>> today() async =>
      (await todayResponse()).entries;

  Future<TodayResponse> todayResponse() async {
    final json = await client.getJson('/api/mobile/attendance/today');
    final info = SchoolDayInfo.fromJson(json);
    return TodayResponse(
      info,
      !info.isSchool
          ? {}
          : {
              for (final e in json['data'] as List<dynamic>)
                ((e as Map<String, dynamic>)['student_id'] as num).toInt():
                    TodayAttendance.fromJson(e),
            },
    );
  }

  Future<List<HolidayDay>> holidays(DateTime month) async {
    final json = await client.getJson(
      '/api/mobile/holidays',
      query: {'month': BaghdadTime.apiMonth(month)},
    );
    return [
      for (final item in json['data'] as List)
        HolidayDay.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// سجل شهر لكل طالب (الأيام الدراسية حتى اليوم، الأحدث أولاً).
  Future<Map<int, List<MonthlyRecord>>> monthly(DateTime month) async {
    final json = await client.getJson(
      '/api/mobile/attendance/monthly',
      query: {'month': BaghdadTime.apiMonth(month)},
    );
    return {
      for (final s in json['data'] as List<dynamic>)
        ((s as Map<String, dynamic>)['student_id'] as num).toInt(): [
          for (final r in s['records'] as List<dynamic>)
            MonthlyRecord.fromJson(r as Map<String, dynamic>),
        ],
    };
  }

  /// الجدول الأسبوعي مجمّعاً لكل طالب، بترتيب الأيام كما يرسلها الخادم.
  Future<Map<int, List<DaySchedule>>> schedule() async {
    final json = await client.getJson('/api/mobile/schedule');
    return groupSchedule(json['data'] as List<dynamic>);
  }

  Future<NotificationPage> notifications({int? before}) async {
    final json = await client.getJson(
      '/api/mobile/notifications',
      query: before == null ? null : {'before': '$before'},
    );
    return NotificationPage(
      [
        for (final n in json['data'] as List<dynamic>)
          AppNotification.fromJson(n as Map<String, dynamic>),
      ],
      json['has_more'] as bool? ?? false,
      (json['next_before'] as num?)?.toInt(),
      (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> markNotificationRead(int id) async {
    await client.putJson(
      '/api/mobile/notifications/read',
      query: {'id': '$id'},
    );
  }

  Future<void> markAllNotificationsRead() async {
    await client.putJson('/api/mobile/notifications/read-all');
  }

  Future<List<SchoolBanner>> banners() async {
    final json = await client.getJson('/api/mobile/banners');
    final revision = DateTime.now().microsecondsSinceEpoch.toString();
    String imageUrl(String value) {
      final resolved = client.resolve(value);
      final uri = Uri.tryParse(resolved);
      // الصورة المُستبدلة تحمل نفس المعرّف؛ لا نعرض نسخة قديمة من الذاكرة.
      if (value.startsWith('/api/mobile/banners/image') && uri != null) {
        return uri
            .replace(queryParameters: {...uri.queryParameters, 'v': revision})
            .toString();
      }
      return resolved;
    }

    return [
      for (final b in json['data'] as List<dynamic>)
        SchoolBanner(
          id: ((b as Map<String, dynamic>)['id'] as num).toInt(),
          title: b['title'] as String? ?? '',
          // المسار النسبي يُكمَّل بعنوان الخادم؛ لا يحتاج توكن.
          imageUrl: imageUrl(b['image_url'] as String? ?? ''),
          actionLink: b['action_link'] as String? ?? '',
        ),
    ];
  }
}
