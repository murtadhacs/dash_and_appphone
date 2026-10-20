import 'dart:convert';
import 'dart:typed_data';
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/core/attendance_policy.dart';
import 'package:alrhman_dashboard/core/baghdad_time.dart';
import 'package:alrhman_dashboard/models/attendance_entry.dart';
import 'package:alrhman_dashboard/models/schedule_class.dart';
import 'package:alrhman_dashboard/models/student.dart';
import 'package:alrhman_dashboard/widgets/attendance/attendance_table.dart';
import 'package:alrhman_dashboard/widgets/attendance/attendance_kpi_row.dart';
import 'package:alrhman_dashboard/widgets/attendance/leave_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

const schoolClass = ScheduleClass(
  grade: 'G3 ',
  section: 'شعبة أ',
  studentCount: 0,
  periodCount: 5,
  dayCount: 1,
);
const student = Student(
  id: 1,
  name: 'عمر',
  parentName: '',
  parentPhone: '',
  rfidTag: '1001',
  grade: 'الثالث',
  section: 'أ',
);
http.Response jsonResponse(Object body, [int code = 200]) => http.Response(
  jsonEncode(body),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Widget host(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);
Future<void> tap(WidgetTester t, String text) async {
  final f = find.text(text).last;
  await t.ensureVisible(f);
  await t.tap(f);
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async => initializeDateFormatting());
  tearDown(() => BaghdadTime.clock = DateTime.now);
  test('Baghdad cutoff, weekends and previous day', () {
    BaghdadTime.clock = () => DateTime.utc(2026, 10, 11, 6, 30, 59);
    expect(AttendancePolicy(DateTime(2026, 10, 11)).awaitingArrival, isTrue);
    BaghdadTime.clock = () => DateTime.utc(2026, 10, 11, 6, 31);
    expect(AttendancePolicy(DateTime(2026, 10, 11)).hideAbsence, isFalse);
    expect(AttendancePolicy(DateTime(2026, 10, 9)).weekend, isTrue);
    expect(AttendancePolicy(DateTime(2026, 10, 10)).weekend, isTrue);
    expect(AttendancePolicy(DateTime(2026, 10, 8)).awaitingArrival, isFalse);
    expect(leaveSchoolDays(DateTime(2026, 10, 8), DateTime(2026, 10, 12)), [
      DateTime(2026, 10, 8),
      DateTime(2026, 10, 11),
      DateTime(2026, 10, 12),
    ]);
    expect(nextSchoolDay(DateTime(2026, 10, 8)), DateTime(2026, 10, 11));
  });
  test(
    'schedule bytes, exact class guard, multipart and clear request',
    () async {
      final calls = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((r) async {
          calls.add(r);
          if (r.url.path.endsWith('/export')) {
            return http.Response.bytes(
              [80, 75, 3, 4],
              200,
              headers: {
                'content-disposition':
                    "attachment; filename*=UTF-8''${Uri.encodeComponent('جدول.xlsx')}",
              },
            );
          }
          return jsonResponse({'status': 'success', 'data': []});
        }),
      )..token = 'TOKEN';
      final api = AdminApi(client, MemoryTokenStore());
      final file = await api.exportSchedule(schoolClass);
      expect(file.bytes, [80, 75, 3, 4]);
      expect(file.fileName, 'جدول.xlsx');
      expect(calls.single.url.queryParameters, {
        'grade': 'G3 ',
        'section': 'شعبة أ',
      });
      expect(calls.single.headers['Authorization'], 'Bearer TOKEN');
      await api.importSchedule(
        schoolClass,
        Uint8List.fromList([80, 75]),
        'schedule.xlsx',
        dryRun: true,
      );
      expect(
        calls.last.body,
        contains('name="file"; filename="schedule.xlsx"'),
      );
      expect(calls.last.body, contains('name="dry_run"\r\n\r\ntrue'));
      expect(calls.last.body, contains('name="grade"\r\n\r\nG3 '));
      await api.importSchedule(
        schoolClass,
        Uint8List.fromList([80, 75]),
        'schedule.xlsx',
        dryRun: false,
      );
      expect(calls.last.body, isNot(contains('name="dry_run"')));
      await api.clearSchedule(schoolClass);
      expect(calls.last.method, 'PUT');
      expect(jsonDecode(calls.last.body), {
        'grade': 'G3 ',
        'section': 'شعبة أ',
        'periods': [],
      });
    },
  );
  testWidgets(
    'leave range skips weekends, retries remaining days, plain notes and ordinary errors',
    (t) async {
      final calls = <String>[];
      var fail = true;
      await t.pumpWidget(
        host(
          LeaveDialog(
            students: const [student],
            prefillStudentId: 1,
            initialDate: DateTime(2026, 10, 8),
            onSubmit: (id, date, notes) async {
              final key = BaghdadTime.apiDate(date);
              calls.add(key);
              expect(notes, 'موعد طبي');
              if (key == '2026-10-11' && fail) {
                fail = false;
                throw const ApiException(
                  statusCode: 400,
                  message: 'ordinary',
                  serverMessage: 'SECRET SERVER ERROR',
                );
              }
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('1001'), findsOneWidget);
      expect(find.textContaining('قبل 12:00'), findsOneWidget);
      await t.enterText(find.byType(TextFormField).at(2), '2026-10-12');
      await t.enterText(find.byType(TextFormField).at(3), 'موعد طبي');
      await tap(t, 'منح الإجازة');
      expect(calls, ['2026-10-08', '2026-10-11']);
      expect(find.textContaining('SECRET SERVER ERROR'), findsNothing);
      expect(find.textContaining('تم حفظ 1 من 3'), findsOneWidget);
      await tap(t, 'إكمال الأيام المتبقية');
      expect(calls, ['2026-10-08', '2026-10-11', '2026-10-11', '2026-10-12']);
      expect(find.textContaining('بنجاح لـ 3'), findsOneWidget);
      await tap(t, 'إضافة اليوم الدراسي التالي');
      expect(
        t
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '2026-10-13',
      );
    },
  );
  testWidgets('weekend hides absent status and KPI; waiting has neutral text', (
    t,
  ) async {
    const absent = AttendanceEntry(
      studentId: 1,
      fullName: 'عمر',
      status: PresenceStatus.absent,
    );
    final search = TextEditingController();
    addTearDown(search.dispose);
    Widget table(bool weekend, bool waiting) => AttendanceTable(
      entries: const [absent],
      students: const {},
      onRegisterExcuse: (_) {},
      onCancelLeave: (_) {},
      weekend: weekend,
      awaitingArrival: waiting,
    );
    await t.pumpWidget(host(table(true, false)));
    expect(find.text('غائب'), findsNothing);
    await t.pumpWidget(host(table(false, true)));
    expect(find.text('بانتظار الوصول'), findsOneWidget);
    expect(find.text('غائب'), findsNothing);
    await t.pumpWidget(
      host(
        AttendanceKpiRow(
          day: AttendanceDay('2026-10-10', const [absent]),
          live: false,
          lastUpdated: '—',
          hideAbsence: true,
        ),
      ),
    );
    expect(find.text('الغائبون'), findsNothing);
  });
}
