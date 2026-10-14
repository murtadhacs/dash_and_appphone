import 'dart:convert';
import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/data/parent_data.dart';
import 'package:alrhman_school/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'support/fake_server.dart';

void main() {
  testWidgets(
    'school broadcast appears in notification list and unread count and can be read',
    (t) async {
      final server = FakeServer();
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((req) async {
          if (req.url.path == '/api/mobile/notifications') {
            return http.Response(
              jsonEncode({
                'data': [
                  {
                    'id': 50,
                    'title': 'اجتماع أولياء الأمور',
                    'body': 'الخميس الساعة العاشرة في المدرسة.',
                    'created_at': '2026-10-10T09:15:00+03:00',
                    'is_read': server.readIds.contains(50),
                  },
                ],
                'unread_count': server.readIds.contains(50) ? 0 : 1,
                'has_more': false,
                'next_before': null,
              }),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          final forwarded = http.Request(req.method, req.url)
            ..headers.addAll(req.headers)
            ..bodyBytes = req.bodyBytes;
          return server.client.send(forwarded).then(http.Response.fromStream);
        }),
      );
      final api = ParentApi(client, MemorySessionStore());
      await api.login('07000000101', '4321');
      final data = ParentData(api);
      addTearDown(data.dispose);
      await data.loadAll();
      expect(data.unreadCount, 1);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NotificationsScreen(data: data)),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('اجتماع أولياء الأمور'), findsOneWidget);
      expect(find.text('الخميس الساعة العاشرة في المدرسة.'), findsOneWidget);
      await data.markRead(data.notifications.single);
      expect(data.unreadCount, 0);
      await data.refresh();
      expect(data.unreadCount, 0);
      expect(data.notifications.single.isRead, true);
      expect(server.readIds.contains(50), true);
      expect(t.takeException(), isNull);
    },
  );
}
