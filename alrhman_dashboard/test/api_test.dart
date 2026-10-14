import 'dart:convert';

import 'package:alrhman_dashboard/api/admin_api.dart';
import 'package:alrhman_dashboard/api/api_client.dart';
import 'package:alrhman_dashboard/api/api_exception.dart';
import 'package:alrhman_dashboard/api/token_store.dart';
import 'package:alrhman_dashboard/models/attendance_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// طلب مسجَّل من العميل الوهمي.
class _Call {
  final http.Request request;
  _Call(this.request);
  Map<String, dynamic> get body =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

class _Setup {
  final AdminApi api;
  final ApiClient client;
  final List<_Call> calls;
  final MemoryTokenStore store;
  _Setup(this.api, this.client, this.calls, this.store);
}

_Setup _setup(http.Response Function(http.Request) handler) {
  final calls = <_Call>[];
  final mock = MockClient((req) async {
    calls.add(_Call(req));
    return handler(req);
  });
  final client = ApiClient(baseUrl: 'https://api.test', client: mock);
  final store = MemoryTokenStore();
  return _Setup(AdminApi(client, store), client, calls, store);
}

http.Response jsonResponse(
  Object body, [
  int status = 200,
  Map<String, String>? headers,
]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
);

Map<String, dynamic> studentJson({
  String phone = '+9647700000001',
  String rfid = 'admin-1',
}) => {
  'id': 1,
  'name': 'س',
  'parent_name': 'و',
  'parent_phone': phone,
  'rfid_tag': rfid,
  'grade': null,
  'section': null,
};

void main() {
  setUpAll(() async => initializeDateFormatting());

  test('تسجيل الدخول يحفظ التوكن ويرسله Bearer في الطلبات التالية', () async {
    final t = _setup((req) {
      if (req.url.path == '/api/admin/login') {
        return jsonResponse({
          'status': 'success',
          'data': {'token': 'TKN'},
        });
      }
      return jsonResponse({'status': 'success', 'data': []});
    });

    await t.api.login('admin', 'pw');
    expect(await t.store.readToken(), 'TKN');
    expect(t.calls.first.request.headers['Authorization'], isNull);

    await t.api.students();
    expect(t.calls.last.request.headers['Authorization'], 'Bearer TKN');
  });

  test('401 على طلب موثَّق يستدعي onUnauthorized', () async {
    final t = _setup(
      (_) => jsonResponse({'status': 'error', 'message': 'Unauthorized'}, 401),
    );
    var called = false;
    t.client.onUnauthorized = () => called = true;
    t.client.token = 'old';

    await expectLater(t.api.students(), throwsA(isA<ApiException>()));
    expect(called, isTrue);
  });

  test('401 في تسجيل الدخول يعرض رسالة الخادم ولا يُعدّ انتهاء جلسة', () async {
    final t = _setup(
      (_) => jsonResponse({
        'status': 'error',
        'message': 'بيانات الدخول غير صحيحة',
      }, 401),
    );
    var expired = false;
    t.client.onUnauthorized = () => expired = true;

    try {
      await t.api.login('a', 'b');
      fail('يجب أن يرمي');
    } on ApiException catch (e) {
      expect(e.message, 'بيانات الدخول غير صحيحة');
    }
    expect(expired, isFalse);
  });

  test('429 يعرض دقائق الانتظار من Retry-After', () async {
    final t = _setup(
      (_) => jsonResponse(
        {'status': 'error', 'message': 'x'},
        429,
        {'retry-after': '600'},
      ),
    );
    try {
      await t.api.login('a', 'b');
      fail('يجب أن يرمي');
    } on ApiException catch (e) {
      expect(e.statusCode, 429);
      expect(e.message, contains('10 دقيقة'));
    }
  });

  test('رد غير JSON (502) لا يكسر العميل', () async {
    final t = _setup((_) => http.Response('<html>Bad gateway</html>', 502));
    t.client.token = 't';
    try {
      await t.api.dashboard();
      fail('يجب أن يرمي');
    } on ApiException catch (e) {
      expect(e.statusCode, 502);
      expect(e.message, contains('غير متاح'));
    }
  });

  test('إضافة طالب لولي أمر مسجّل ترسل رقم الجهاز دون parent_pin', () async {
    final t = _setup(
      (_) => jsonResponse({
        'status': 'success',
        'message': 'ok',
        'data': studentJson(),
      }),
    );
    t.client.token = 't';
    await t.api.createStudent(
      name: 'س',
      parentName: 'و',
      parentPhone: '+9647700000001',
      rfidTag: '1001',
    );
    expect(t.calls.single.body.containsKey('parent_pin'), isFalse);
    expect(t.calls.single.body['rfid_tag'], '1001');
  });

  test('إضافة طالب لولي أمر جديد ترسل الرمز ومعرّف البصمة', () async {
    final t = _setup(
      (_) => jsonResponse({
        'status': 'success',
        'message': 'ok',
        'data': studentJson(rfid: '10'),
      }),
    );
    t.client.token = 't';
    final s = await t.api.createStudent(
      name: 'س',
      parentName: 'و',
      parentPhone: '+9647700000001',
      parentPin: 'Kq7#vR2m!Tx9pW4z',
      rfidTag: '10',
    );
    expect(t.calls.single.body['parent_pin'], 'Kq7#vR2m!Tx9pW4z');
    expect(t.calls.single.body['rfid_tag'], '10');
    expect(s.rfidTag, '10');
  });

  test('409 عند تكرار معرّف البصمة يعطي رسالة واضحة', () async {
    final t = _setup(
      (_) => jsonResponse({
        'status': 'error',
        'message': 'rfid_tag is already used by another student',
        'suggested_rfid_tag': '11',
      }, 409),
    );
    t.client.token = 't';
    try {
      await t.api.createStudent(
        name: 'س',
        parentName: 'و',
        parentPhone: '+9647700000001',
        rfidTag: '10',
      );
      fail('يجب أن يرمي');
    } on ApiException catch (e) {
      expect(e.studentSaveMessage, contains('معرّف البصمة'));
      expect(e.suggestedRfidTag, '11');
    }
  });

  test(
    'كلمة المرور الفارغة في التعديل لا تُرسل والجديدة تُرسل حرفياً',
    () async {
      final t = _setup((_) => jsonResponse({'status': 'success'}));
      for (final password in [null, '', '${'a' * 70}1!']) {
        await t.api.updateStudent(
          id: 1,
          name: 'س',
          parentName: 'و',
          parentPhone: '+9647700000001',
          parentPin: password,
        );
        if (password == null || password.isEmpty) {
          expect(t.calls.last.body.containsKey('parent_pin'), isFalse);
        } else {
          expect(t.calls.last.body['parent_pin'], password);
        }
      }
    },
  );

  test('400 عند حفظ الطالب يعرض رسالة الخادم', () async {
    const message =
        'parent_pin must be 16 to 72 printable ASCII characters with a letter, digit and symbol';
    final t = _setup((_) => jsonResponse({'message': message}, 400));
    await expectLater(
      t.api.updateStudent(
        id: 1,
        name: 'س',
        parentName: 'و',
        parentPhone: '+9647700000001',
        parentPin: '123456',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.studentSaveMessage,
          'server message',
          message,
        ),
      ),
    );
  });

