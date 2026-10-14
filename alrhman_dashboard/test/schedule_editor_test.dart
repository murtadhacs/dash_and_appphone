import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/core/app_theme.dart';
import 'package:alrhman_dashboard/models/navigation_tab.dart';
import 'package:alrhman_dashboard/models/schedule_class.dart';
import 'package:alrhman_dashboard/models/schedule_period.dart';
import 'package:alrhman_dashboard/screens/schedule_screen.dart';
import 'package:alrhman_dashboard/widgets/layout/sidebar.dart';
import 'package:alrhman_dashboard/widgets/layout/app_header.dart';
import 'package:alrhman_dashboard/widgets/schedule/schedule_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

const subjects = [
  'القرآن',
  'اللغة العربية',
  'الرياضيات',
  'العلوم',
  'التربية الفنية',
  'اللغة الإنكليزية',
];
List<Map<String, dynamic>> periods({int days = 5, int count = 6}) => [
  for (final day in scheduleWeekdays.take(days))
    for (var n = 1; n <= count; n++)
      {
        'day_of_week': day,
        'period_number': n,
        'subject_name': subjects[n - 1],
        'teacher_name': 'المعلم أحمد',
        'subject_key': 'other',
      },
];
http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class Server {
  final requests = <http.Request>[];
  final data = <String, List<Map<String, dynamic>>>{};
  bool rejectSave = false;
  bool failPreview = false;
  Server() {
    for (var i = 0; i < 9; i++) {
      data['الصف ${i + 1}/أ'] = i % 3 == 1
          ? []
          : periods(days: i % 3 == 2 ? 2 : 5);
    }
  }
  late final client = ApiClient(
    baseUrl: 'https://fake.test',
    client: MockClient((r) async {
      requests.add(r);
      if (r.url.path.endsWith('/classes')) {
        return jsonResponse({
          'data': [
            for (final entry in data.entries)
              {
                'grade': entry.key.split('/')[0],
                'section': 'أ',
                'student_count': 10,
                'period_count': entry.value.length,
                'day_count': entry.value
                    .map((p) => p['day_of_week'])
                    .toSet()
                    .length,
              },
          ],
        });
      }
      if (r.method == 'GET') {
        if (failPreview) return jsonResponse({'message': 'failed'}, 500);
        return jsonResponse({
          'data':
              data['${r.url.queryParameters['grade']}/${r.url.queryParameters['section']}'] ??
              [],
        });
      }
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      if (rejectSave) {
        return jsonResponse({
          'message': 'day must contain 5 or 6 periods',
        }, 400);
      }
      data['${body['grade']}/${body['section']}'] = (body['periods'] as List)
          .cast<Map<String, dynamic>>();
      return jsonResponse({'data': body['periods']});
    }),
  )..token = 'TOKEN';
  late final store = MemoryTokenStore();
  late final api = AdminApi(client, store);
}

