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

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_server.dart';

const _png = [
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAHCAIAAACOQloVAAAAFklEQVR4nGNkUM5nIAUwkaSaYYRqAADMwwCgc8Qt7QAAAABJRU5ErkJggg==',
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAHCAIAAACOQloVAAAAFklEQVR4nGMU2NnIQApgIkk1wwjVAADB6AFYno0dWgAAAABJRU5ErkJggg==',
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAHCAIAAACOQloVAAAAFklEQVR4nGP8t0ySgRTARJJqhhGqAQBcfAHLyJM6rAAAAABJRU5ErkJggg==',
];

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// بيانات عيّنة للشاشات التي لا يغطيها الخادم الوهمي المشترك.
http.Response? _extra(http.BaseRequest req) {
  final path = req.url.path;
  if (req.method != 'GET') return null;
  switch (path) {
    case '/api/admin/schedule/classes':
      return _json({
        'data': [
          for (final (g, s, st, p, d) in [
            ('الأول الابتدائي', 'شعبة أ', 31, 30, 5),
            ('الأول الابتدائي', 'شعبة ب', 30, 28, 5),
            ('الثاني الابتدائي', 'شعبة أ', 29, 18, 3),
            ('الثالث الابتدائي', 'شعبة أ', 32, 30, 5),
            ('الرابع الابتدائي', 'شعبة ب', 30, 0, 0),
            ('الخامس الابتدائي', 'شعبة أ', 28, 27, 5),
          ])
            {
              'grade': g,
              'section': s,
              'student_count': st,
              'period_count': p,
              'day_count': d,
            },
        ],
      });
    case '/api/admin/schedule':
      const subjects = ['رياضيات', 'عربي', 'علوم', 'إنجليزي', 'تربية إسلامية', 'اجتماعيات'];
      const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
      return _json({
        'data': [
          for (var d = 0; d < days.length; d++)
            for (var n = 1; n <= 6; n++)
              {
                'day_of_week': days[d],
                'period_number': n,
                'subject_name': subjects[(d + n * 2) % 6],
                'teacher_name': 'أ. معلم ${n + d}',
              },
        ],
      });
    case '/api/admin/banners':
      return _json({
        'data': [
          for (final (i, title, active) in [
            (1, 'بداية الفصل الدراسي الثاني', true),
            (2, 'عطلة نصف السنة', true),
            (3, 'حفل تكريم المتفوقين', false),
          ])
            {
              'id': i,
              'title': title,
              'image_url': '/api/admin/banners/image?id=$i',
              'is_active': active,
              'image_content_type': 'image/png',
              'image_size_bytes': 860000 + i * 210000,
            },
        ],
      });
    case '/api/admin/banners/image':
      final id = int.tryParse(req.url.queryParameters['id'] ?? '') ?? 1;
      return http.Response.bytes(
        base64Decode(_png[(id - 1) % _png.length]),
        200,
        headers: {'content-type': 'image/png'},
      );
    case '/api/admin/broadcasts':
      return _json({
        'data': [
          {
            'id': 1,
            'title': 'تذكير بموعد اجتماع أولياء الأمور',
            'body': 'نود تذكيركم بموعد الاجتماع يوم الأحد القادم في تمام الساعة 10 صباحاً.',
            'audience': {'type': 'all'},
            'recipient_count': 418,
            'read_count': 312,
            'created_at': '2026-10-20T06:10:00Z',
          },
          {
            'id': 2,
            'title': 'امتحان شهري',
            'body': 'يبدأ الامتحان الشهري للصف الخامس يوم الثلاثاء.',
            'audience': {'type': 'class', 'grade': 'الخامس الابتدائي'},
            'recipient_count': 92,
            'read_count': 54,
            'created_at': '2026-10-15T05:05:00Z',
          },
        ],
        'has_more': true,
        'next_before': 1,
      });
    case '/api/admin/activity-log':
      return _json({
        'data': [
          for (final (i, action, result, detail) in [
            (9, 'student.create', 'success', null),
            (8, 'leave.create', 'success', null),
            (7, 'holiday.create', 'success', 'dry_run'),
            (6, 'device.update', 'success', null),
            (5, 'broadcast.send', 'failed', 'push provider timeout'),
            (4, 'login.failed', 'rejected', null),
          ])
            {
              'id': i,
              'created_at': '2026-10-20T0${i - 3}:12:44Z',
              'actor': 'admin',
              'action': action,
              'method': 'POST',
              'path': '/api/admin/x',
              'status': result == 'success' ? 200 : 400,
              'result': result,
              'ip': '192.168.1.20',
              'target_type': 'student',
              'target_id': '$i',
              'detail': detail,
            },
        ],
        'has_more': true,
        'next_before': 3,
      });
  }
  return null;
}

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
  final lucidePath =
      '${Platform.environment['LOCALAPPDATA']}/Pub/Cache/hosted/pub.dev/lucide_icons_flutter-4.0.1/assets/lucide.ttf';
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      Future.value(ByteData.sublistView(File(lucidePath).readAsBytesSync())),
    );
  await lucide.load();
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
  Size size = const Size(1440, 1100),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final server = _server();
  final store = MemoryTokenStore();
  if (loggedIn) await store.save(token: fakeToken, username: 'أ. أحمد السعدي');
  final client = ApiClient(
    baseUrl: 'https://fake.test',
    client: MockClient((req) async {
      final extra = _extra(req);
      if (extra != null) return extra;
      final copy = http.Request(req.method, req.url)
        ..headers.addAll(req.headers)
        ..bodyBytes = req.bodyBytes;
      return http.Response.fromStream(await server.client.send(copy));
    }),
  );
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
      '03_students': 'الطلاب',
      '04_attendance': 'الحضور والإجازات',
      '05_devices': 'الأجهزة',
      '06_banners': 'التواصل والإعلانات',
      '07_broadcasts': 'الإشعارات الجماعية',
      '08_schedule': 'الجداول الأسبوعية',
      '09_settings': 'إعدادات المدرسة',
      '10_activity': 'سجل النشاط',
    };
    for (final e in tabs.entries) {
      await _tap(t, e.value);
      await _shot(t, e.key);
    }
    await _tap(t, 'الطلاب');
    await _tap(t, 'إضافة طالب');
    await _shot(t, '11_dialog_student');
    await _tap(t, 'إلغاء');
    await _tap(t, 'الأجهزة');
    await _tap(t, 'إضافة جهاز');
    await _shot(t, '12_dialog_device');
    await _tap(t, 'إلغاء');
    await _tap(t, 'الحضور والإجازات');
    await _tap(t, 'إدارة العطل');
    await _shot(t, '13_dialog_holidays');
    await _tap(t, 'إلغاء');
    await _tap(t, 'منح إجازة');
    await _shot(t, '14_dialog_leave');
    await _end(t);
  });

  testWidgets('mobile', (t) async {
    await _pump(t, size: const Size(390, 1500));
    await _shot(t, '11_mobile_dashboard');
    await _end(t);
  });

  for (final width in [390.0, 820.0]) {
    testWidgets('narrow $width: every tab lays out without overflow', (t) async {
      await _pump(t, size: Size(width, 1400));
      for (final label in [
        'الطلاب',
        'الحضور والإجازات',
        'الأجهزة',
        'البنرات',
        'الإشعارات الجماعية',
        'الجداول الأسبوعية',
        'إعدادات المدرسة',
        'سجل النشاط',
      ]) {
        await t.tap(find.byTooltip('القائمة').first);
        await _settle(t);
        await _tap(t, label);
        expect(t.takeException(), isNull, reason: label);
        await _shot(t, 'narrow_${width.toInt()}_$label');
      }
      await _end(t);
    });
  }
}
