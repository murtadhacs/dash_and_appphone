@Tags(['live'])
library;

import 'dart:io';

import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/core/baghdad_time.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// اختبار قراءة فقط على الخادم الحقيقي. يُشغَّل يدوياً:
///   LIVE_USER=... LIVE_PASS=... flutter test test/live --tags live
/// (بيانات الدخول من البيئة فقط، لا تُحفظ في الكود).
void main() {
  final user = Platform.environment['LIVE_USER'];
  final pass = Platform.environment['LIVE_PASS'];
  final base =
      Platform.environment['LIVE_URL'] ??
      'https://futurekids-staging.up.railway.app';

  final skip = (user == null || pass == null)
      ? 'LIVE_USER / LIVE_PASS غير معرّفين'
      : null;

  setUpAll(() async => initializeDateFormatting());

  test('قراءة كل شاشات الإدارة من staging (قراءة فقط)', () async {
    final client = ApiClient(baseUrl: base);
    final api = AdminApi(client, MemoryTokenStore());

    // الدخول
    await api.login(user!, pass!);
    expect(api.hasSession, isTrue);
    // ignore: avoid_print
    print('LOGIN ok');

    final stats = await api.dashboard();
    // ignore: avoid_print
    print(
      'DASHBOARD date=${stats.date} students=${stats.totalStudents} '
      'parents=${stats.totalParents} present=${stats.presentToday} '
      'excused=${stats.excusedToday} absent=${stats.absentToday}',
    );

    final students = await api.students();
    // ignore: avoid_print
    print('STUDENTS n=${students.length}');
    for (final s in students) {
      // ignore: avoid_print
      print(
        '  #${s.id} ${s.name} | ${s.gradeSection} | rfid=${s.rfidTag} '
        '| parent=${s.parentName} ${s.parentPhone} | created=${s.createdAt}',
      );
    }

    final day = await api.attendance(BaghdadTime.today());
    // ignore: avoid_print
    print('ATTENDANCE ${day.date} entries=${day.entries.length}');
    for (final e in day.ordered) {
      // ignore: avoid_print
      print(
        '  ${e.studentId} ${e.fullName} ${e.status.name} '
        'in=${e.checkInTime} out=${e.checkOutTime}',
      );
    }

    final devices = await api.devices();
    // ignore: avoid_print
    print('DEVICES n=${devices.length}');
    for (final d in devices) {
      // ignore: avoid_print
      print(
        '  ${d.serialNumber} | "${d.locationName}" | active=${d.isActive} '
        '| lastSync=${d.lastSync}',
      );
    }

    final settings = await api.settings();
    // ignore: avoid_print
    print('SETTINGS keys=${settings.keys.toList()}');

    final file = await api.exportAttendanceExcel(BaghdadTime.today());
    // ignore: avoid_print
    print('EXPORT name=${file.fileName} bytes=${file.bytes.length}');
    expect(file.bytes.length, greaterThan(100));
  }, skip: skip);

  test('كلمة مرور خاطئة تعطي رسالة الخادم (مرة واحدة فقط)', () async {
    final client = ApiClient(baseUrl: base);
    final api = AdminApi(client, MemoryTokenStore());
    try {
      await api.login('no-such-user-xyz', 'x');
      fail('يجب أن يرفض');
    } on ApiException catch (e) {
      // ignore: avoid_print
      print('BADLOGIN status=${e.statusCode} msg=${e.message}');
      expect(e.statusCode, 401);
    }
  }, skip: skip);
}