final boundaryKey = GlobalKey();
Future<void> pumpPage(
  WidgetTester t,
  Server server,
  Size size, {
  bool shell = false,
  bool quick = false,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final page = SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: ScheduleScreen(openAddOnStart: quick),
  );
  await t.pumpWidget(
    AppScope(
      services: AppServices(server.client, server.api, server.store),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: AppTheme.light().colorScheme,
          scaffoldBackgroundColor: AppTheme.light().scaffoldBackgroundColor,
          fontFamily: 'Cairo',
          fontFamilyFallback: const ['Roboto'],
        ),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(
            body: shell
                ? Row(
                    children: [
                      if (size.width >= 1024)
                        Sidebar(
                          currentTab: NavigationTab.schedule,
                          onSelectTab: (_) {},
                        ),
                      Expanded(
                        child: Column(
                          children: [
                            AppHeader(
                              username: 'admin',
                              onToggleSidebar: () {},
                              onLogout: () {},
                            ),
                            Expanded(child: page),
                          ],
                        ),
                      ),
                    ],
                  )
                : page,
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, String label) async {
  final finder = find.text(label).last;
  await t.ensureVisible(finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> screenshot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
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
    final font = FontLoader('Cairo');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      final bytes = File('test/fonts/Cairo-$weight.ttf').readAsBytesSync();
      font.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await font.load();
    final fontsPath =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      Future.value(
        ByteData.sublistView(
          File('$fontsPath/materialicons-regular.otf').readAsBytesSync(),
        ),
      ),
    );
    await icons.load();
    final roboto = FontLoader('Roboto');
    for (final weight in ['regular', 'bold']) {
      roboto.addFont(
        Future.value(
          ByteData.sublistView(
            File('$fontsPath/roboto-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    await roboto.load();
  });
  test(
    'GET and PUT retain exact class identifiers and omit read-only subject_key',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((r) async {
          requests.add(r);
          return jsonResponse({'data': periods(days: 1, count: 5)});
        }),
      )..token = 'TOKEN';
      final api = AdminApi(client, MemoryTokenStore());
      const c = ScheduleClass(
        grade: 'G3 ',
        section: 'شعبة أ',
        studentCount: 2,
        periodCount: 5,
        dayCount: 1,
      );
      final rows = await api.schedule(c);
      expect(requests.single.url.queryParameters, {
        'grade': 'G3 ',
        'section': 'شعبة أ',
      });
      await api.saveSchedule(c, rows);
      final body = jsonDecode(requests.last.body) as Map;
      expect(body['grade'], 'G3 ');
      expect(body['section'], 'شعبة أ');
      expect((body['periods'] as List).first.containsKey('subject_key'), false);
      expect(requests.last.method, 'PUT');
      expect(requests.last.headers['Authorization'], 'Bearer TOKEN');
    },
  );
  testWidgets(
    'all registered classes, filters, pagination and grid remain connected without Excel',
    (t) async {
      final server = Server();
      await pumpPage(t, server, const Size(1300, 1000));
      expect(find.text('9 صفوف مسجّلة'), findsOneWidget);
      expect(find.text('استيراد'), findsNothing);
      expect(find.text('تصدير'), findsNothing);
      expect(find.textContaining('معاينة جدول الصف 1'), findsOneWidget);
      await tap(t, 'التالي');
      expect(find.text('الصف 7 — أ'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, 'الصف 9');
      await t.pumpAndSettle();
      expect(find.text('الصف 9 — أ'), findsOneWidget);
      await tap(t, 'عرض شبكي');
      expect(find.text('تعديل الجدول'), findsOneWidget);
      await t.tap(find.text('الصف 9 — أ'));
      await t.pumpAndSettle();
      expect(find.textContaining('معاينة جدول الصف 9'), findsOneWidget);
      expect(server.requests.last.url.queryParameters, {
        'grade': 'الصف 9',
        'section': 'أ',
      });
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'edit preserves the other days, confirms the class, handles server errors and reloads',
    (t) async {
      final server = Server();
      await pumpPage(t, server, const Size(1300, 1000));
      await t.ensureVisible(find.text('تعديل').first);
      await t.tap(find.text('تعديل').first);
      await t.pumpAndSettle();
      final field = find.byKey(const ValueKey('subject/الأحد/1'));
      await t.enterText(field, 'الرياضيات المتقدمة');
      await tap(t, 'حفظ الجدول');
      expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
      expect(find.textContaining('الصف: الصف 1 — أ'), findsOneWidget);
      server.rejectSave = true;
      await tap(t, 'تأكيد الحفظ');
      expect(find.text('day must contain 5 or 6 periods'), findsOneWidget);
      server.rejectSave = false;
      await tap(t, 'حفظ الجدول');
      await tap(t, 'تأكيد الحفظ');
      final saved = server.data['الصف 1/أ']!;
      expect(saved.length, 30);
      expect(saved.first['subject_name'], 'الرياضيات المتقدمة');
      expect(saved.where((p) => p['day_of_week'] == 'الإثنين').length, 6);
      expect(find.byType(ScheduleEditorDialog), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'empty class cannot save a gapped day or write after cancelling',
    (t) async {
      final server = Server();
      await pumpPage(t, server, const Size(1300, 1000));
      await tap(t, 'إعداد');
      await tap(t, 'حفظ الجدول');
      expect(find.text('أدخل مادة الحصة 1 ليوم الأحد'), findsOneWidget);
      expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
      await tap(t, 'إلغاء');
      expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
    },
  );
  testWidgets('preview failure allows retry without replacing another class', (
    t,
  ) async {
    final server = Server()..failPreview = true;
    await pumpPage(t, server, const Size(1300, 1000));
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    server.failPreview = false;
    await tap(t, 'إعادة المحاولة');
    expect(find.text('إعادة المحاولة'), findsNothing);
    expect(find.text('اللغة الإنكليزية'), findsWidgets);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'quick schedule requires an explicit class and opens that class only',
    (t) async {
      final server = Server();
      await pumpPage(t, server, const Size(1300, 1000), quick: true);
      expect(find.text('اختر الصف لإعداد جدوله'), findsOneWidget);
      await tap(t, 'الصف 3 — أ');
      expect(find.byType(ScheduleEditorDialog), findsOneWidget);
      expect(server.requests.last.url.queryParameters, {
        'grade': 'الصف 3',
        'section': 'أ',
      });
      expect(server.requests.where((r) => r.method == 'PUT'), isEmpty);
      await tap(t, 'إلغاء');
    },
  );
  for (final size in [const Size(1600, 1100), const Size(390, 1000)]) {
    testWidgets('responsive schedule preview ${size.width}', (t) async {
      final server = Server();
      await pumpPage(t, server, size, shell: true);
      expect(t.takeException(), isNull);
      await t.ensureVisible(find.textContaining('معاينة جدول الصف 1'));
      await t.pumpAndSettle();
      await screenshot(
        t,
        size.width > 1000
            ? 'schedule_desktop_manual'
            : 'schedule_mobile_manual',
      );
    });
  }
}
