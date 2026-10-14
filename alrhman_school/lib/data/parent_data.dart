import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import '../api/parent_api.dart';
import '../core/baghdad_time.dart';
import '../core/school_day_info.dart';
import '../models/holiday.dart';
import '../models/models.dart';

/// مالك بيانات التطبيق بعد الدخول: الأبناء، حضور اليوم، الجداول، الإشعارات، البنرات.
///
/// الشاشات تقرأ منه وتستمع لتغيّراته؛ هو وحده يتحدث مع [ParentApi].
class ParentData extends ChangeNotifier {
  ParentData(this.api) {
    api.onSessionCleared = clear;
  }

  bool _cleared = false;

  void clear() {
    _cleared = true;
    students = const [];
    schedules = const {};
    banners = const [];
    notifications = const [];
    unreadCount = 0;
    hasMoreNotifications = false;
    _nextBefore = null;
    _months.clear();
    _holidays.clear();
    settings = const PublicSettings();
    dayInfo = const SchoolDayInfo();
    notifyListeners();
  }

  final ParentApi api;
  SchoolDayInfo dayInfo = const SchoolDayInfo();
  final Map<String, List<HolidayDay>> _holidays = {};
  List<HolidayDay> holidaysFor(DateTime month) =>
      _holidays[BaghdadTime.apiMonth(month)] ?? const [];

  List<Student> students = const [];
  int _selectedIndex = 0;

  /// الجدول الأسبوعي لكل طالب.
  Map<int, List<DaySchedule>> schedules = const {};

  List<SchoolBanner> banners = const [];
  PublicSettings settings = const PublicSettings();

  // الإشعارات
  List<AppNotification> notifications = const [];
  int unreadCount = 0;
  bool hasMoreNotifications = false;
  int? _nextBefore;
  bool loadingMoreNotifications = false;

  /// سجلات الأشهر المحمّلة: "YYYY-MM" → (طالب → سجلات).
  final Map<String, Map<int, List<MonthlyRecord>>> _months = {};

  ParentProfile? get parent => api.parent;

  Student? get currentStudent => students.isEmpty
      ? null
      : students[_selectedIndex.clamp(0, students.length - 1)];

  void selectStudent(Student s) {
    final i = students.indexWhere((x) => x.id == s.id);
    if (i == -1 || i == _selectedIndex) return;
    _selectedIndex = i;
    notifyListeners();
  }

  /// التحميل الأول بعد الدخول. يرمي [ApiException] إن فشل جزء أساسي.
  Future<void> loadAll() async {
    final results = await Future.wait([
      api.students(),
      api.todayResponse(),
      api.schedule(),
      api.notifications(),
      // البنرات والإعدادات ثانويان: فشلهما لا يمنع فتح التطبيق.
      api.banners().catchError((_) => <SchoolBanner>[]),
      api.publicSettings().catchError((_) => const PublicSettings()),
    ]);

    if (_cleared) return;
    final list = results[0] as List<Student>;
    final response = results[1] as TodayResponse;
    dayInfo = response.dayInfo;
    final today = response.entries;
    students = [for (final s in list) s.withToday(today[s.id])];
    schedules = results[2] as Map<int, List<DaySchedule>>;
    _applyNotificationPage(results[3] as NotificationPage, replace: true);
    banners = results[4] as List<SchoolBanner>;
    settings = results[5] as PublicSettings;
    notifyListeners();
  }

  /// تحديث الحضور والإشعارات والبنرات عند السحب أو العودة للتطبيق.
  Future<void> refresh() async {
    final results = await Future.wait([
      api.todayResponse(),
      api.notifications(),
      api.banners().catchError((_) => banners),
      api.schedule(),
    ]);
    if (_cleared) return;
    final response = results[0] as TodayResponse;
    dayInfo = response.dayInfo;
    final today = response.entries;
    students = [for (final s in students) s.withToday(today[s.id])];
    _applyNotificationPage(results[1] as NotificationPage, replace: true);
    banners = results[2] as List<SchoolBanner>;
    schedules = results[3] as Map<int, List<DaySchedule>>;
    // سجل الشهر الحالي قد تغيّر (اليوم نفسه): نُسقطه ليُحمَّل من جديد.
    _months.clear();
    _holidays.clear();
    notifyListeners();
  }

  // ------------------------------------------------------------- سجل الشهر

  List<MonthlyRecord>? recordsFor(int studentId, DateTime month) {
    final records = _months[BaghdadTime.apiMonth(month)];
    return records == null ? null : records[studentId] ?? const [];
  }

  bool isMonthLoaded(DateTime month) =>
      _months.containsKey(BaghdadTime.apiMonth(month));

  /// يحمّل سجل شهر لكل الأبناء (طلب واحد للجميع).
  Future<void> loadMonth(DateTime month, {bool force = false}) async {
    final key = BaghdadTime.apiMonth(month);
    if (!force && _months.containsKey(key)) return;
    final results = await Future.wait([
      api.monthly(month),
      api.holidays(month),
    ]);
    if (_cleared) return;
    final holidays = results[1] as List<HolidayDay>;
    final closed = holidays.map((h) => BaghdadTime.apiDate(h.date)).toSet();
    _months[key] = {
      for (final entry in (results[0] as Map<int, List<MonthlyRecord>>).entries)
        entry.key: entry.value
            .where(
              (r) =>
                  !BaghdadTime.isWeekend(r.date) &&
                  !closed.contains(BaghdadTime.apiDate(r.date)),
            )
            .toList(),
    };
    _holidays[key] = holidays;
    notifyListeners();
  }

  // -------------------------------------------------------------- الإشعارات

  void _applyNotificationPage(NotificationPage page, {required bool replace}) {
    notifications = replace ? page.items : [...notifications, ...page.items];
    hasMoreNotifications = page.hasMore;
    _nextBefore = page.nextBefore;
    unreadCount = page.unreadCount;
  }

  Future<void> loadMoreNotifications() async {
    if (!hasMoreNotifications || loadingMoreNotifications) return;
    loadingMoreNotifications = true;
    notifyListeners();
    try {
      final page = await api.notifications(before: _nextBefore);
      if (_cleared) return;
      _applyNotificationPage(page, replace: false);
    } finally {
      loadingMoreNotifications = false;
      notifyListeners();
    }
  }

  /// يعلّم إشعاراً كمقروء (عند فتحه). العدّاد يُحدَّث محلياً ثم من الخادم لاحقاً.
  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    await api.markNotificationRead(n.id);
    if (_cleared) return;
    notifications = [
      for (final x in notifications) x.id == n.id ? x.markedRead() : x,
    ];
    if (unreadCount > 0) unreadCount--;
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await api.markAllNotificationsRead();
    if (_cleared) return;
    notifications = [for (final x in notifications) x.markedRead()];
    unreadCount = 0;
    notifyListeners();
  }

  /// اسم الابن المذكور في نص الإشعار (لا يرسل الخادم معرّف الطالب).
  Student? studentMentionedIn(AppNotification n) {
    for (final s in students) {
      if (s.name.isNotEmpty && n.body.contains(s.name)) return s;
    }
    return null;
  }
}
