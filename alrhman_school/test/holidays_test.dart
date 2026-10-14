import 'dart:convert';
import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/core/month_calendar.dart';
import 'package:alrhman_school/core/school_day_info.dart';
import 'package:alrhman_school/data/parent_data.dart';
import 'package:alrhman_school/models/holiday.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:alrhman_school/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'holiday and weekend outrank stale attendance, including future closures',
    () {
      final h = HolidayDay(
        date: DateTime(2026, 10, 11),
        kind: 'pause',
        title: 'العطلة الصيفية',
        notes: 'لا دوام',
      );
      final grid = buildMonthGrid(
        DateTime(2026, 10),
        [
          MonthlyRecord.fromJson({'date': '2026-10-11', 'status': 'Absent'}),
          MonthlyRecord.fromJson({'date': '2026-10-09', 'status': 'Absent'}),
        ],
        DateTime(2026, 10, 8),
        holidays: [h],
      );
      final cells = grid.whereType<CalendarCell>();
      expect(cells.firstWhere((c) => c.date.day == 11).state, DayState.holiday);
      expect(cells.firstWhere((c) => c.date.day == 11).record, isNull);
      expect(cells.firstWhere((c) => c.date.day == 9).state, DayState.weekend);
    },
  );

  test(
    'monthly loading requests holidays and excludes closed dates from counters',
    () async {
      final api = ParentApi(
        ApiClient(
          baseUrl: 'https://fake.test',
          client: MockClient((r) async {
            expect(r.url.queryParameters['month'], '2026-10');
            final data = r.url.path.endsWith('/holidays')
                ? [
                    {
                      'date': '2026-10-11',
                      'kind': 'holiday',
                      'title': 'عطلة',
                      'notes': null,
                    },
                  ]
                : [
                    {
                      'student_id': 1,
                      'records': [
                        {'date': '2026-10-11', 'status': 'Absent'},
                        {'date': '2026-10-09', 'status': 'Absent'},
                        {'date': '2026-10-12', 'status': 'Present'},
                      ],
                    },
                  ];
            return http.Response(
              jsonEncode({'data': data}),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
        MemorySessionStore(),
      );
      final data = ParentData(api);
      await data.loadMonth(DateTime(2026, 10));
      final stats = MonthStats.of(data.recordsFor(1, DateTime(2026, 10))!);
      expect(stats.schoolDays, 1);
      expect(stats.absent, 0);
      expect(stats.present, 1);
      expect(data.holidaysFor(DateTime(2026, 10)).single.title, 'عطلة');
      expect(data.recordsFor(999, DateTime(2026, 10)), isEmpty);
      final grid = buildMonthGrid(
        DateTime(2026, 10),
        data.recordsFor(999, DateTime(2026, 10))!,
        DateTime(2026, 10, 12),
        holidays: data.holidaysFor(DateTime(2026, 10)),
      );
      expect(
        grid
            .whereType<CalendarCell>()
            .firstWhere((c) => c.date.day == 11)
            .state,
        DayState.holiday,
      );
    },
  );

  testWidgets('home displays closure title and notes instead of attendance', (
    tester,
  ) async {
    final api = ParentApi(
      ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((r) async => http.Response('{}', 200)),
      ),
      MemorySessionStore(),
    );
    final data = ParentData(api)
      ..dayInfo = const SchoolDayInfo(
        type: 'pause',
        title: 'العطلة الصيفية',
        notes: 'نتمنى لكم عطلة سعيدة',
      )
      ..students = [
        Student.fromJson({
          'id': 1,
          'name': 'طالب',
          'grade': 'G1',
          'section': 'A',
        }),
      ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeScreen(data: data)),
      ),
    );
    expect(find.text('العطلة الصيفية'), findsOneWidget);
    expect(find.text('نتمنى لكم عطلة سعيدة'), findsOneWidget);
    expect(find.text('حالة الطالب اليوم'), findsNothing);
  });
}
