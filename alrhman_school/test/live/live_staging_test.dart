@Tags(['live'])
library;

import 'dart:io';

import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/core/baghdad_time.dart';
import 'package:alrhman_school/core/month_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبار قراءة فقط على الخادم الحقيقي (لا يعلّم إشعارات كمقروءة ولا يسجّل جهازاً).
/// يُشغَّل يدوياً، وبيانات الدخول من البيئة فقط:
///   LIVE_PHONE=... LIVE_PIN=... flutter test test/live --tags live
void main() {
  final phone = Platform.environment['LIVE_PHONE'];
  final pin = Platform.environment['LIVE_PIN'];
  final base =
      Platform.environment['LIVE_URL'] ??
      'https://futurekids-staging.up.railway.app';

  test(
    'قراءة كل بيانات ولي الأمر من staging',
    () async {
      final api = ParentApi(ApiClient(baseUrl: base), MemorySessionStore());
      // ignore: avoid_print
      void log(Object o) => print(o);

      final settings = await api.publicSettings();
      log(
        'SETTINGS school=${settings.schoolName} wa=${settings.whatsappNumber}',
      );

      final parent = await api.login(phone!, pin!);
      log('LOGIN ${parent.name} ${parent.localPhone}');

      final kids = await api.students();
      final today = await api.today();
      for (final k in kids) {
        final t = today[k.id];
        log(
          'STUDENT #${k.id} ${k.name} | ${k.classLabel} | today=${t?.status.name} '
          'in=${t?.checkIn} out=${t?.checkOut}',
        );
      }

      final month = await api.monthly(BaghdadTime.today());
      for (final e in month.entries) {
        final s = MonthStats.of(e.value);
        log(
          'MONTH #${e.key} days=${e.value.length} present=${s.present} '
          'absent=${s.absent} excused=${s.excused} rate=${s.rate}',
        );
      }

      final schedule = await api.schedule();
      for (final e in schedule.entries) {
        log(
          'SCHEDULE #${e.key} ${e.value.map((d) => '${d.dayName}:${d.periods.length}').join(' ')}',
        );
      }

      final page = await api.notifications();
      log(
        'NOTIFS n=${page.items.length} unread=${page.unreadCount} more=${page.hasMore} '
        'first="${page.items.firstOrNull?.title}" at=${page.items.firstOrNull?.createdAt} '
        'cat=${page.items.firstOrNull?.category.name}',
      );

      final banners = await api.banners();
      for (final b in banners) {
        log('BANNER #${b.id} "${b.title}" ${b.imageUrl} link=${b.actionLink}');
      }
      expect(kids, isNotEmpty);
    },
    skip: (phone == null || pin == null)
        ? 'LIVE_PHONE / LIVE_PIN غير معرّفين'
        : null,
  );
}
