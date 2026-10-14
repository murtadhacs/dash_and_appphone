import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:alrhman_dashboard/widgets/banners/banner_form_dialog.dart';
import 'package:alrhman_dashboard/widgets/attendance/leave_dialog.dart';

import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/app_shell.dart';
import 'package:alrhman_dashboard/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_server.dart';

final _captureKey = GlobalKey();

Future<void> _loadCairo() async {
  final loader = FontLoader('Cairo');
  for (final f in ['Regular', 'SemiBold', 'Bold']) {
    final bytes = File('test/fonts/Cairo-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  final fontsPath =
      '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
  for (final font in ['MaterialIcons', 'Roboto']) {
    final fontLoader = FontLoader(font);
    final file = font == 'MaterialIcons'
        ? 'materialicons-regular.otf'
        : 'roboto-regular.ttf';
    fontLoader.addFont(
      Future.value(
        ByteData.sublistView(File('$fontsPath/$file').readAsBytesSync()),
      ),
    );
    await fontLoader.load();
  }
}

/// يبني التطبيق على خادم وهمي. [loggedIn] يهيّئ جلسة محفوظة مسبقاً.
Future<FakeServer> _pumpApp(
  WidgetTester tester, {
  bool loggedIn = true,
  FakeServer? server,
  Size size = const Size(1400, 1000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  server ??= FakeServer();
  final store = MemoryTokenStore();
  if (loggedIn) await store.save(token: fakeToken, username: 'admin');

  final client = ApiClient(baseUrl: 'https://fake.test', client: server.client);
  final services = AppServices(client, AdminApi(client, store), store);

  await tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (_, child) => RepaintBoundary(key: _captureKey, child: child!),
        theme: ThemeData(fontFamily: 'Cairo', useMaterial3: true),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AppShell(),
      ),
    ),
  );
  await _settle(tester);
  return server;
}

/// لا نستخدم pumpAndSettle لأن في الشاشات حركات متكررة (نقاط نابضة).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text).first;
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _settle(tester);
}