  test('تعديل جهاز يرسل الحقول المعدّلة فقط', () async {
    final t = _setup(
      (_) => jsonResponse({'status': 'success', 'message': 'ok'}),
    );
    t.client.token = 't';

    await t.api.updateDevice(serialNumber: 'SN1', isActive: false);
    expect(t.calls.last.body, {'serial_number': 'SN1', 'is_active': false});

    await t.api.updateDevice(serialNumber: 'SN1', locationName: 'البوابة');
    expect(t.calls.last.body, {
      'serial_number': 'SN1',
      'location_name': 'البوابة',
    });
  });

  test('إلغاء الإجازة يرسل student_id وdate كـ query', () async {
    final t = _setup(
      (_) => jsonResponse({'status': 'success', 'message': 'ok'}),
    );
    t.client.token = 't';
    await t.api.cancelLeave(studentId: 42, date: DateTime(2026, 9, 21));

    final req = t.calls.single.request;
    expect(req.method, 'DELETE');
    expect(req.url.path, '/api/admin/leaves');
    expect(req.url.queryParameters, {'student_id': '42', 'date': '2026-09-21'});
  });

  test(
    'الحضور: الحاضرون الأحدث دخولاً أولاً ثم المجازون ثم الغائبون',
    () async {
      Map<String, dynamic> e(int id, String n, String st, String? inTime) => {
        'student_id': id,
        'full_name': n,
        'status': st,
        'check_in_time': inTime,
        'check_out_time': null,
      };
      final t = _setup(
        (_) => jsonResponse({
          'status': 'success',
          'date': '2026-09-21',
          'data': [
            e(1, 'أ', 'Present', '07:10 AM'),
            e(2, 'ب', 'Absent', null),
            e(3, 'ج', 'Present', '08:45 AM'),
            e(4, 'د', 'Excused', null),
            e(5, 'هـ', 'Present', '12:05 PM'),
          ],
        }),
      );
      t.client.token = 't';
      final day = await t.api.attendance(DateTime(2026, 9, 21));

      expect(day.ordered.map((x) => x.studentId), [5, 3, 1, 4, 2]);
      expect(day.arrivals.map((x) => x.studentId), [5, 3, 1]);
      expect(day.count(PresenceStatus.present), 3);
    },
  );

  test(
    'تقرير Excel من الخادم: يُقرأ اسم الملف من Content-Disposition',
    () async {
      final t = _setup(
        (_) => http.Response.bytes(
          [1, 2, 3],
          200,
          headers: {
            'content-disposition':
                'attachment; filename=attendance_2026-09-21.xlsx',
          },
        ),
      );
      t.client.token = 't';
      final f = await t.api.exportAttendanceExcel(DateTime(2026, 9, 21));
      expect(f.fileName, 'attendance_2026-09-21.xlsx');
      expect(f.bytes, [1, 2, 3]);
    },
  );
}
