import 'dart:async';
import 'dart:convert';

import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:alrhman_school/services/push_device.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class RefreshingPush extends UnavailablePushDevice {
  final refreshes = StreamController<String>.broadcast(sync: true);
  bool requestedPermission = false;
  @override
  Future<void> requestPermission() async {
    requestedPermission = true;
  }

  @override
  Future<String?> token() async => 'initial-fcm-registration-token';
  @override
  Stream<String> get tokenRefresh => refreshes.stream;
}

const parent = ParentProfile(id: 1, name: 'ولي الأمر', phone: '+9647701111111');
http.Response response(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'foreground notification uses FCM title/body and ignores empty messages',
    () {
      final content = ForegroundNotificationContent.fromMessage(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'وصول الابن',
            body: 'وصل الطالب إلى المدرسة',
          ),
        ),
      );
      expect(content!.title, 'وصول الابن');
      expect(content.body, 'وصل الطالب إلى المدرسة');
      expect(
        ForegroundNotificationContent.fromMessage(const RemoteMessage()),
        isNull,
      );
      final dataContent = ForegroundNotificationContent.fromMessage(
        const RemoteMessage(data: {'body': 'انصرف الطالب'}),
      );
      expect(dataContent!.title, 'مدرسة الرحمن');
      expect(dataContent.body, 'انصرف الطالب');
    },
  );

  for (final restore in [false, true]) {
    test(
      '${restore ? 'restored session' : 'login'} requests permission, registers token and sends refreshed token',
      () async {
        final push = RefreshingPush();
        final store = MemorySessionStore();
        if (restore) {
          await store.save(const StoredSession('parent-token', parent));
        }
        final requests = <http.Request>[];
        var registration = Completer<void>();
        final api = ParentApi(
          ApiClient(
            baseUrl: 'https://fake.test',
            client: MockClient((r) async {
              requests.add(r);
              if (r.url.path.endsWith('/login')) {
                return response({
                  'data': {'token': 'parent-token', 'parent': parent.toJson()},
                });
              }
              expect(push.requestedPermission, isTrue);
              if (!registration.isCompleted) registration.complete();
              return response({'status': 'success', 'registered': true});
            }),
          ),
          store,
          pushDevice: push,
        );
        if (restore) {
          await api.restoreSession();
        } else {
          await api.login('07701111111', '4321');
        }
        await registration.future;
        expect(jsonDecode(requests.last.body), {
          'token': 'initial-fcm-registration-token',
        });
        expect(requests.last.method, 'PUT');
        expect(requests.last.url.path, '/api/mobile/device-token');
        expect(requests.last.headers['Authorization'], 'Bearer parent-token');
        registration = Completer<void>();
        push.refreshes.add('refreshed-fcm-registration-token');
        await registration.future;
        expect(jsonDecode(requests.last.body), {
          'token': 'refreshed-fcm-registration-token',
        });
        await api.clearSession();
        final count = requests.length;
        push.refreshes.add('token-after-sign-out');
        await Future<void>.delayed(Duration.zero);
        expect(requests.length, count);
        await push.refreshes.close();
      },
    );
  }
}
