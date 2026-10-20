import 'dart:convert';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/models/broadcast.dart';
import 'package:alrhman_dashboard/screens/broadcasts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'schedule_and_leaves_test.dart' show host, jsonResponse, tap;

Map<String, dynamic> logItem(int id) => {
  'id': id,
  'title': 'اجتماع أولياء الأمور',
  'body': 'الخميس في المدرسة',
  'audience': {'type': 'all'},
  'recipient_count': 24,
  'read_count': 17,
  'created_at': '2026-10-10T09:15:00+03:00',
};

void main() {
  testWidgets(
    'changing audience resets choices and previews exact parent, grade, section and class',
    (t) async {
      t.view.physicalSize = const Size(1100, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final posts = <Map<String, dynamic>>[];
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((req) async {
          if (req.url.path == '/api/admin/students') {
            return jsonResponse({
              'data': [
                for (final id in [1, 2])
                  {
                    'id': id,
                    'name': 'طالب $id',
                    'parent_name': 'ولي أمر',
                    'parent_phone': '+9647000000101',
                    'grade': 'G3',
                    'section': 'A',
                  },
              ],
            });
          }
          if (req.method == 'GET') {
            return jsonResponse({
              'data': [],
              'has_more': false,
              'next_before': null,
            });
          }
          posts.add(jsonDecode(req.body) as Map<String, dynamic>);
          return jsonResponse({
            'data': {'id': null, 'recipient_count': 1, 'dry_run': true},
          });
        }),
      )..token = 'TOKEN';
      final store = MemoryTokenStore();
      await t.pumpWidget(
        host(
          AppScope(
            services: AppServices(client, AdminApi(client, store), store),
            child: SingleChildScrollView(child: const BroadcastsScreen()),
          ),
        ),
      );
      await t.pumpAndSettle();
      await tap(t, 'معاينة وإرسال');
      expect(posts, isEmpty);
      await t.enterText(find.byType(TextFormField).at(0), 'عنوان');
      await t.enterText(find.byType(TextFormField).at(1), 'نص');
      Future<void> pick(String choice) => tap(t, choice);

      Future<void> preview(Map<String, dynamic> expected) async {
        await tap(t, 'معاينة وإرسال');
        expect(posts.last['audience'], expected);
        await tap(t, 'إلغاء');
      }

      await pick('ولي أمر');
      await t.tap(find.byKey(const ValueKey('broadcast-parent')));
      await t.pumpAndSettle();
      await t.tap(find.textContaining('ولي أمر •').last);
      await t.pumpAndSettle();
      await preview({'type': 'parent', 'parent_phone': '+9647000000101'});
      await pick('صف');
      await t.tap(find.byKey(const ValueKey('grade-المرحلة')));
      await t.pumpAndSettle();
      await tap(t, 'G3');
      await preview({'type': 'class', 'grade': 'G3'});
      await pick('شعبة');
      await t.tap(find.byKey(const ValueKey('section-الشعبة')));
      await t.pumpAndSettle();
      await tap(t, 'A');
      await preview({'type': 'class', 'section': 'A'});
      await pick('صف وشعبة');
      await t.tap(find.byKey(const ValueKey('class-المرحلة')));
      await t.pumpAndSettle();
      await tap(t, 'G3');
      await t.tap(find.byKey(const ValueKey('class-الشعبة')));
      await t.pumpAndSettle();
      await tap(t, 'A');
      await preview({'type': 'class', 'grade': 'G3', 'section': 'A'});
      await pick('الجميع');
      await preview({'type': 'all'});
      expect(posts.every((p) => p['dry_run'] == true), true);
      expect(t.takeException(), isNull);
    },
  );
  test('audiences contain only allowed fields and real send omits dry_run', () {
    for (final entry in <String, Map<String, dynamic>>{
      'all': {'type': 'all'},
      'parent': {'type': 'parent', 'parent_phone': '07000000101'},
      'grade': {'type': 'class', 'grade': 'G3'},
      'section': {'type': 'class', 'section': 'A'},
      'class': {'type': 'class', 'grade': 'G3', 'section': 'A'},
    }.entries) {
      final draft = BroadcastDraft(
        title: ' عنوان ',
        body: ' نص ',
        type: entry.key == 'all' || entry.key == 'parent' ? entry.key : 'class',
        phone: '07000000101',
        grade: entry.key == 'section' ? null : 'G3',
        section: entry.key == 'grade' ? null : 'A',
      );
      expect(draft.toJson(dryRun: true), {
        'title': 'عنوان',
        'body': 'نص',
        'audience': entry.value,
        'dry_run': true,
      });
      expect(draft.toJson(dryRun: false).containsKey('dry_run'), false);
    }
  });

  for (final status in [200, 400, 404, 409]) {
    testWidgets('preview, cancel, confirm, log and error $status', (t) async {
      t.view.physicalSize = const Size(1200, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final posts = <Map<String, dynamic>>[];
      final cursors = <String?>[];
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((req) async {
          expect(req.headers['Authorization'], 'Bearer TOKEN');
          if (req.url.path == '/api/admin/students') {
            return jsonResponse({'data': []});
          }
          if (req.method == 'GET') {
            cursors.add(req.url.queryParameters['before']);
            return jsonResponse({
              'data': [
                logItem(req.url.queryParameters['before'] == null ? 120 : 119),
              ],
              'has_more': req.url.queryParameters['before'] == null,
              'next_before': req.url.queryParameters['before'] == null
                  ? 120
                  : null,
            });
          }
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          posts.add(body);
          if (body['dry_run'] != true && status != 200) {
            return jsonResponse({
              'status': 'error',
              'message': status == 400
                  ? 'No parents match this audience'
                  : 'error',
            }, status);
          }
          return jsonResponse({
            'data': {
              'id': body['dry_run'] == true ? null : 121,
              'recipient_count': 24,
              'dry_run': body['dry_run'] == true,
            },
          });
        }),
      )..token = 'TOKEN';
      final store = MemoryTokenStore();
      await t.pumpWidget(
        host(
          AppScope(
            services: AppServices(client, AdminApi(client, store), store),
            child: SingleChildScrollView(child: const BroadcastsScreen()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('قرأه 17 من 24 من أولياء الأمور'), findsOneWidget);
      await tap(t, 'تحميل إشعارات أقدم');
      expect(cursors, [null, '120']);
      await t.enterText(find.byType(TextFormField).at(0), 'عنوان جديد');
      await t.enterText(find.byType(TextFormField).at(1), 'نص جديد');
      await tap(t, 'معاينة وإرسال');
      expect(
        find.text('سيصل الإشعار إلى 24 من أولياء الأمور ولا يمكن سحبه'),
        findsOneWidget,
      );
      expect(posts.length, 1);
      expect(posts.single['dry_run'], true);
      await tap(t, 'إلغاء');
      expect(posts.length, 1);
      await tap(t, 'معاينة وإرسال');
      await tap(t, 'إرسال الإشعار');
      expect(posts.length, 3);
      expect(posts.last.containsKey('dry_run'), false);
      expect(posts[1]['audience'], posts[2]['audience']);
      expect(posts[1]['title'], posts[2]['title']);
      expect(posts[1]['body'], posts[2]['body']);
      if (status == 200) {
        expect(
          find.text('تم إرسال الإشعار إلى 24 من أولياء الأمور.'),
          findsOneWidget,
        );
      }
      if (status == 400) {
        expect(
          find.text('لا يوجد أولياء أمور ضمن الجمهور المحدد.'),
          findsOneWidget,
        );
      }
      if (status == 404) {
        expect(find.textContaining('ولي الأمر غير موجود'), findsOneWidget);
      }
      if (status == 409) {
        expect(find.textContaining('لم يُرسل مرة أخرى'), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    });
  }
}
