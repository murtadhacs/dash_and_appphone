import 'dart:convert';
import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/api_exception.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/core/baghdad_time.dart';
import 'package:alrhman_school/core/month_calendar.dart';
import 'package:alrhman_school/core/school_days.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:alrhman_school/data/parent_data.dart';
import 'package:alrhman_school/screens/schedule_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';

ParentApi _api(FakeServer s, [SessionStore? store]) => ParentApi(
  ApiClient(baseUrl: 'https://fake.test', client: s.client),
  store ?? MemorySessionStore(),
);

void main() {
  // الخميس 2026-10-08 الساعة 09:00 بتوقيت بغداد.
  setUp(() => BaghdadTime.clock = () => DateTime.utc(2026, 10, 8, 6));
  tearDown(() => BaghdadTime.clock = DateTime.now);

  group('الدخول', () {
    test('يرسل الجديدة حتى 72 رمزاً والقديمة حرفياً دون قص أو تعديل', () async {
      for (final password in ['Kq7#vR2m!Tx9pW4z', '${'a' * 70}1!', ' 4321 ']) {
        final server = FakeServer()..parent1Credential = password;
        await _api(server).login('07000000101', password);
        expect(jsonDecode(server.requests.last.body)['pin'], password);
      }
    });
    test(
      'يحفظ التوكن وبيانات ولي الأمر (بلا PIN) ويرسل Bearer بعدها',
      () async {
        final s = FakeServer();
        final store = MemorySessionStore();
        final api = _api(s, store);

        final p = await api.login('07000000101', '4321');
        expect(p.name, 'Test Parent');
        expect(p.localPhone, '07000000101');

        final saved = await store.read();
        expect(saved!.token, 'tok-1');
        expect(saved.parent.phone, '+9647000000101');

        await api.students();
        expect(s.requests.last.headers['Authorization'], 'Bearer tok-1');
      },
    );

    test('رمز خاطئ: رسالة عربية ولا يُعدّ انتهاء جلسة', () async {
      final s = FakeServer();
      final api = _api(s);
      var expired = false;
      api.client.onUnauthorized = () => expired = true;
      await expectLater(
        api.login('07000000101', '0000'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'رقم الهاتف أو كلمة المرور غير صحيحة',
          ),
        ),
      );
      expect(expired, isFalse);
    });

    test('429 يحدد دقائق الانتظار', () async {
      final s = FakeServer()..failedLogins = 5;
      try {
        await _api(s).login('07000000101', '4321');
        fail('يجب أن يرمي');
      } on ApiException catch (e) {
        expect(e.statusCode, 429);
        expect(e.retryAfterSeconds, 540);
        expect(e.message, contains('9 دقيقة'));
      }
    });

    test('401 على طلب موثّق يستدعي onUnauthorized', () async {
      final s = FakeServer();
      final api = _api(s);
      await api.login('07000000101', '4321');
      s.expireTokens = true;
      var expired = false;
      api.client.onUnauthorized = () => expired = true;
      await expectLater(api.students(), throwsA(isA<ApiException>()));
      expect(expired, isTrue);
    });
  });

  group('تحويل البيانات', () {
    test('حضور اليوم والأبناء', () async {
      final s = FakeServer();
      final api = _api(s);
      await api.login('07000000102', '123654');
      final kids = await api.students();
      final today = await api.today();
      expect(kids.map((k) => k.classLabel), ['G2 — A', 'G4 — B']);
      expect(today[3]!.status, PresenceStatus.excused);
    });

    test('صور البنرات النسبية تُكمَّل بعنوان الخادم', () async {
      final s = FakeServer();
      final api = _api(s);
      await api.login('07000000101', '4321');
      final b = await api.banners();
      expect(
        b.single.imageUrl.split('&v=').first,
        'https://fake.test/api/mobile/banners/image?id=2',
      );
    });

    test('وقت الإشعار يُقرأ بساعة بغداد', () async {
      final s = FakeServer();
      final api = _api(s);
      await api.login('07000000101', '4321');
      final page = await api.notifications();
      expect(page.items.first.createdAt, DateTime(2026, 10, 8, 7, 15, 4));
      expect(page.unreadCount, 2);
      expect(page.hasMore, isTrue);
      expect(page.nextBefore, 3);
    });
  });

  group('الجدول', () {
    test('subject keys, known icons, unknown fallback and refresh', () async {
      final grouped = groupSchedule([
        for (final key in [
          'arabic',
          'islamic',
          'math',
          'science',
          'social',
          'english',
          'art',
          'pe',
          'computer',
          'music',
          'other',
          'future',
        ])
          {
            'student_id': 1,
            'day_of_week': 'الأحد',
            'period_number': 1,
            'subject_name': 'مادة',
            'subject_key': key,
            'teacher_name': null,
          },
      ]);
      expect(grouped[1]!.single.periods.map((p) => p.subjectKey), [
        'arabic',
        'islamic',
        'math',
        'science',
        'social',
        'english',
        'art',
        'pe',
        'computer',
        'music',
        'other',
        'future',
      ]);
      expect(subjectIcon('future'), subjectIcon('other'));
      expect(subjectIcon('arabic'), isNot(subjectIcon('math')));
      final server = FakeServer();
      final api = _api(server);
      await api.login('07000000101', '4321');
      final data = ParentData(api);
      addTearDown(data.dispose);
      await data.loadAll();
      data.schedules = const {};
      await data.refresh();
      expect(data.schedules[1], isNotEmpty);
      expect(
        server.requests
            .where((r) => r.url.path == '/api/mobile/schedule')
            .length,
        2,
      );
    });
    test('يجمّع الأيام بترتيب الأسبوع ويوحّد الهمزة والإنجليزية', () async {
      final s = FakeServer();
      final api = _api(s);
      await api.login('07000000101', '4321');
      final days = (await api.schedule())[1]!;

      expect(days.map((d) => d.dayKey), [
        'sunday',
        'monday',
        'thursday',
        'يوم النشاط', // اسم غير معروف يُلحق بعد أيام الأسبوع
      ]);
      expect(days.first.periods.map((p) => p.periodNumber), [1, 2]);
      expect(days[1].dayName, 'الإثنين');
    });

    test('dayKeyOf', () {
      expect(dayKeyOf('الأربعاء'), 'wednesday');
      expect(dayKeyOf('الاربعاء'), 'wednesday');
      expect(dayKeyOf('  SUNDAY '), 'sunday');
      expect(dayKeyOf('الجمعة'), isNull);
    });
  });

  group('تقويم الشهر', () {
    final records = [
      MonthlyRecord(
        date: DateTime(2026, 10, 8),
        status: PresenceStatus.present,
      ),
      MonthlyRecord(date: DateTime(2026, 10, 6), status: PresenceStatus.absent),
      MonthlyRecord(
        date: DateTime(2026, 10, 5),
        status: PresenceStatus.excused,
      ),
    ];

    test('يبدأ أكتوبر 2026 يوم الخميس (4 خانات فارغة قبله)', () {
      final grid = buildMonthGrid(
        DateTime(2026, 10),
        records,
        DateTime(2026, 10, 8),
      );
      expect(grid.take(4).every((c) => c == null), isTrue);
      expect(grid[4]!.date, DateTime(2026, 10, 1));
      expect(grid.whereType<CalendarCell>().length, 31);
    });

    test('حالات الأيام', () {
      final grid = buildMonthGrid(
        DateTime(2026, 10),
        records,
        DateTime(2026, 10, 8),
      );
      DayState at(int day) => grid
          .whereType<CalendarCell>()
          .firstWhere((c) => c.date.day == day)
          .state;
      expect(at(8), DayState.present);
      expect(at(6), DayState.absent);
      expect(at(5), DayState.excused);
      expect(at(2), DayState.weekend); // جمعة
      expect(at(7), DayState.noRecord);
      expect(at(12), DayState.future);
    });

    test('الإحصاء والنسبة', () {
      final s = MonthStats.of(records);
      expect([s.present, s.absent, s.excused], [1, 1, 1]);
      expect(s.rate, 33);
      expect(MonthStats.of(const []).rate, isNull);
    });
  });

  test('BaghdadTime.relative', () {
    expect(BaghdadTime.relative(DateTime(2026, 10, 8, 8, 55)), 'قبل 5 دقيقة');
    expect(BaghdadTime.relative(DateTime(2026, 10, 8, 7, 15)), 'اليوم 07:15');
    expect(BaghdadTime.relative(DateTime(2026, 10, 7, 12, 1)), 'أمس 12:01');
  });
}
