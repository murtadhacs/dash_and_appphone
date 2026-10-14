import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// خادم وهمي في الذاكرة يطبّق جزء ولي الأمر من عقد Future Kids API.
///
/// "اليوم" في البيانات هو الخميس 2026-10-08 (ثبّته في الاختبار عبر BaghdadTime.clock).
class FakeServer {
  static const parent1Phone = '+9647000000101';
  static const parent1Pin = '4321';
  static const parent2Phone = '+9647000000102';
  static const parent2Pin = '123654';

  final requests = <http.Request>[];

  /// عند true: كل طلب موثّق يرجع 401 (انتهاء الجلسة).
  bool expireTokens = false;

  int failedLogins = 0;
  String parent1Credential = parent1Pin;

  final readIds = <int>{1, 2};

  late final MockClient client = MockClient((req) async {
    requests.add(req);
    return _handle(req);
  });

  http.Response _json(
    Object body, [
    int status = 200,
    Map<String, String>? h,
  ]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8', ...?h},
  );

  http.Response _err(int status, String msg, [Map<String, String>? h]) =>
      _json({'status': 'error', 'message': msg}, status, h);

  String? _parentOf(http.Request req) {
    final auth = req.headers['Authorization'] ?? '';
    if (!auth.startsWith('Bearer ')) return null;
    final t = auth.substring(7);
    return (t == 'tok-1' || t == 'tok-2') ? t : null;
  }

  Map<String, dynamic> _rec(
    String date,
    String status, [
    String? inT,
    String? outT,
  ]) => {
    'date': date,
    'status': status,
    'check_in_time': inT,
    'check_out_time': outT,
  };

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path;
    final q = req.url.queryParameters;

    if (path == '/api/mobile/settings') {
      return _json({
        'status': 'success',
        'data': {
          'school_name': 'مدرسة الرحمن الابتدائية',
          'whatsapp_number': '+9647749078969',
        },
      });
    }

    if (path == '/api/mobile/login') {
      final b = jsonDecode(req.body) as Map<String, dynamic>;
      if (failedLogins >= 5) {
        return _err(429, 'Too many', {'retry-after': '540'});
      }
      // الخادم الحقيقي يطبّع الرقم؛ هنا نكتفي بالصيغتين المستخدمتين في الاختبار.
      final phone = (b['phone'] as String).replaceAll(' ', '');
      String? token;
      Map<String, dynamic>? parent;
      if ((phone == parent1Phone || phone == '07000000101') &&
          b['pin'] == parent1Credential) {
        token = 'tok-1';
        parent = {'id': 1, 'name': 'Test Parent', 'phone': parent1Phone};
      } else if ((phone == parent2Phone || phone == '07000000102') &&
          b['pin'] == parent2Pin) {
        token = 'tok-2';
        parent = {'id': 2, 'name': 'Parent Two', 'phone': parent2Phone};
      }
      if (token == null) {
        failedLogins++;
        return _err(401, 'Invalid phone number or PIN');
      }
      return _json({
        'status': 'success',
        'data': {'token': token, 'parent': parent},
      });
    }

    final who = expireTokens ? null : _parentOf(req);
    if (who == null) return _err(401, 'Invalid or expired token');
    final p1 = who == 'tok-1';

