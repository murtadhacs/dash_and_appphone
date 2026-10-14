import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/app_services.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/models/school_banner.dart';
import 'package:alrhman_dashboard/screens/banners_screen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _png = File('assets/images/logo.png').readAsBytesSync();
Map<String, dynamic> _banner({String title = 'إعلان المدرسة'}) => {
  'id': 5,
  'title': title,
  'is_active': false,
  'image_url': '/api/mobile/banners/image?id=5',
  'image_content_type': 'image/png',
  'image_size_bytes': _png.length,
};
http.Response _json(Object data) => http.Response(
  jsonEncode({'status': 'success', 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final class _MemoryFile extends PlatformFile {
  _MemoryFile(this.bytes);
  final Uint8List bytes;
  @override
  String get name => 'school.png';
  @override
  Uri get uri => Uri.parse('memory:school.png');
  @override
  get xFile => throw UnsupportedError('unused');
  @override
  int lengthSync() => bytes.length;
  @override
  Future<int> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

class _Picker extends FilePickerPlatform {
  Uint8List selected = _png;
  Uint8List? saved;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => [_MemoryFile(selected)];
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    saved = bytes;
    expect(fileName, 'banner_5.png');
    expect(mimeType, 'image/png');
    return Uri.parse('file:///download/banner_5.png');
  }
}

void main() {
  testWidgets(
    'upload validates size, adds image then GETs and downloads it on mobile width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final originalPicker = FilePickerPlatform.instance;
      final picker = _Picker();
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = originalPicker);
      final calls = <http.Request>[];
      var created = false;
      final client = ApiClient(
        baseUrl: 'https://api.test',
        client: MockClient((req) async {
          calls.add(req);
          if (req.url.path.endsWith('/image')) {
            return http.Response.bytes(_png, 200);
          }
          if (req.method == 'POST') {
            created = true;
          }
          return _json(
            req.method == 'GET'
                ? created
                      ? [_banner()]
                      : []
                : _banner(),
          );
        }),
      )..token = 'admin-token';
      addTearDown(client.close);
      final store = MemoryTokenStore();
      await tester.pumpWidget(
        AppScope(
          services: AppServices(client, AdminApi(client, store), store),
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(
              body: SingleChildScrollView(child: BannersScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة إعلان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ الإعلان'));
      await tester.pumpAndSettle();
      expect(find.text('ارفع صورة الإعلان أولاً'), findsOneWidget);
      picker.selected = Uint8List(2097153);
      await tester.tap(find.text('رفع / استبدال الصورة'));
      await tester.pumpAndSettle();
      expect(find.text('حجم الصورة يجب ألا يتجاوز 2 ميجابايت'), findsOneWidget);
      expect(calls.any((req) => req.method == 'POST'), false);
      picker.selected = _png;
      await tester.runAsync(() async {
        await tester.tap(find.text('رفع / استبدال الصورة'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('school.png'), findsOneWidget);
      await tester.tap(find.text('حفظ الإعلان'));
      await tester.pumpAndSettle();
      expect(created, true);
      final post = calls.indexWhere((r) => r.method == 'POST');
      expect(calls[post + 1].method, 'GET');
      expect(calls[post + 1].url.path, '/api/admin/banners');
      await tester.ensureVisible(find.text('تحميل'));
      await tester.tap(find.text('تحميل'));
      await tester.pumpAndSettle();
      expect(picker.saved, _png);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'multipart upload and edit use contract fields and authenticated image GET',
    () async {
      final calls = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'https://api.test',
        client: MockClient((request) async {
          calls.add(request);
          if (request.url.path.endsWith('/image')) {
            return http.Response.bytes(_png, 200);
          }
          return _json(request.method == 'GET' ? [_banner()] : _banner());
        }),
      )..token = 'admin-token';
      addTearDown(client.close);
      final api = AdminApi(client, MemoryTokenStore());
      await api.saveBanner(
        title: ' جديد ',
        isActive: true,
        image: Uint8List.fromList(_png),
        fileName: 'school.png',
      );
      expect(calls.last.method, 'POST');
      expect(calls.last.headers['authorization'], 'Bearer admin-token');
      expect(
        calls.last.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      final upload = latin1.decode(calls.last.bodyBytes);
      expect(upload, contains('name="image"; filename="school.png"'));
      final actionPart = upload
          .split('name="action_link"')
          .last
          .split('\r\n\r\n')
          .skip(1)
          .join('\r\n\r\n');
      expect(actionPart, startsWith('\r\n--'));
      expect(upload, contains('name="is_active"\r\n\r\ntrue'));
      await api.saveBanner(id: 5, title: 'تعديل', isActive: false);
      expect(calls.last.method, 'PUT');
      expect(calls.last.url.queryParameters['id'], '5');
      expect(calls.last.body, isNot(contains('name="image"')));
      final banners = await api.banners();
      expect(banners.single.isActive, false);
      expect(await api.bannerImage(banners.single), _png);
      expect(calls.last.url.path, '/api/admin/banners/image');
      expect(calls.last.headers['authorization'], 'Bearer admin-token');
      await api.deleteBanner(5);
      expect(calls.last.method, 'DELETE');
      expect(calls.last.url.queryParameters['id'], '5');
    },
  );

  test('external legacy images never receive the admin token', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      client: MockClient((request) async {
        expect(request.url.host, 'images.test');
        expect(request.headers['authorization'], isNull);
        return http.Response.bytes(_png, 200);
      }),
    )..token = 'secret';
    addTearDown(client.close);
    final api = AdminApi(client, MemoryTokenStore());
    await api.bannerImage(
      const SchoolBanner(
        id: 1,
        title: '',
        imageUrl: 'https://images.test/banner.png',
        isActive: true,
      ),
    );
  });

  testWidgets(
    'management previews hidden image, edits then GETs, and deletes then GETs',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final calls = <http.Request>[];
      var title = 'إعلان المدرسة';
      var deleted = false;
      final client = ApiClient(
        baseUrl: 'https://api.test',
        client: MockClient((request) async {
          calls.add(request);
          if (request.url.path.endsWith('/image')) {
            return http.Response.bytes(_png, 200);
          }
          if (request.method == 'PUT') title = 'العنوان الجديد';
          if (request.method == 'DELETE') deleted = true;
          return _json(
            request.method == 'GET'
                ? deleted
                      ? []
                      : [_banner(title: title)]
                : _banner(),
          );
        }),
      )..token = 'admin-token';
      addTearDown(client.close);
      final store = MemoryTokenStore();
      await tester.pumpWidget(
        AppScope(
          services: AppServices(client, AdminApi(client, store), store),
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(
              body: SingleChildScrollView(child: BannersScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('مخفي'), findsOneWidget);
      await tester.tap(find.text('معاينة'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('إغلاق'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعديل'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'العنوان الجديد');
      await tester.tap(find.text('حفظ الإعلان'));
      await tester.pumpAndSettle();
      expect(find.text('العنوان الجديد'), findsOneWidget);
      final put = calls.indexWhere((r) => r.method == 'PUT');
      expect(
        calls
            .skip(put + 1)
            .any(
              (r) => r.method == 'GET' && r.url.path == '/api/admin/banners',
            ),
        true,
      );
      await tester.tap(find.text('حذف'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
      await tester.pumpAndSettle();
      expect(find.textContaining('لا توجد إعلانات بعد'), findsOneWidget);
      expect(calls.last.url.path, '/api/admin/banners');
      expect(calls.last.method, 'GET');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
