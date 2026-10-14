import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const fakeToken = 'fake-admin-token';

/// خادم وهمي في الذاكرة يطبّق جزء الإدارة من عقد Future Kids API.
class FakeServer {
  final List<Map<String, dynamic>> students = [
    {
      'id': 1,
      'name': 'عمر فيصل المنصور',
      'parent_name': 'فيصل المنصور',
      'parent_phone': '+9647701111111',
      'rfid_tag': '1001',
      'grade': 'روضة 1',
      'section': 'شعبة أ',
    },
    {
      'id': 2,
      'name': 'ليان سعود المطيري',
      'parent_name': 'سعود المطيري',
      'parent_phone': '+9647702222222',
      'rfid_tag': '1002',
      'grade': 'روضة 2',
      'section': 'شعبة ب',
    },
    {
      'id': 3,
      'name': 'زيد ريان الشمري',
      'parent_name': 'مها القحطاني',
      'parent_phone': '+9647703333333',
      'rfid_tag': 'admin-3',
      'grade': 'الصف الثالث الابتدائي',
      'section': 'شعبة أ',
    },
    {
      'id': 4,
      'name': 'كريم إبراهيم الحازمي',
      'parent_name': 'إبراهيم الحازمي',
      'parent_phone': '+9647704444444',
      'rfid_tag': '1004',
      'grade': 'روضة 2',
      'section': 'شعبة أ',
    },
  ];

  /// بصمات اليوم: id → [دخول، خروج].
  final Map<int, List<String?>> punches = {
    1: ['07:12 AM', null],
    2: ['08:41 AM', null],
  };
  final Set<String> leaves = {}; // "id|date"
  final Map<String, String> settings = {
    'school_name': 'الرحمن الابتدائية',
    'whatsapp_number': '+9647749078969',
  };
  final List<Map<String, dynamic>> devices = [
    {
      'serial_number': 'ZK-0001',
      'location_name': 'المدخل الرئيسي',
      'is_active': true,
      'last_sync': '2026-10-08 07:31:02',
    },
  ];

  /// كل الطلبات الواردة، لفحصها في الاختبارات.
  final List<http.Request> requests = [];

  int _nextId = 10;

  String _today() {
    final d = DateTime.now().toUtc().add(const Duration(hours: 3));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  late final MockClient client = MockClient((req) async {
    requests.add(req);
    return _handle(req);
  });

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  http.Response _err(int status, String message) =>
      _json({'status': 'error', 'message': message}, status);

  List<Map<String, dynamic>> _attendance(String date) {
    final list = [...students]
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return [
      for (final s in list)
        () {
          final id = s['id'] as int;
          String status;
          String? inT;
          String? outT;
          if (leaves.contains('$id|$date')) {
            status = 'Excused';
          } else if (punches.containsKey(id) && date == _today()) {
            status = 'Present';
            inT = punches[id]![0];
            outT = punches[id]![1];
          } else {
            status = 'Absent';
          }
          return {
            'student_id': id,
            'full_name': s['name'],
            'status': status,
            'check_in_time': inT,
            'check_out_time': outT,
          };
        }(),
    ];
  }

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path;
    final q = req.url.queryParameters;
    final m = req.method;
    Map<String, dynamic> body() =>
        req.body.isEmpty ? {} : jsonDecode(req.body) as Map<String, dynamic>;

    if (path == '/api/admin/login' && m == 'POST') {
      final b = body();
      return b['username'] == 'admin' && b['password'] == 'admin'
          ? _json({
              'status': 'success',
              'data': {'token': fakeToken},
            })
          : _err(401, 'بيانات الدخول غير صحيحة');
    }

    if (req.headers['Authorization'] != 'Bearer $fakeToken') {
      return _err(401, 'Unauthorized');
    }

    switch ((m, path)) {
      case ('GET', '/api/admin/holidays'):
        return _json({'status': 'success', 'data': []});
      case ('GET', '/api/admin/dashboard'):
        final att = _attendance(_today());
        int c(String s) => att.where((a) => a['status'] == s).length;
        return _json({
          'status': 'success',
          'date': _today(),
          'data': {
            'total_students': students.length,
            'total_parents': students
                .map((s) => s['parent_phone'])
                .toSet()
                .length,
            'present_today': c('Present'),
            'excused_today': c('Excused'),
            'absent_today': c('Absent'),
          },
        });
      case ('GET', '/api/admin/students'):
        return _json({'status': 'success', 'data': students.reversed.toList()});
      case ('POST', '/api/admin/students'):
        final b = body();
        final known = students.map((s) => s['parent_phone']).toSet();
        final pin = (b['parent_pin'] ?? '') as String;
        if ((!known.contains(b['parent_phone']) || pin.isNotEmpty) &&
            !(pin.length >= 16 &&
                pin.length <= 72 &&
                pin.codeUnits.every((c) => c >= 33 && c <= 126) &&
                RegExp(r'[A-Za-z]').hasMatch(pin) &&
                RegExp(r'[0-9]').hasMatch(pin) &&
                RegExp(r'[^A-Za-z0-9]').hasMatch(pin))) {
          return _err(400, 'parent_pin is required for a new parent');
        }
        final s = {
          'id': _nextId,
          'name': b['name'],
          'parent_name': b['parent_name'],
          'parent_phone': b['parent_phone'],
          'rfid_tag': (b['rfid_tag'] as String?) ?? 'admin-$_nextId',
          'grade': b['grade'],
          'section': b['section'],
        };
        _nextId++;
        students.add(s);
        return _json({
          'status': 'success',
          'message': 'Student created',
          'data': s,
        });
      case ('DELETE', '/api/admin/students'):
        students.removeWhere((s) => '${s['id']}' == q['id']);
        return _json({'status': 'success', 'message': 'Student deleted'});
      case ('GET', '/api/admin/attendance'):
        final d = q['date'] ?? _today();
        return _json({'status': 'success', 'date': d, 'data': _attendance(d)});
      case ('POST', '/api/admin/leaves'):
        final b = body();
        leaves.add('${b['student_id']}|${b['leave_date']}');
        return _json({
          'status': 'success',
          'message': 'Leave recorded successfully',
          'data': {'leave_id': 1},
        });
      case ('DELETE', '/api/admin/leaves'):
        leaves.remove('${q['student_id']}|${q['date']}');
        return _json({'status': 'success', 'message': 'No leave remains'});
      case ('GET', '/api/admin/settings'):
        return _json({'status': 'success', 'data': settings});
      case ('PUT', '/api/admin/settings'):
        final b = body();
        settings[b['key'] as String] = (b['value'] ?? '') as String;
        return _json({'status': 'success', 'message': 'Setting saved'});
      case ('GET', '/api/admin/devices'):
        return _json({'status': 'success', 'data': devices});
      case ('POST', '/api/admin/devices'):
        final b = body();
        devices.add({
          'serial_number': b['serial_number'],
          'location_name': b['location_name'] ?? '',
          'is_active': b['is_active'] ?? true,
        });
        return _json({
          'status': 'success',
          'message': 'Device added successfully',
        });
      case ('PUT', '/api/admin/devices'):
        final b = body();
        for (final d in devices) {
          if (d['serial_number'] == b['serial_number']) {
            if (b.containsKey('location_name')) {
              d['location_name'] = b['location_name'];
            }
            if (b.containsKey('is_active')) {
              d['is_active'] = b['is_active'];
            }
          }
        }
        return _json({
          'status': 'success',
          'message': 'Device updated successfully',
        });
    }
    return _err(404, 'Not found');
  }
}
