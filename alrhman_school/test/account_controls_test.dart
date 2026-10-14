import 'dart:convert';

import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/api_exception.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/app_scope.dart';
import 'package:alrhman_school/data/parent_data.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:alrhman_school/services/push_device.dart';
import 'package:alrhman_school/widgets/account_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const profile = ParentProfile(
  id: 1,
  name: 'ولي الأمر',
  phone: '+9647701111111',
);
http.Response response(
  Object body, [
  int status = 200,
  Map<String, String>? headers,
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
);

class TestPush extends UnavailablePushDevice {
  bool deleted = false;
  @override
  Future<String?> token() async => 'test-fcm-registration-token-0001';
  @override
  Future<PhoneNotificationPermission> permission() async =>
      PhoneNotificationPermission.denied;
  @override
  Future<void> deleteToken() async {
    deleted = true;
  }
}

ParentApi apiFor(
  Future<http.Response> Function(http.Request) handler,
  MemorySessionStore store, {
  PushDevice? push,
}) {
  final api = ParentApi(
    ApiClient(baseUrl: 'https://fake.test', client: MockClient(handler)),
    store,
    pushDevice: push,
  );
  api.client.token = 'parent-token';
  api.parent = profile;
  return api;
}

Future<void> pumpControls(WidgetTester tester, ParentApi api) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      services: AppServices(api),
      child: MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NotificationsSettings(data: ParentData(api)),
              DeleteAccountTile(data: ParentData(api)),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'successful delete returns to login and removes the confirmation route',
    (tester) async {
      final store = MemorySessionStore();
      await store.save(const StoredSession('parent-token', profile));
      final api = apiFor((r) async {
        if (r.url.path.endsWith('notification-settings')) {
          return response({
            'data': {'push_enabled': true},
          });
        }
        if (r.url.path.endsWith('account/delete')) {
          return response({'status': 'success', 'message': 'Account deleted'});
        }
        return response({'data': {}});
      }, store);
      await pumpControls(tester, api);
      await tester.tap(find.text('حذف حساب ولي الأمر'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '123654');
      await tester.tap(find.widgetWithText(FilledButton, 'حذف الحساب نهائياً'));
      // Login includes repeating animations, so advance a bounded number of frames.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('رقم الهاتف'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(await store.read(), isNull);
      expect(api.client.token, isNull);
    },
  );
  for (final scenario in [
    (400, 'pin is required'),
    (400, 'Incorrect PIN'),
    (400, 'Invalid request body'),
    (429, 'Too many failed login attempts. Try again later.'),
    (500, 'Internal error'),
  ]) {
    test(
      'delete ${scenario.$1} ${scenario.$2} preserves session and cached data',
      () async {
        final store = MemorySessionStore();
        await store.save(const StoredSession('parent-token', profile));
        final api = apiFor((r) async {
          expect(r.method, 'POST');
          expect(r.url.path, '/api/mobile/account/delete');
          expect(r.headers['Authorization'], 'Bearer parent-token');
          expect(jsonDecode(r.body), {'pin': ' 4321 '});
          return response(
            {'status': 'error', 'message': scenario.$2},
            scenario.$1,
            {'retry-after': '121'},
          );
        }, store);
        var cleared = false;
        api.onSessionCleared = () => cleared = true;
        var unauthorized = false;
        api.client.onUnauthorized = () => unauthorized = true;
        await expectLater(
          api.deleteAccount(' 4321 '),
          throwsA(
            isA<ApiException>().having(
              (e) => e.retryAfterSeconds,
              'Retry-After',
              121,
            ),
          ),
        );
        expect(api.client.token, 'parent-token');
        expect(await store.read(), isNotNull);
        expect(api.parent, profile);
        expect(cleared, isFalse);
        expect(unauthorized, isFalse);
      },
    );
  }

  for (final status in [401, 403]) {
    test('delete $status invokes session expiration', () async {
      final store = MemorySessionStore();
      await store.save(const StoredSession('parent-token', profile));
      final api = apiFor(
        (_) async => response({'message': 'Unauthorized'}, status),
        store,
      );
      var expired = false;
      api.client.onUnauthorized = () {
        expired = true;
        api.clearSession();
      };
      await expectLater(
        api.deleteAccount('4321'),
        throwsA(isA<ApiException>()),
      );
      expect(expired, isTrue);
      expect(api.client.token, isNull);
      expect(await store.read(), isNull);
    });
  }

  test(
    'successful deletion wipes session and memory without device-token DELETE',
    () async {
      final store = MemorySessionStore();
      await store.save(const StoredSession('parent-token', profile));
      final requests = <http.Request>[];
      final push = TestPush();
      final api = apiFor(
        (r) async {
          requests.add(r);
          return response({'status': 'success', 'message': 'Account deleted'});
        },
        store,
        push: push,
      );
      final data = ParentData(api)..unreadCount = 7;
      await api.deleteAccount('123654');
      expect(requests.length, 1);
      expect(api.client.token, isNull);
      expect(api.parent, isNull);
      expect(await store.read(), isNull);
      expect(data.unreadCount, 0);
      expect(data.students, isEmpty);
      expect(push.deleted, isTrue);
    },
  );

  test(
    'device-token registered false is a successful result with JSON body',
    () async {
      final api = apiFor(
        (r) async {
          expect(r.method, 'PUT');
          expect(r.url.path, '/api/mobile/device-token');
          expect(r.headers['content-type'], 'application/json');
          expect(jsonDecode(r.body), {
            'token': 'test-fcm-registration-token-0001',
          });
          return response({'status': 'success', 'registered': false});
        },
        MemorySessionStore(),
        push: TestPush(),
      );
      expect(await api.refreshDeviceRegistration(), isFalse);
      expect(api.deviceRegistered, isFalse);
    },
  );

  testWidgets(
    'enable saves true before registering device; OS denial is independent',
    (tester) async {
      final requests = <http.Request>[];
      final api = apiFor(
        (r) async {
          requests.add(r);
          if (r.url.path.endsWith('device-token')) {
            return response({'registered': true});
          }
          return response({
            'data': {'push_enabled': r.method == 'PUT'},
          });
        },
        MemorySessionStore(),
        push: TestPush(),
      );
      await pumpControls(tester, api);
      expect(find.textContaining('غير مسموح'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(requests.map((r) => '${r.method} ${r.url.path}').toList(), [
        'GET /api/mobile/notification-settings',
        'PUT /api/mobile/notification-settings',
        'PUT /api/mobile/device-token',
      ]);
      expect(jsonDecode(requests[1].body), {'push_enabled': true});
      expect(tester.widget<Switch>(find.byType(Switch)).value, true);
      expect(find.textContaining('غير مسموح'), findsOneWidget);
    },
  );

  testWidgets(
    'disable needs warning confirmation; cancellation sends nothing',
    (tester) async {
      final requests = <http.Request>[];
      final api = apiFor((r) async {
        requests.add(r);
        return response({
          'data': {'push_enabled': r.method == 'GET'},
        });
      }, MemorySessionStore());
      await pumpControls(tester, api);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.textContaining('لن ترن'), findsOneWidget);
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(requests.length, 1);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إيقاف الإشعارات'));
      await tester.pumpAndSettle();
      expect(requests.length, 2);
      expect(jsonDecode(requests.last.body), {'push_enabled': false});
    },
  );

  for (final status in [400, 429]) {
    testWidgets('delete dialog requires PIN and stays open on $status', (
      tester,
    ) async {
      final requests = <http.Request>[];
      final store = MemorySessionStore();
      final api = apiFor((r) async {
        requests.add(r);
        if (r.method == 'GET') {
          return response({
            'data': {'push_enabled': true},
          });
        }
        return response(
          {
            'message': status == 400
                ? 'Incorrect PIN'
                : 'Too many failed login attempts. Try again later.',
          },
          status,
          {'retry-after': '121'},
        );
      }, store);
      await pumpControls(tester, api);
      await tester.tap(find.text('حذف حساب ولي الأمر'));
      await tester.pumpAndSettle();
      expect(find.textContaining('جميع الأبناء'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'حذف الحساب نهائياً'));
      await tester.pumpAndSettle();
      expect(requests.length, 1);
      await tester.enterText(find.byType(TextField), ' 4321 ');
      await tester.tap(find.widgetWithText(FilledButton, 'حذف الحساب نهائياً'));
      await tester.pumpAndSettle();
      expect(jsonDecode(requests.last.body), {'pin': ' 4321 '});
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(api.client.token, 'parent-token');
      expect(
        find.text(
          status == 400
              ? 'رمز PIN غير صحيح، حاول مرة أخرى'
              : 'محاولات دخول خاطئة كثيرة، حاول بعد 3 دقيقة',
        ),
        findsOneWidget,
      );
    });
  }
}