/// يفرغ الشجرة لإلغاء المؤقتات قبل نهاية الاختبار.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('design_previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadCairo();
  });

  testWidgets(
    'overview shortcuts open banner and leave forms; one report export',
    (tester) async {
      await _pumpApp(tester, size: const Size(1600, 1400));
      expect(find.text('تصدير كشف اليوم'), findsOneWidget);
      expect(find.text('تصدير التقرير اليومي'), findsNothing);
      expect(find.text('إضافة جدول سريع'), findsOneWidget);
      await _capture(tester, 'overview_updated');
      await _tapText(tester, 'إضافة بنر');
      expect(find.byType(BannerFormDialog), findsOneWidget);
      await _tapText(tester, 'إلغاء');
      await _tapText(tester, 'لوحة التحكم');
      await _tapText(tester, 'تسجيل إجازة');
      expect(find.byType(LeaveDialog), findsOneWidget);
      expect(find.text('نوع العذر'), findsNothing);
      await _capture(tester, 'leave_updated');
      expect(tester.takeException(), isNull);
      await _dispose(tester);
    },
  );
  testWidgets('overview quick actions fit a narrow screen', (tester) async {
    await _pumpApp(tester, size: const Size(390, 900));
    await tester.ensureVisible(find.text('إضافة بنر'));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await _capture(tester, 'overview_mobile_updated');
    await _dispose(tester);
  });

  testWidgets('الدخول: بيانات خاطئة تُظهر رسالة الخادم، والصحيحة تفتح اللوحة', (
    tester,
  ) async {
    final server = await _pumpApp(tester, loggedIn: false);
    expect(find.text('مرحباً بك مجدداً في بوابة الإدارة'), findsOneWidget);
    // لا بيانات تجريبية معبأة مسبقاً.
    expect(find.text('admin@futurekids.edu.sa'), findsNothing);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'wrong');
    await _tapText(tester, 'تسجيل الدخول للنظام');
    expect(find.text('بيانات الدخول غير صحيحة'), findsOneWidget);

    await tester.enterText(fields.at(1), 'admin');
    await _tapText(tester, 'تسجيل الدخول للنظام');
    expect(find.text('نظرة عامة'), findsOneWidget);
    expect(
      server.requests.where((r) => r.url.path == '/api/admin/login').length,
      2,
    );
    await _dispose(tester);
  });

  testWidgets('لوحة التحكم: أرقام حقيقية + تنبيه عدم وجود جهاز مفعّل', (
    tester,
  ) async {
    final fake = FakeServer()..devices.first['is_active'] = false;
    await _pumpApp(tester, server: fake);

    expect(find.textContaining('لا يوجد أي جهاز بصمة مفعّل'), findsOneWidget);
    expect(find.text('إجمالي الطلاب'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    // آخر الحركات: الأحدث دخولاً (08:41) قبل الأقدم (07:12).
    final newer = tester.getTopLeft(find.text('ليان سعود المطيري').first).dy;
    final older = tester.getTopLeft(find.text('عمر فيصل المنصور').first).dy;
    expect(newer, lessThan(older));
    await _dispose(tester);
  });

  testWidgets('لوحة التحكم: لا تنبيه عند وجود جهاز مفعّل', (tester) async {
    await _pumpApp(tester);
    expect(find.textContaining('لا يوجد أي جهاز بصمة مفعّل'), findsNothing);
    expect(find.text('ZK-0001'), findsNothing); // الملخص يعرض الموقع لا الرقم
    expect(find.text('المدخل الرئيسي'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('الطلاب: كلمة مرور جديدة 16 رمزاً تُرسل دون تغيير وتبقى مخفية', (
    tester,
  ) async {
    final server = await _pumpApp(tester);
    await _tapText(tester, 'الطلاب وأولياء الأمور');
    expect(find.text('عمر فيصل المنصور'), findsOneWidget);
    // لا عمود لصلة القرابة ولا بيانات مزيّفة.
    expect(find.textContaining('الصلة'), findsNothing);

    await _tapText(tester, 'إضافة طالب جديد');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'مثال: ريان فهد الحارثي'),
      'طالب جديد',
    );
    // الحقول: الاسم، (قوائم)، معرّف البصمة، اسم ولي الأمر، الهاتف، PIN
    final parent = find.widgetWithText(
      TextFormField,
      'مثال: فهد عبد الله الحارثي',
    );
    await tester.enterText(parent, 'ولي أمر جديد');
    final phone = find.widgetWithText(TextFormField, '07XXXXXXXXX');
    await tester.enterText(phone, '٠٧٧٠٥٥٥٥٥٥٥'); // أرقام عربية
    await tester.pump();
    await _settle(tester);

    // رقم جديد → تم توليد PIN تلقائياً (6 أرقام).
    final pinField = find.widgetWithText(
      TextFormField,
      '16–72 رمزاً: حرف ورقم ورمز، بلا مسافات',
    );
    expect(pinField, findsOneWidget);
    final pin = (tester.widget<TextFormField>(pinField).controller!).text;
    expect(pin.length, 16);
    expect(RegExp(r'[A-Za-z]').hasMatch(pin), isTrue);
    expect(RegExp(r'[0-9]').hasMatch(pin), isTrue);
    expect(RegExp(r'[^A-Za-z0-9]').hasMatch(pin), isTrue);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: pinField, matching: find.byType(TextField)),
          )
          .obscureText,
      isTrue,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'مثال: 1001'),
      '2001',
    );
    await _tapText(tester, 'حفظ بيانات الطالب');
    final post = server.requests.lastWhere(
      (r) => r.method == 'POST' && r.url.path == '/api/admin/students',
    );
    final sent = jsonDecode(post.body) as Map<String, dynamic>;
    expect(sent['parent_phone'], '+9647705555555');
    expect(sent['parent_pin'], pin);

    // نافذة إظهار الرمز مرة واحدة.
    expect(find.text('تم الحفظ — سلّم كلمة المرور لولي الأمر'), findsOneWidget);
    final revealed = find.byType(TextField).last;
    expect(tester.widget<TextField>(revealed).controller!.text, pin);
    expect(tester.widget<TextField>(revealed).obscureText, isTrue);
    await tester.tap(find.byTooltip('إظهار').last);
    await _settle(tester);
    expect(tester.widget<TextField>(revealed).obscureText, isFalse);
    await _tapText(tester, 'تم');
    expect(find.text('طالب جديد'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('الطلاب: ولي أمر مسجّل → لا يُولَّد PIN ولا يُرسل', (
    tester,
  ) async {
    final server = await _pumpApp(tester);
    await _tapText(tester, 'الطلاب وأولياء الأمور');
    await _tapText(tester, 'إضافة طالب جديد');

    await tester.enterText(
      find.widgetWithText(TextFormField, 'مثال: ريان فهد الحارثي'),
      'أخ لعمر',
    );
    await _tapText(tester, 'اختيار ولي أمر مسجّل');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'اسم ولي الأمر، الابن أو رقم الهاتف'),
      'عمر',
    );
    await _settle(tester);
    await _capture(tester, 'parent_picker_debug');
    final parentChoice = find.widgetWithText(ListTile, 'فيصل المنصور');
    expect(parentChoice, findsOneWidget);
    await tester.tap(parentChoice);
    await _settle(tester);
    await _settle(tester);

    final pinField = find.widgetWithText(TextFormField, 'فارغ = بدون تغيير');
    expect(pinField, findsNothing);
    expect(find.text('سيُربط الطالب بحساب ولي الأمر المسجّل'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'مثال: 1001'),
      '2001',
    );
    await _tapText(tester, 'حفظ بيانات الطالب');
    final post = server.requests.lastWhere(
      (r) => r.method == 'POST' && r.url.path == '/api/admin/students',
    );
    expect((jsonDecode(post.body) as Map).containsKey('parent_pin'), isFalse);
    expect(jsonDecode(post.body)['parent_phone'], '+9647701111111');
    expect(jsonDecode(post.body)['parent_name'], 'فيصل المنصور');
    expect(find.text('تم الحفظ — سلّم كلمة المرور لولي الأمر'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('الحضور: ترتيب الحاضرين، وإلغاء إجازة', (tester) async {
    final server = await _pumpApp(tester);
    server.leaves.add('3|${_todayStr()}'); // زيد في إجازة
    await _tapText(tester, 'الحضور والاجازات');

    // الحاضر الأحدث دخولاً (ليان 08:41) فوق (عمر 07:12).
    final lian = tester.getTopLeft(find.text('ليان سعود المطيري').first).dy;
    final omar = tester.getTopLeft(find.text('عمر فيصل المنصور').first).dy;
    expect(lian, lessThan(omar));
    expect(find.text('08:41 AM'), findsOneWidget);
    expect(find.text('إلغاء الإجازة'), findsOneWidget);
    expect(find.text('تسجيل عذر'), findsOneWidget); // كريم غائب

    await _tapText(tester, 'إلغاء الإجازة');
    await _tapText(tester, 'نعم، ألغِ الإجازة');
    expect(
      server.requests.any(
        (r) => r.method == 'DELETE' && r.url.path == '/api/admin/leaves',
      ),
      isTrue,
    );
    expect(server.leaves, isEmpty);
    await _dispose(tester);
  });

  testWidgets('الأجهزة: تحذير قبل التعطيل، وتعديل جزئي', (tester) async {
    final server = await _pumpApp(tester);
    await _tapText(tester, 'الأجهزة وبوابات الحضور');

    expect(find.text('ZK-0001'), findsOneWidget);
    expect(find.text('مفعّل'), findsOneWidget);
    expect(find.text('آخر مزامنة'), findsOneWidget);
    // لا عناصر محذوفة من التصميم.
    expect(find.textContaining('Ping'), findsNothing);
    expect(find.textContaining('IP'), findsNothing);
    expect(find.text('متصل'), findsNothing);

    await tester.tap(find.byTooltip('تعطيل الجهاز'));
    await _settle(tester);
    expect(
      find.textContaining('لن تُحفظ بصمات هذا الجهاز أثناء تعطيله'),
      findsOneWidget,
    );

    await _tapText(tester, 'نعم، عطّل الجهاز');
    final put = server.requests.lastWhere(
      (r) => r.method == 'PUT' && r.url.path == '/api/admin/devices',
    );
    expect(jsonDecode(put.body), {
      'serial_number': 'ZK-0001',
      'is_active': false,
    });
    expect(server.devices.first['is_active'], isFalse);
    await _dispose(tester);
  });

  testWidgets('الإعدادات: حقلان فقط (الاسم والواتساب) بلا حقول محذوفة', (
    tester,
  ) async {
    final server = await _pumpApp(tester);
    await _tapText(tester, 'الإعدادات العامة');

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.textContaining('موعد'), findsNothing);
    expect(find.textContaining('البريد'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.textContaining('إشعار'),
      ),
      findsNothing,
    );

    final whatsapp = find.widgetWithText(TextFormField, '07749078969');
    expect(whatsapp, findsOneWidget); // يُعرض بصيغة محلية

    await tester.enterText(whatsapp, '07700000000');
    await tester.pump();
    await _tapText(tester, 'حفظ التغييرات');
    expect(server.settings['whatsapp_number'], '+9647700000000');
    await _dispose(tester);
  });

  testWidgets('انتهاء الجلسة (401) يعيد لشاشة الدخول', (tester) async {
    final server = await _pumpApp(tester);
    // نُبطل التوكن في الخادم: أي طلب موثّق يصير 401.
    server.requests.clear();
    final services = AppScope.of(tester.element(find.byType(AppShell)));
    services.client.token = 'expired';
    await _tapText(tester, 'الطلاب وأولياء الأمور');
    expect(find.text('مرحباً بك مجدداً في بوابة الإدارة'), findsOneWidget);
    await _dispose(tester);
  });
}

String _todayStr() {
  final d = DateTime.now().toUtc().add(const Duration(hours: 3));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
