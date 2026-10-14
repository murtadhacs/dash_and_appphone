import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/core/school_day_info.dart';
import 'package:alrhman_dashboard/models/attendance_entry.dart';
import 'package:alrhman_dashboard/models/dashboard_stats.dart';
import 'package:alrhman_dashboard/widgets/attendance/holiday_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });
  test(
    'closed reports discard attendance and preserve student and parent totals',
    () {
      final stats = DashboardStats.fromJson({
        'date': '2026-10-11',
        'day_type': 'pause',
        'day_title': 'العطلة الصيفية',
        'day_notes': 'حتى إشعار آخر',
        'data': {
          'total_students': 50,
          'total_parents': 30,
          'absent_today': 50,
          'present_today': 1,
          'excused_today': 2,
        },
      });
      expect(stats.totalStudents, 50);
      expect(stats.totalParents, 30);
      expect(
        [stats.presentToday, stats.absentToday, stats.excusedToday],
        [0, 0, 0],
      );
      expect(stats.dayInfo.label, 'العطلة الصيفية');
      final day = AttendanceDay('2026-10-11', const [
        AttendanceEntry(
          studentId: 1,
          fullName: 'طالب',
          status: PresenceStatus.absent,
        ),
      ], dayInfo: stats.dayInfo);
      expect(day.entries, isEmpty);
      expect(day.arrivals, isEmpty);
      expect(
        SchoolDayInfo.fromJson({
          'date': '2026-10-09',
          'day_type': 'holiday',
          'day_title': 'عطلة',
        }).label,
        'عطلة نهاية الأسبوع',
      );
    },
  );

  testWidgets('pause preview never writes until confirmation', (tester) async {
    final posts = <Map<String, dynamic>>[];
    final api = AdminApi(
      ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((req) async {
          if (req.method == 'GET') {
            return http.Response(jsonEncode({'data': []}), 200);
          }
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          posts.add(body);
          return http.Response(
            jsonEncode({
              'data': {
                'start_date': body['start_date'],
                'end_date': null,
                'school_days': null,
                'recipient_count': 25,
              },
            }),
            200,
          );
        }),
      ),
      MemoryTokenStore(),
    );
    int changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HolidayControls(
            api: api,
            onChanged: () async {
              changed++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إيقاف الدوام'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'العطلة الصيفية');
    await tester.tap(find.text('معاينة قبل التأكيد'));
    await tester.pumpAndSettle();
    expect(posts.length, 1);
    expect(posts.single['dry_run'], true);
    expect(posts.single.containsKey('confirm'), false);
    expect(posts.single.containsKey('end_date'), false);
    expect(find.textContaining('25 ولي أمر'), findsOneWidget);
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();
    expect(posts.length, 1);
    expect(changed, 0);
    await tester.tap(find.text('إيقاف الدوام'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'العطلة الصيفية');
    await tester.tap(find.text('معاينة قبل التأكيد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(posts.length, 3);
    expect(posts.last['confirm'], true);
    expect(posts.last.containsKey('dry_run'), false);
    expect(changed, 1);
  });

  test(
    'cancellation sends id and notification preferences in preview and commit',
    () async {
      final calls = <Map<String, dynamic>>[];
      final api = AdminApi(
        ApiClient(
          baseUrl: 'https://fake.test',
          client: MockClient((r) async {
            expect(r.url.path, '/api/admin/holidays/cancel');
            calls.add(jsonDecode(r.body) as Map<String, dynamic>);
            return http.Response(
              jsonEncode({
                'data': {
                  'id': 12,
                  'action': 'shortened',
                  'end_date': '2026-10-12',
                },
              }),
              200,
            );
          }),
        ),
        MemoryTokenStore(),
      );
      await api.cancelHoliday(
        12,
        dryRun: true,
        notify: false,
        notes: 'استئناف',
      );
      final result = await api.cancelHoliday(
        12,
        dryRun: false,
        notify: false,
        notes: 'استئناف',
      );
      expect(calls.first['dry_run'], true);
      expect(calls.last.containsKey('dry_run'), false);
      expect(calls.last['notify'], false);
      expect(calls.last['id'], 12);
      expect(result['action'], 'shortened');
    },
  );
}
