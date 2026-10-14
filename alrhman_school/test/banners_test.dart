import 'dart:convert';

import 'package:alrhman_school/api/api_client.dart';
import 'package:alrhman_school/api/parent_api.dart';
import 'package:alrhman_school/api/session_store.dart';
import 'package:alrhman_school/data/parent_data.dart';
import 'package:alrhman_school/models/models.dart';
import 'package:alrhman_school/widgets/banner_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_server.dart';

void main() {
  testWidgets('a banner with an old action link is display only', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BannerCarousel(
            banners: [
              SchoolBanner(
                id: 1,
                title: 'إعلان',
                imageUrl: '',
                actionLink: 'https://example.com',
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(BannerCarousel),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    final gestures = tester.widgetList<GestureDetector>(
      find.descendant(
        of: find.byType(BannerCarousel),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gestures.every((g) => g.onTap == null), true);
    await tester.tap(find.text('إعلان'));
    expect(tester.takeException(), isNull);
  });

  test(
    'parent refresh GETs new banners, updates image revision and retains banners on failure',
    () async {
      final server = FakeServer();
      var title = 'قديم';
      var failBanners = false;
      var bannerGets = 0;
      final client = ApiClient(
        baseUrl: 'https://fake.test',
        client: MockClient((req) async {
          if (req.url.path != '/api/mobile/banners') {
            final forwarded = http.Request(req.method, req.url)
              ..headers.addAll(req.headers)
              ..bodyBytes = req.bodyBytes;
            return server.client.send(forwarded).then(http.Response.fromStream);
          }
          bannerGets++;
          return http.Response(
            jsonEncode(
              failBanners
                  ? {'status': 'error'}
                  : {
                      'status': 'success',
                      'data': [
                        {
                          'id': 5,
                          'title': title,
                          'image_url': '/api/mobile/banners/image?id=5',
                          'action_link': '',
                        },
                      ],
                    },
            ),
            failBanners ? 503 : 200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final api = ParentApi(client, MemorySessionStore());
      await api.login('07000000101', '4321');
      final data = ParentData(api);
      addTearDown(data.dispose);
      await data.loadAll();
      final firstImage = data.banners.single.imageUrl;
      title = 'جديد';
      await data.refresh();
      expect(data.banners.single.title, 'جديد');
      expect(data.banners.single.imageUrl, isNot(firstImage));
      expect(bannerGets, 2);
      failBanners = true;
      await data.refresh();
      expect(data.banners.single.title, 'جديد');
    },
  );
}
