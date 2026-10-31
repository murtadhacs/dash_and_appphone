import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/data/parent_data.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:alrhman_school/screens/tuition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';

Future<ParentData> _data(FakeServer server, String token) async {
  final client = ApiClient(baseUrl: 'https://fake.test', client: server.client);
  final api = ParentApi(client, MemorySessionStore());
  client.token = token;
  return ParentData(api);
}

Future<void> _pump(WidgetTester t, ParentData data) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: TuitionScreen(data: data),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test(
    'parses remaining, last update in Baghdad time, and null remaining',
    () async {
      final data = await _data(FakeServer(), 'tok-2');
      final items = await data.api.tuition();
      expect(items.length, 2);
      expect(items[0].remaining, 900000);
      expect(items[0].academicYear, '2026-2027');
      expect(items[0].lastUpdated, DateTime(2026, 10, 1, 9, 30));
      expect(items[1].remaining, isNull);
      expect(items[1].feeSet, isFalse);
      expect(items[1].lastUpdated, isNull);
    },
  );

  test('money and date formatting', () {
    expect(formatDinar(900000), '900,000');
    expect(formatDinar(1500000), '1,500,000');
    expect(formatDinar(5), '5');
    expect(
      formatTuitionUpdate(DateTime(2026, 10, 1, 9, 30)),
      '1 تشرين الأول 2026 · 9:30 ص',
    );
    expect(
      formatTuitionUpdate(DateTime(2026, 10, 1, 0, 5)),
      '1 تشرين الأول 2026 · 12:05 ص',
    );
    expect(
      formatTuitionUpdate(DateTime(2026, 10, 1, 13, 0)),
      '1 تشرين الأول 2026 · 1:00 م',
    );
  });

  testWidgets(
    'shows the remaining amount and a not-set card, never a zero for null',
    (t) async {
      final server = FakeServer();
      final data = await _data(server, 'tok-2');
      data.students = const [
        Student(id: 2, name: 'Ali Test', grade: 'G2', section: 'A'),
        Student(id: 3, name: 'Sara Test', grade: 'G4', section: 'B'),
      ];
      await _pump(t, data);
      expect(find.text('المتبقي من القسط'), findsWidgets);
      expect(find.text('900,000'), findsOneWidget);
      expect(find.text('متبقٍ'), findsOneWidget);
      expect(find.text('لم يُحدَّد'), findsOneWidget);
      expect(find.text('لم يُحدَّد القسط بعد'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(
        find.text('آخر تحديث: 1 تشرين الأول 2026 · 9:30 ص'),
        findsOneWidget,
      );
      expect(find.text('لا يوجد تحديث بعد'), findsOneWidget);
      expect(find.text('G2 — A'), findsOneWidget);
      // قراءة فقط: طلب واحد، ولا تفاصيل دفعات.
      expect(
        server.requests
            .where((r) => r.url.path == '/api/mobile/tuition')
            .length,
        1,
      );
    },
  );

  testWidgets('a zero remaining is shown as paid', (t) async {
    final data = await _data(FakeServer(), 'tok-1');
    await _pump(t, data);
    expect(find.text('مسدّد'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('an error shows the message and retries', (t) async {
    final server = FakeServer()..expireTokens = true;
    final data = await _data(server, 'tok-2');
    await _pump(t, data);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
