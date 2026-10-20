import 'dart:convert';
import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/models/activity_log.dart';
import 'package:alrhman_dashboard/screens/activity_log_screen.dart';
import 'package:alrhman_dashboard/widgets/common/pill.dart';
import 'package:alrhman_dashboard/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> item(
  int id, {
  String action = 'leave.create',
  String result = 'success',
  String? detail,
}) => {
  'id': id,
  'created_at': '2026-10-13T09:15:04+03:00',
  'actor': action == 'login.failed' ? 'unknown' : 'admin',
  'action': action,
  'method': 'POST',
  'path': '/api/admin/leaves',
  'status': result == 'success'
      ? 200
      : result == 'rejected'
      ? 409
      : 500,
  'result': result,
  'ip': null,
  'target_type': null,
  'target_id': null,
  'detail': detail,
};
http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));
  test(
    'labels cover documented actions; unknown actions and nullable fields survive',
    () {
      expect(activityActionLabels.length, 24);
      final deletion = ActivityLogItem.fromJson({
        ...item(3, action: 'parent.account_delete', detail: 'اسم الابن'),
        'actor': 'parent',
        'target_type': 'student',
        'target_id': '42',
      });
      expect(deletion.actor, 'parent');
      expect(deletion.ip, isNull);
      expect(deletion.actionLabel, 'حذف ولي الأمر لحسابه');
      expect(deletion.detail, 'اسم الابن');
      final unknown = ActivityLogItem.fromJson(
        item(1, action: 'future.operation', detail: 'kind=pause dry_run'),
      );
      expect(unknown.actionLabel, 'future.operation');
      expect(unknown.isPreview, true);
      expect(unknown.targetLabel, isEmpty);
      expect(unknown.ip, isNull);
      expect(unknown.baghdadTime.hour, 9);
      expect(unknown.baghdadTime.minute, 15);
      final failedLogin = ActivityLogItem.fromJson(
        item(2, action: 'login.failed', result: 'rejected'),
      );
      expect(failedLogin.actor, 'unknown');
      expect(failedLogin.actionLabel, 'محاولة دخول فاشلة');
    },
  );

  test(
    'API uses GET, preserves 50 entries and passes next_before verbatim',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((r) async {
          requests.add(r);
          return response({
            'data': [for (var i = 100; i > 50; i--) item(i)],
            'has_more': true,
            'next_before': 51,
          });
        }),
      )..token = 'test-token';
      final api = AdminApi(client, MemoryTokenStore());
      final page = await api.activityLog();
      expect(page.items.length, 50);
      expect(page.items.first.id, 100);
      expect(page.hasMore, true);
      expect(requests.first.url.queryParameters, isEmpty);
      await api.activityLog(before: page.nextBefore);
      expect(requests.last.method, 'GET');
      expect(requests.last.url.path, '/api/admin/activity-log');
      expect(requests.last.url.queryParameters, {'before': '51'});
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
    },
  );

  testWidgets(
    'pagination retries preserve rows, results and preview; no write requests',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final requests = <http.Request>[];
      bool fail = true;
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((r) async {
          requests.add(r);
          if (r.url.queryParameters['before'] == '48') {
            if (fail) {
              fail = false;
              return response({'message': 'server unavailable'}, 500);
            }
            return response({
              'data': [item(40, action: 'new.code', result: 'failed')],
              'has_more': false,
              'next_before': null,
            });
          }
          return response({
            'data': [
              item(50, detail: 'date=2026-10-13 dry_run'),
              item(48, action: 'login.failed', result: 'rejected'),
            ],
            'has_more': true,
            'next_before': 48,
          });
        }),
      );
      final store = MemoryTokenStore();
      final api = AdminApi(client, store);
      await tester.pumpWidget(
        AppScope(
          services: AppServices(client, api, store),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ActivityLogScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'الوقت (بغداد)',
        'المنفذ',
        'العملية',
        'الهدف',
        'النتيجة',
        'عنوان IP',
        'التفاصيل',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('dry_run'), findsOneWidget);
      expect(find.text('unknown'), findsOneWidget);
      expect(find.text('2026-10-13 09:15:04'), findsNWidgets(2));
      final success = tester.widget<Pill>(find.widgetWithText(Pill, 'نجاح'));
      final rejected = tester.widget<Pill>(
        find.widgetWithText(Pill, 'مرفوض'),
      );
      expect(success.background, AppColors.okBg);
      expect(rejected.background, AppColors.warnBg);
      await tester.tap(find.text('تحميل المزيد من السجلات'));
      await tester.pumpAndSettle();
      expect(find.text('تسجيل إجازة'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      await tester.tap(find.text('إعادة المحاولة'));
      await tester.pumpAndSettle();
      expect(find.text('new.code'), findsOneWidget);
      expect(find.text('تحميل المزيد من السجلات'), findsNothing);
      expect(
        tester.widget<Pill>(find.widgetWithText(Pill, 'فشل')).background,
        AppColors.badBg,
      );
      expect(requests.map((r) => r.url.queryParameters['before']).toList(), [
        null,
        '48',
        '48',
      ]);
      expect(requests.every((r) => r.method == 'GET'), true);
      expect(tester.takeException(), isNull);
    },
  );
}