    switch ((req.method, path)) {
      case ('GET', '/api/mobile/students'):
        return _json({
          'status': 'success',
          'data': p1
              ? [
                  {
                    'id': 1,
                    'full_name': 'Test Student',
                    'grade': 'G1',
                    'section': 'A',
                    'avatar_url': '',
                  },
                ]
              : [
                  {
                    'id': 2,
                    'full_name': 'Ali Test',
                    'grade': 'G2',
                    'section': 'A',
                    'avatar_url': '',
                  },
                  {
                    'id': 3,
                    'full_name': 'Sara Test',
                    'grade': 'G4',
                    'section': 'B',
                    'avatar_url': '',
                  },
                ],
        });
      case ('GET', '/api/mobile/attendance/today'):
        return _json({
          'status': 'success',
          'date': '2026-10-08',
          'data': p1
              ? [
                  {
                    'student_id': 1,
                    'full_name': 'Test Student',
                    'status': 'Present',
                    'check_in_time': '07:15 AM',
                    'check_out_time': null,
                  },
                ]
              : [
                  {
                    'student_id': 2,
                    'full_name': 'Ali Test',
                    'status': 'Absent',
                    'check_in_time': null,
                    'check_out_time': null,
                  },
                  {
                    'student_id': 3,
                    'full_name': 'Sara Test',
                    'status': 'Excused',
                    'check_in_time': null,
                    'check_out_time': null,
                  },
                ],
        });
      case ('GET', '/api/mobile/holidays'):
        return _json({'status': 'success', 'month': q['month'], 'data': []});
      case ('GET', '/api/mobile/attendance/monthly'):
        final month = q['month'] ?? '2026-10';
        final records = month == '2026-10'
            ? [
                _rec('2026-10-08', 'Present', '07:15 AM'),
                _rec('2026-10-07', 'Present', '09:20 AM', '12:01 PM'),
                _rec('2026-10-06', 'Absent'),
                _rec('2026-10-05', 'Excused'),
                _rec('2026-10-04', 'Absent'),
                _rec('2026-10-01', 'Present', '07:40 AM', '12:30 PM'),
              ]
            : [_rec('2026-09-30', 'Present', '07:30 AM')];
        return _json({
          'status': 'success',
          'month': month,
          'data': [
            for (final s in p1 ? [1] : [2, 3])
              {'student_id': s, 'full_name': 'x', 'records': records},
          ],
        });
      case ('GET', '/api/mobile/schedule'):
        Map<String, dynamic> e(
          int s,
          String day,
          int n,
          String subj,
          String teacher,
        ) => {
          'student_id': s,
          'student_name': 'x',
          'grade': 'G1',
          'section': 'A',
          'day_of_week': day,
          'period_number': n,
          'subject_name': subj,
          'teacher_name': teacher,
        };
        return _json({
          'status': 'success',
          'data': p1
              ? [
                  e(1, 'الأحد', 2, 'العلوم', 'معلمة تجريبية'),
                  e(1, 'الأحد', 1, 'اللغة العربية', ''),
                  e(1, 'الاثنين', 1, 'الرياضيات', 'معلم تجريبي'),
                  e(1, 'Thursday', 1, 'الحاسوب', ''),
                  e(1, 'Thursday', 2, 'التربية الإسلامية', ''),
                  e(1, 'يوم النشاط', 1, 'رحلة', ''),
                ]
              : [e(2, 'الأحد', 1, 'العلوم', '')],
        });
      case ('GET', '/api/mobile/notifications'):
        if (!p1) {
          return _json({
            'status': 'success',
            'data': [],
            'has_more': false,
            'next_before': null,
            'unread_count': 0,
          });
        }
        Map<String, dynamic> n(int id, String title, String body, String at) =>
            {
              'id': id,
              'title': title,
              'body': body,
              'is_read': readIds.contains(id),
              'created_at': at,
            };
        final unread = [3, 4, 2, 1].where((id) => !readIds.contains(id)).length;
        if (q['before'] == null) {
          return _json({
            'status': 'success',
            'data': [
              n(
                4,
                'إشعار دخول',
                'تم تسجيل دخول الطالب Test Student الساعة 07:15',
                '2026-10-08T07:15:04+03:00',
              ),
              n(
                3,
                'إشعار غياب',
                'الطالب Test Student غائب اليوم',
                '2026-10-06T12:00:02+03:00',
              ),
            ],
            'has_more': true,
            'next_before': 3,
            'unread_count': unread,
          });
        }
        return _json({
          'status': 'success',
          'data': [
            n(
              2,
              'إشعار خروج',
              'تم تسجيل خروج الطالب Test Student الساعة 12:01',
              '2026-09-20T12:01:00+03:00',
            ),
          ],
          'has_more': false,
          'next_before': null,
          'unread_count': unread,
        });
      case ('PUT', '/api/mobile/notifications/read'):
        readIds.add(int.parse(q['id']!));
        return _json({
          'status': 'success',
          'message': 'Notification marked as read',
        });
      case ('PUT', '/api/mobile/notifications/read-all'):
        readIds.addAll([1, 2, 3, 4]);
        return _json({
          'status': 'success',
          'data': {'updated': 2},
        });
      case ('GET', '/api/mobile/banners'):
        return _json({
          'status': 'success',
          'data': [
            {
              'id': 2,
              'title': 'رحلة مدرسية',
              'image_url': '/api/mobile/banners/image?id=2',
              'action_link': 'https://example.com/trip',
            },
          ],
        });
    }
    return _err(404, 'Not found');
  }
}
