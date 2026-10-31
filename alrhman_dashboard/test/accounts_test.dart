import 'dart:convert';

import 'package:alrhman_dashboard/api/accounts_errors.dart';
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/core/baghdad_time.dart';
import 'package:alrhman_dashboard/core/money.dart';
import 'package:alrhman_dashboard/models/teacher.dart';
import 'package:alrhman_dashboard/screens/academic_year_screen.dart';
import 'package:alrhman_dashboard/widgets/common/app_button.dart';
import 'package:alrhman_dashboard/screens/expenses_screen.dart';
import 'package:alrhman_dashboard/screens/settings_screen.dart';
import 'package:alrhman_dashboard/screens/teachers_screen.dart';
import 'package:alrhman_dashboard/screens/tuition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_server.dart';

Future<(AdminApi, FakeServer)> _api() async {
  final server = FakeServer();
  final store = MemoryTokenStore();
  await store.save(token: fakeToken, username: 'admin');
  final client = ApiClient(baseUrl: 'https://fake.test', client: server.client);
  final api = AdminApi(client, store);
  await api.restoreSession();
  return (api, server);
}

TeacherInput _teacher({
  String phone = '07701234567',
  String? rfid,
  String? specialization,
  String? notes,
  TeacherStatus status = TeacherStatus.active,
}) => TeacherInput(
  firstName: 'أحمد',
  fatherName: 'علي',
  grandfatherName: 'حسن',
  phone: phone,
  gender: 'male',
  status: status,
  specialization: specialization,
  notes: notes,
  rfidTag: rfid,
);

Map<String, dynamic> _lastBody(FakeServer s, String method, String path) =>
    jsonDecode(
          s.requests
              .lastWhere((r) => r.method == method && r.url.path == path)
              .body,
        )
        as Map<String, dynamic>;

