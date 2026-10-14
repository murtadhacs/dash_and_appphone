import 'dart:convert';
import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/app_scope.dart';
import 'package:alrhman_school/core/baghdad_time.dart';
import 'package:alrhman_school/main.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_server.dart';

/// خطا Cairo وLucide حتى تظهر النصوص والأيقونات بقياسها الحقيقي في الاختبار.
Future<void> loadFonts() async {
  final cairo = FontLoader('Cairo');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    cairo.addFont(rootBundle.load('assets/fonts/Cairo-$w.ttf'));
  }
  await cairo.load();
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucide.load();
}

class Harness {
  final FakeServer server;
  final MemorySessionStore store;
  Harness(this.server, this.store);
}

/// يشغّل التطبيق كاملاً من شاشة البداية على خادم وهمي.
Future<Harness> pumpApp(
  WidgetTester tester, {
  StoredSession? session,
  FakeServer? server,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final s = server ?? FakeServer();
  final store = MemorySessionStore();
  if (session != null) await store.save(session);
  final services = AppServices(
    ParentApi(ApiClient(baseUrl: 'https://fake.test', client: s.client), store),
  );

  await tester.pumpWidget(AlRahmanSchoolApp(services: services));
  // شاشة البداية تنتظر 2.2 ثانية، ثم تحميل البيانات.
  await settle(tester, seconds: 4);
  return Harness(s, store);
}

/// لا pumpAndSettle: في الشاشات حركات متكررة (نبض، دوران).
Future<void> settle(WidgetTester tester, {double seconds = 1.5}) async {
  final steps = (seconds * 10).round();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text).last;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f, warnIfMissed: false);
  await settle(tester);
}

const parent1 = StoredSession(
  'tok-1',
  ParentProfile(id: 1, name: 'Test Parent', phone: '+9647000000101'),
);
const parent2 = StoredSession(
  'tok-2',
  ParentProfile(id: 2, name: 'Parent Two', phone: '+9647000000102'),
);

