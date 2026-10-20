// يلتقط صور شاشات اللوحة بعد إعادة التصميم إلى design_previews/redesign/.
// flutter test test/redesign_capture_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/app_shell.dart';
import 'package:alrhman_dashboard/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_server.dart';

final _key = GlobalKey();

Future<void> _loadFonts() async {
  final loader = FontLoader('Cairo');
  for (final f in ['Regular', 'SemiBold', 'Bold']) {
    final bytes = File('test/fonts/Cairo-$f.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  final fontsPath =
      '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File('$fontsPath/materialicons-regular.otf').readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

FakeServer _server() {
  final server = FakeServer();
  const rows = [
    ('زيد علي الشمري', 'علي حسن الشمري', 'الرابع الابتدائي', 'شعبة أ'),
    ('محمد سجاد الربيعي', 'سجاد كريم الربيعي', 'الأول الابتدائي', 'شعبة أ'),
    ('حسن حيدر الكرخي', 'حيدر جاسم الكرخي', 'الثالث الابتدائي', 'شعبة ب'),
    ('عبدالله قاسم التميمي', 'قاسم رائد التميمي', 'الخامس الابتدائي', 'شعبة ج'),
  ];
  for (var i = 0; i < rows.length; i++) {
    final id = 20 + i;
    server.students.add({
      'id': id,
      'name': rows[i].$1,
      'parent_name': rows[i].$2,
      'parent_phone': '+96477010000${i + 10}',
      'rfid_tag': 'RF-${8000 + i}',
      'grade': rows[i].$3,
      'section': rows[i].$4,
    });
    if (i != 3) server.punches[id] = ['07:${20 + i * 4} AM', null];
  }
  return server;
}

Future<void> _pump(
  WidgetTester t, {
  bool loggedIn = true,
  Size size = const Size(1440, 1000),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final server = _server();
  final store = MemoryTokenStore();
  if (loggedIn) await store.save(token: fakeToken, username: 'أ. أحمد السعدي');
  final client = ApiClient(baseUrl: 'https://fake.test', client: server.client);
  final services = AppServices(client, AdminApi(client, store), store);
  await t.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (_, child) => RepaintBoundary(key: _key, child: child!),
        theme: ThemeData(
          fontFamily: 'Cairo',
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.viewport,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
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
  await _settle(t);
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester t, String text) async {
  final f = find.text(text).first;
  await t.ensureVisible(f);
  await t.tap(f);
  await _settle(t);
}

Future<void> _shot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final b = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final file = File('design_previews/redesign/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    img.dispose();
  });
}

Future<void> _end(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadFonts();
  });

  testWidgets('login', (t) async {
    await _pump(t, loggedIn: false);
    await _shot(t, '01_login');
    await _end(t);
  });

  testWidgets('tabs', (t) async {
    await _pump(t);
    await _shot(t, '02_dashboard');
    final tabs = {
      '03_students': 'الطلاب وأولياء الأمور',
      '04_attendance': 'الحضور والاجازات',
      '05_devices': 'الأجهزة وبوابات الحضور',
      '06_comms': 'الإعلانات والإشعارات',
      '07_schedule': 'الجدول الدراسي',
      '08_settings': 'الإعدادات العامة',
      '09_activity': 'سجل النشاط',
    };
    for (final e in tabs.entries) {
      await _tap(t, e.value);
      await _shot(t, e.key);
    }
    await _tap(t, 'الطلاب وأولياء الأمور');
    await _tap(t, 'إضافة طالب جديد');
    await _shot(t, '10_dialog_student');
    await _end(t);
  });

  testWidgets('mobile', (t) async {
    await _pump(t, size: const Size(390, 1500));
    await _shot(t, '11_mobile_dashboard');
    await _end(t);
  });
}