Future<void> _pump(WidgetTester t, FakeServer server, Widget screen) async {
  t.view.physicalSize = const Size(1400, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final store = MemoryTokenStore();
  await store.save(token: fakeToken, username: 'admin');
  final client = ApiClient(baseUrl: 'https://fake.test', client: server.client);
  final services = AppServices(client, AdminApi(client, store), store);
  await services.api.restoreSession();
  await t.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: screen)),
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('money and grades', () {
    test('amounts are whole positive dinars up to 1,000,000,000', () {
      expect(Money.parse('1,500,000'), 1500000);
      expect(Money.parse('٥٠٠'), 500);
      expect(Money.parse('0'), isNull);
      expect(Money.parse('1.5'), isNull);
      expect(Money.parse('-5'), isNull);
      expect(Money.parse('1000000001'), isNull);
      expect(Money.parse('1e30'), isNull);
      expect(Money.parseAllowZero('0'), 0);
      expect(Money.format(1500000), '1,500,000');
      expect(Money.dinar(null), '—');
    });

    test('grades sort first to sixth, not alphabetically', () {
      final sorted = Grades.sorted([
        'الصف السادس الابتدائي',
        'الصف الثاني الابتدائي',
        'الصف الأول الابتدائي',
        'الصف الخامس الابتدائي',
        'الصف الثالث الابتدائي',
        'الصف الرابع الابتدائي',
      ]);
      expect(sorted.first, 'الصف الأول الابتدائي');
      expect(sorted[1], 'الصف الثاني الابتدائي');
      expect(sorted.last, 'الصف السادس الابتدائي');
    });
  });

  group('teachers api', () {
    test(
      'create normalizes the phone; update sends the whole record',
      () async {
        final (api, server) = await _api();
        final t = await api.createTeacher(
          _teacher(rfid: '12', specialization: 'الرياضيات'),
        );
        expect(t.phone, '+9647701234567');
        expect(t.rfidTag, '12');

        await api.updateTeacher(
          t.id,
          _teacher(
            status: TeacherStatus.onLeave,
            specialization: '  ',
            notes: '',
          ),
        );
        final body = _lastBody(server, 'PUT', '/api/admin/teachers');
        expect(body['id'], t.id);
        expect(body['status'], 'on_leave');
        // الحقول الاختيارية الفارغة تُرسل null لتُمسح، فلا يبقى رقم بصمة قديم.
        expect(body.containsKey('rfid_tag'), isTrue);
        expect(body['rfid_tag'], isNull);
        expect(body['specialization'], isNull);
        expect(body['notes'], isNull);
        final again = await api.teacher(t.id);
        expect(again.rfidTag, isNull);
      },
    );

    test('409 and 400 messages are mapped to Arabic', () async {
      final (api, server) = await _api();
      await api.createTeacher(_teacher(rfid: '12'));

      Future<ApiException> fail(TeacherInput i) async {
        try {
          await api.createTeacher(i);
        } on ApiException catch (e) {
          return e;
        }
        throw StateError('expected failure');
      }

      expect(
        (await fail(_teacher(rfid: '13'))).accountsMessage,
        'رقم الهاتف مستخدم لمعلم آخر',
      );
      expect(
        (await fail(
          _teacher(phone: '07709999999', rfid: '12'),
        )).accountsMessage,
        'رقم البصمة هذا لمعلم آخر',
      );
      server.students.add({
        'id': 90,
        'name': 'طالب',
        'parent_name': 'ولي',
        'parent_phone': '+9647700000000',
        'rfid_tag': '77',
        'grade': 'روضة 1',
        'section': 'أ',
      });
      expect(
        (await fail(
          _teacher(phone: '07708888888', rfid: '77'),
        )).accountsMessage,
        contains('لطالب'),
      );
      final tooHigh = await fail(_teacher(phone: '07707777777', rfid: '150'));
      expect(tooHigh.statusCode, 400);
      expect(tooHigh.accountsMessage, contains('من 1 إلى 99'));
    });

    test(
      'attendance carries not_punched; search and status filters go to the server',
      () async {
        final (api, server) = await _api();
        await api.createTeacher(_teacher());
        final day = await api.teachersAttendance(DateTime(2026, 10, 29));
        expect(day.entries.single.notPunched, isTrue);
        expect(day.missing, 1);
        await api.teachers(search: 'أحمد', status: TeacherStatus.active);
        final req = server.requests.lastWhere(
          (r) => r.url.path == '/api/admin/teachers',
        );
        expect(req.url.queryParameters, {'search': 'أحمد', 'status': 'active'});
      },
    );
  });

  group('tuition api', () {
    test('remaining is null until the grade has a fee, never zero', () async {
      final (api, _) = await _api();
      final before = await api.tuition();
      expect(
        before.rows.every((r) => r.remaining == null && !r.feeSet),
        isTrue,
      );
      expect(before.summary.notSetCount, before.rows.length);

      await api.setTuitionFee(grade: 'روضة 1', fee: 1500000);
      final after = await api.tuition(grade: 'روضة 1');
      expect(after.rows.single.remaining, 1500000);
    });

    test(
      'payments are integers; overpaying is a 409 with an Arabic message',
      () async {
        final (api, server) = await _api();
        await api.setTuitionFee(grade: 'روضة 1', fee: 1500000);
        await api.setTuitionDiscount(
          studentId: 1,
          discount: 100000,
          note: 'خصم الأخوة',
        );
        var d = await api.recordPayment(
          studentId: 1,
          amount: 500000,
          paidAt: DateTime(2026, 10, 1),
          note: 'القسط الأول',
        );
        final body = _lastBody(server, 'POST', '/api/admin/tuition/payments');
        expect(body['amount'], isA<int>());
        expect(body['paid_at'], '2026-10-01');
        expect(d.row.remaining, 900000);

        try {
          await api.recordPayment(
            studentId: 1,
            amount: 9000000,
            paidAt: DateTime(2026, 10, 1),
          );
          fail('should be refused');
        } on ApiException catch (e) {
          expect(e.statusCode, 409);
          expect(e.accountsMessage, contains('أكبر من المتبقي'));
        }

        d = await api.voidPayment(id: d.payments.first.id, reason: 'صفر زائد');
        expect(d.row.paid, 0);
        expect(d.row.remaining, 1400000);
        expect(d.payments.single.voided, isTrue);
        expect(d.payments.single.voidReason, 'صفر زائد');

        try {
          await api.voidPayment(id: d.payments.single.id, reason: 'مرة ثانية');
          fail('already voided');
        } on ApiException catch (e) {
          expect(e.statusCode, 409);
          expect(e.accountsMessage, 'أُلغي هذا السجل من قبل');
        }
      },
    );

    test('discount above the fee is refused', () async {
      final (api, _) = await _api();
      await api.setTuitionFee(grade: 'روضة 1', fee: 100000);
      try {
        await api.setTuitionDiscount(studentId: 1, discount: 200000);
        fail('refused');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.accountsMessage, 'الخصم أكبر من القسط');
      }
    });

    test(
      'apply_to_existing is all or nothing and names the students',
      () async {
        final (api, server) = await _api();
        await api.setTuitionFee(grade: 'روضة 1', fee: 1500000);
        await api.recordPayment(
          studentId: 1,
          amount: 1400000,
          paidAt: DateTime(2026, 10, 1),
        );
        try {
          await api.setTuitionFee(
            grade: 'روضة 1',
            fee: 1000000,
            applyToExisting: true,
          );
          fail('negative balance');
        } on ApiException catch (e) {
          expect(e.statusCode, 409);
          expect(e.accountsMessage, contains('رصيد'));
          expect(e.accountsMessage, contains('1'));
        }
        expect(
          _lastBody(
            server,
            'PUT',
            '/api/admin/tuition/fees',
          )['apply_to_existing'],
          true,
        );
        final fees = await api.tuitionFees();
        expect(fees.fees.firstWhere((f) => f.grade == 'روضة 1').fee, 1500000);
      },
    );

    test(
      'the academic year is changed only through the settings key',
      () async {
        final (api, server) = await _api();
        await api.changeAcademicYear('2027-2028');
        expect(_lastBody(server, 'PUT', '/api/admin/settings'), {
          'key': 'academic_year',
          'value': '2027-2028',
        });
      },
    );
  });

  group('expenses api', () {
    test('a teacher is only accepted for the salary category', () async {
      final (api, server) = await _api();
      final teacher = await api.createTeacher(_teacher());
      final cats = await api.expenseCategories();
      final salary = cats.firstWhere((c) => c.isSalary);
      final rent = cats.firstWhere((c) => !c.isSalary);

      await api.createExpense(
        categoryId: salary.id,
        amount: 750000,
        date: DateTime(2026, 9, 30),
        note: 'راتب أيلول',
        teacherId: teacher.id,
      );
      expect(
        _lastBody(server, 'POST', '/api/admin/expenses')['amount'],
        isA<int>(),
      );
      try {
        await api.createExpense(
          categoryId: rent.id,
          amount: 1000,
          date: DateTime(2026, 9, 30),
          teacherId: teacher.id,
        );
        fail('refused');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.accountsMessage, contains('رواتب'));
      }
      final list = await api.expenses(teacherId: teacher.id);
      expect(list.expenses.single.teacherName, 'أحمد علي حسن');
      expect(list.total, 750000);
    });

    test('voided expenses stay listed but leave the total', () async {
      final (api, _) = await _api();
      final cats = await api.expenseCategories();
      await api.createExpense(
        categoryId: cats[1].id,
        amount: 70000,
        date: DateTime(2026, 9, 8),
      );
      await api.createExpense(
        categoryId: cats[1].id,
        amount: 30000,
        date: DateTime(2026, 9, 9),
      );
      var list = await api.expenses();
      expect(list.expenses.first.expenseDate, '2026-09-09');
      await api.voidExpense(id: list.expenses.first.id, reason: 'مبلغ خاطئ');
      list = await api.expenses();
      expect(list.expenses.length, 2);
      expect(list.expenses.first.voided, isTrue);
      expect(list.expenses.first.voidReason, 'مبلغ خاطئ');
      expect(list.total, 70000);
    });

    test(
      'a salary summary has null collected and difference, not zero',
      () async {
        final (api, _) = await _api();
        final cats = await api.expenseCategories();
        await api.createExpense(
          categoryId: cats.first.id,
          amount: 400000,
          date: DateTime(2026, 9, 30),
        );
        final all = await api.expenseSummary();
        expect(all.totals.collected, 0);
        final salaries = await api.expenseSummary(categoryId: cats.first.id);
        expect(salaries.categoryId, cats.first.id);
        expect(salaries.totals.expenses, 400000);
        expect(salaries.totals.collected, isNull);
        expect(salaries.totals.difference, isNull);
        expect(salaries.byMonth.single.totals.difference, isNull);
      },
    );

    test('a duplicate category name maps to an Arabic message', () async {
      final (api, _) = await _api();
      await api.createExpenseCategory('نظافة');
      try {
        await api.createExpenseCategory('نظافة');
        fail('duplicate');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.accountsMessage, 'الاسم مستخدم لفئة أخرى');
      }
    });
  });

  group('screens', () {
    testWidgets(
      'tuition list shows «لم يحدد القسط» and never a zero remaining',
      (t) async {
        final server = FakeServer();
        await _pump(t, server, TuitionScreen(onOpenAcademicYear: () {}));
        expect(find.text('لم يحدد القسط'), findsWidgets);
        expect(find.text('تغيير السنة الدراسية'), findsOneWidget);
        expect(find.text('قسط غير محدد: 4'), findsOneWidget);
      },
    );

    testWidgets('grades tab lists grades in school order with their fees', (
      t,
    ) async {
      final server = FakeServer();
      server.accounts.gradeFees['الصف الثالث الابتدائي'] = 1750000;
      await _pump(t, server, TuitionScreen(onOpenAcademicYear: () {}));
      await t.tap(find.text('أقساط الصفوف'));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.textContaining('1,750,000', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('الصف الثالث الابتدائي'), findsOneWidget);
    });

    testWidgets(
      'academic year: validation, two confirmations, then the settings key',
      (t) async {
        expect(validateAcademicYear('2027-2028'), isNull);
        expect(validateAcademicYear('2027-2029'), isNotNull);
        expect(validateAcademicYear('2027'), isNotNull);

        final server = FakeServer();
        var back = 0;
        await _pump(t, server, AcademicYearScreen(onBack: () => back++));
        final action = find.widgetWithText(AppButton, 'تغيير السنة الدراسية');
        expect(t.widget<AppButton>(action).onPressed, isNull);

        await t.enterText(find.byType(TextFormField), '2027-2028');
        await t.pump();
        expect(t.widget<AppButton>(action).onPressed, isNull);
        for (final box in find.byType(Checkbox).evaluate().toList()) {
          await t.tap(find.byWidget(box.widget));
          await t.pump();
        }
        expect(t.widget<AppButton>(action).onPressed, isNotNull);
        await t.ensureVisible(action);
        await t.tap(action);
        await t.pumpAndSettle();
        await t.tap(find.text('نعم، غيّر السنة'));
        await t.pumpAndSettle();
        expect(server.settings['academic_year'], '2027-2028');
        expect(back, 1);
      },
    );

    testWidgets('settings never shows academic_year as an ordinary field', (
      t,
    ) async {
      final server = FakeServer();
      server.settings['academic_year'] = '2026-2027';
      await _pump(t, server, const SettingsScreen());
      expect(find.text('academic_year'), findsNothing);
      expect(find.textContaining('2026-2027'), findsNothing);
    });

    testWidgets('teachers screen lists and filters', (t) async {
      final server = FakeServer();
      await _pump(t, server, const TeachersScreen());
      expect(find.text('لا يوجد معلمون مطابقون'), findsOneWidget);
      expect(find.text('إضافة معلم'), findsOneWidget);
    });

    testWidgets('expenses screen opens with the list and the report tab', (
      t,
    ) async {
      final server = FakeServer();
      await _pump(t, server, const ExpensesScreen());
      expect(find.text('إضافة مصروف'), findsOneWidget);
      expect(find.text('تقرير السنة'), findsOneWidget);
      expect(BaghdadTime.today().year, greaterThan(2000));
    });
  });
}