void main() {
  setUpAll(loadFonts);
  // الخميس 2026-10-08 الساعة 09:00 بتوقيت بغداد.
  setUp(() => BaghdadTime.clock = () => DateTime.utc(2026, 10, 8, 6));
  tearDown(() => BaghdadTime.clock = DateTime.now);

  testWidgets('الدخول: رمز خاطئ ثم صحيح ← الرئيسية ببيانات حقيقية', (t) async {
    final h = await pumpApp(t);
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('ولي أمر الطالب'), findsNothing); // لا قيم تجريبية معبأة

    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '07000000101');
    await t.enterText(fields.at(1), '0000');
    await tapText(t, 'تسجيل الدخول');
    expect(find.text('رقم الهاتف أو كلمة المرور غير صحيحة'), findsOneWidget);

    await t.enterText(fields.at(1), '4321');
    await tapText(t, 'تسجيل الدخول');
    await settle(t, seconds: 2);

    expect(find.text('Test Parent'), findsOneWidget);
    expect(find.text('Test Student'), findsOneWidget);
    expect(find.text('وقت الوصول: 07:15 ص'), findsOneWidget);
    expect(find.text('رحلة مدرسية'), findsOneWidget); // البنر
    expect(find.text('جدول اليوم يشمل 2 حصص'), findsOneWidget); // الخميس
    // الجلسة محفوظة بلا PIN.
    expect((await h.store.read())!.token, 'tok-1');
  });

  testWidgets('الدخول بكلمة مرور جديدة وإظهارها وإرسالها دون تعديل', (t) async {
    const password = 'Kq7#vR2m!Tx9pW4z';
    final server = FakeServer()..parent1Credential = password;
    final h = await pumpApp(t, server: server);
    final fields = find.byType(TextField);
    expect(find.text('كلمة مرور ولي الأمر'), findsOneWidget);
    expect(
      t.widget<TextField>(fields.at(1)).keyboardType,
      TextInputType.visiblePassword,
    );
    expect(t.widget<TextField>(fields.at(1)).obscureText, isTrue);
    await t.enterText(fields.at(0), '07000000101');
    await t.enterText(fields.at(1), password);
    await t.tap(find.byTooltip('إظهار كلمة المرور'));
    await settle(t);
    expect(t.widget<TextField>(fields.at(1)).obscureText, isFalse);
    expect(t.widget<TextField>(fields.at(1)).enableSuggestions, isFalse);
    await t.tap(find.byTooltip('إخفاء كلمة المرور'));
    await settle(t);
    expect(t.widget<TextField>(fields.at(1)).obscureText, isTrue);
    await tapText(t, 'تسجيل الدخول');
    await settle(t, seconds: 2);
    final login = h.server.requests.firstWhere(
      (r) => r.url.path == '/api/mobile/login',
    );
    expect(jsonDecode(login.body)['pin'], password);
    expect(find.text('Test Parent'), findsOneWidget);
  });

  testWidgets('جلسة محفوظة: ابنان، غائب قبل الظهر = "لم يصل بعد"، ثم التبديل', (
    t,
  ) async {
    await pumpApp(t, session: parent2);
    expect(find.text('Ali Test'), findsOneWidget);
    expect(find.text('لم يصل بعد'), findsOneWidget);

    await tapText(t, 'تبديل');
    expect(find.text('قائمة الأبناء'), findsOneWidget);
    // اختيار الطالب يغلق القائمة مباشرة.
    await tapText(t, 'Sara Test');
    expect(find.text('قائمة الأبناء'), findsNothing);
    expect(find.text('في إجازة معتمدة اليوم'), findsOneWidget);
  });

  testWidgets('الحضور: تقويم الشهر وإحصاؤه والتنقل للشهر السابق', (t) async {
    final h = await pumpApp(t, session: parent1);
    await tapText(t, 'الحضور');

    expect(find.text('تقويم شهر تشرين الأول 2026'), findsOneWidget);
    expect(find.text('3 يوم'), findsOneWidget); // حضور
    expect(find.text('2 يوم'), findsOneWidget); // غياب
    expect(find.text('نسبة الحضور 50٪'), findsOneWidget);
    // اليوم المحدد افتراضياً: آخر يوم له سجل (اليوم).
    expect(find.text('تفاصيل يوم الخميس 8 تشرين الأول'), findsOneWidget);

    await t.tap(find.byTooltip('الشهر السابق'));
    await settle(t);
    expect(find.text('تقويم شهر أيلول 2026'), findsOneWidget);
    expect(
      h.server.requests.any((r) => r.url.queryParameters['month'] == '2026-09'),
      isTrue,
    );
  });

  testWidgets('الجدول: أيام الدراسة فقط وتبويب لكل ابن', (t) async {
    await pumpApp(t, session: parent1);
    await tapText(t, 'الجدول');

    expect(find.text('الحاسوب'), findsOneWidget); // الخميس
    expect(find.text('يوم النشاط'), findsNothing);
    expect(find.byType(ChoiceChip), findsOneWidget);
    expect(find.text('لم يُحدَّد المعلم'), findsWidgets);

    await tapText(t, 'الأحد');
    expect(find.text('اللغة العربية'), findsOneWidget);
    expect(find.text('معلمة تجريبية'), findsOneWidget);
  });

  testWidgets('جدول الأبناء: التبديل المباشر والصف بلا جدول', (t) async {
    await pumpApp(t, session: parent2);
    await tapText(t, 'الجدول');
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    await tapText(t, 'الأحد');
    expect(find.text('العلوم'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Sara Test'));
    await settle(t);
    expect(find.text('لم يُضف الجدول بعد'), findsOneWidget);
    expect(find.text('العلوم'), findsNothing);
    await t.tap(find.widgetWithText(ChoiceChip, 'Ali Test'));
    await settle(t);
    expect(find.text('العلوم'), findsOneWidget);
  });

  testWidgets('الإشعارات: قراءة إشعار، الصفحة التالية، قراءة الكل', (t) async {
    final h = await pumpApp(t, session: parent1);
    await tapText(t, 'الإشعارات');

    expect(find.text('قراءة الكل (2)'), findsOneWidget);
    await tapText(t, 'إشعار دخول');
    expect(
      h.server.requests.any(
        (r) =>
            r.method == 'PUT' &&
            r.url.path == '/api/mobile/notifications/read' &&
            r.url.queryParameters['id'] == '4',
      ),
      isTrue,
    );
    expect(find.text('قراءة الكل (1)'), findsOneWidget);

    await tapText(t, 'عرض إشعارات أقدم');
    expect(find.text('إشعار خروج'), findsOneWidget);
    expect(find.text('عرض إشعارات أقدم'), findsNothing);

    await tapText(t, 'قراءة الكل (1)');
    expect(find.textContaining('قراءة الكل'), findsNothing);
  });

  testWidgets('انتهاء الجلسة (401) يعيد للدخول مع تنبيه ويحذف الجلسة', (
    t,
  ) async {
    final h = await pumpApp(t, session: parent1);
    h.server.expireTokens = true;
    // فتح الحضور يطلب سجل الشهر ← 401 ← العودة للدخول.
    await tapText(t, 'الحضور');
    await settle(t, seconds: 2);

    expect(find.textContaining('انتهت الجلسة'), findsOneWidget);
    expect(await h.store.read(), isNull);
  });

  testWidgets('الإعدادات: بيانات ولي الأمر وواتساب الإدارة وتسجيل الخروج', (
    t,
  ) async {
    final h = await pumpApp(t, session: parent1);
    await tapText(t, 'الإعدادات');

    expect(find.text('Test Parent'), findsOneWidget);
    expect(find.textContaining('07000000101'), findsOneWidget);
    expect(find.text('تواصل مع إدارة المدرسة'), findsOneWidget);
    expect(find.text('الإشعارات الفورية'), findsNothing);

    await tapText(t, 'تسجيل الخروج');
    await tapText(t, 'تسجيل الخروج');
    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(await h.store.read(), isNull);
  });
}
