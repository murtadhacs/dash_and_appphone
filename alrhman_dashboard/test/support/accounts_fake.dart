import 'dart:convert';

import 'package:http/http.dart' as http;

/// جزء المعلمين والأقساط والمصروفات من الخادم الوهمي، بقواعد عقد API 1.20–1.22.
/// بيانات تجريبية فقط؛ لا شيء من الإنتاج.
class AccountsFake {
  AccountsFake(this._students);

  /// طلاب الخادم الوهمي (id, name, grade, section, rfid_tag).
  final List<Map<String, dynamic>> Function() _students;

  String academicYear = '2026-2027';
  final Map<String, int> gradeFees = {};
  final Map<int, Map<String, dynamic>> accounts = {};
  final Set<int> leftStudents = {};
  int _payId = 1, _expId = 1, _teacherId = 1, _catId = 8;

  final List<Map<String, dynamic>> teachers = [];
  final List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'رواتب', 'is_salary': true},
    {'id': 2, 'name': 'إيجار', 'is_salary': false},
    {'id': 3, 'name': 'مولد كهرباء', 'is_salary': false},
    {'id': 4, 'name': 'تواصل اجتماعي', 'is_salary': false},
    {'id': 5, 'name': 'كافتريا', 'is_salary': false},
    {'id': 6, 'name': 'إنترنت', 'is_salary': false},
    {'id': 7, 'name': 'أخرى', 'is_salary': false},
  ];
  final List<Map<String, dynamic>> expenses = [];

  String today = '2026-10-31';

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
  static http.Response _err(int s, String m) =>
      _json({'status': 'error', 'message': m}, s);

  http.Response? handle(
    String m,
    String path,
    Map<String, String> q,
    Map<String, dynamic> Function() body,
  ) {
    switch ((m, path)) {
      case ('GET', '/api/admin/teachers'):
        return _teachersList(q);
      case ('POST', '/api/admin/teachers'):
        return _teacherWrite(body(), create: true);
      case ('PUT', '/api/admin/teachers'):
        return _teacherWrite(body(), create: false);
      case ('GET', '/api/admin/teachers/specializations'):
        return _json({
          'status': 'success',
          'data': ['الرياضيات', 'العلوم', 'اللغة العربية'],
        });
      case ('GET', '/api/admin/teachers/attendance'):
        return _json({
          'status': 'success',
          'date': q['date'] ?? today,
          'school_day': true,
          'day_type': 'school',
          'day_title': null,
          'day_notes': null,
          'data': [
            for (final t in teachers.where((t) => t['status'] == 'active'))
              {
                'teacher_id': t['id'],
                'full_name': t['full_name'],
                'status': t['status'],
                'first_punch': null,
                'last_punch': null,
                'punch_count': 0,
                'not_punched': true,
              },
          ],
        });
      case ('GET', '/api/admin/tuition'):
        return _tuitionList(q);
      case ('GET', '/api/admin/tuition/student'):
        final id = int.tryParse(q['student_id'] ?? '');
        if (id == null) {
          return _err(400, 'student_id must be a positive student id');
        }
        final s = _student(id);
        return s == null
            ? _err(404, 'Student not found')
            : _json({
                'status': 'success',
                'academic_year': academicYear,
                'data': _detail(id),
              });
      case ('GET', '/api/admin/tuition/fees'):
        final grades = {
          ...gradeFees.keys,
          for (final s in _students()) s['grade'] as String,
        }.toList()..sort();
        return _json({
          'status': 'success',
          'academic_year': academicYear,
          'data': [
            for (final g in grades)
              {'grade': g, 'fee': gradeFees[g], 'updated_at': null},
          ],
        });
      case ('PUT', '/api/admin/tuition/fees'):
        return _setFee(body());
      case ('PUT', '/api/admin/tuition/discount'):
        return _setDiscount(body());
      case ('POST', '/api/admin/tuition/payments'):
        return _pay(body());
      case ('POST', '/api/admin/tuition/payments/void'):
        return _voidPayment(body());
      case ('GET', '/api/admin/expenses'):
        return _expensesList(q);
      case ('POST', '/api/admin/expenses'):
        return _createExpense(body());
      case ('POST', '/api/admin/expenses/void'):
        return _voidExpense(body());
      case ('GET', '/api/admin/expenses/categories'):
        return _json({'status': 'success', 'data': categories});
      case ('POST', '/api/admin/expenses/categories'):
        final name = ((body()['name'] ?? '') as String).trim();
        if (name.isEmpty) return _err(400, 'name is required');
        if (categories.any((c) => c['name'] == name)) {
          return _err(409, 'name is already used by another category');
        }
        final c = {'id': _catId++, 'name': name, 'is_salary': false};
        categories.add(c);
        return _json({
          'status': 'success',
          'message': 'Category added',
          'data': c,
        });
      case ('GET', '/api/admin/expenses/summary'):
        return _summary(q);
    }
    return null;
  }

  // ----------------------------------------------------------- المعلمون

  http.Response _teachersList(Map<String, String> q) {
    var list = teachers.where((t) {
      if (q['status'] != null && t['status'] != q['status']) return false;
      if (q['id'] != null && '${t['id']}' != q['id']) return false;
      final s = q['search'];
      if (s != null && s.isNotEmpty) {
        return (t['full_name'] as String).contains(s) ||
            (t['phone'] as String).contains(s);
      }
      return true;
    }).toList();
    if (q['id'] != null && list.isEmpty) return _err(404, 'Teacher not found');
    list.sort(
      (a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String),
    );
    return _json({'status': 'success', 'data': list});
  }

  String? _phone(String raw) {
    final d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final n = d.startsWith('00964')
        ? d.substring(5)
        : d.startsWith('964')
        ? d.substring(3)
        : d.startsWith('0')
        ? d.substring(1)
        : d;
    return RegExp(r'^7[0-9]{9}$').hasMatch(n) ? '+964$n' : null;
  }

  http.Response _teacherWrite(Map<String, dynamic> b, {required bool create}) {
    for (final f in [
      'first_name',
      'father_name',
      'grandfather_name',
      'phone',
      'gender',
    ]) {
      if (((b[f] ?? '') as String).trim().isEmpty) {
        return _err(400, '$f is required');
      }
    }
    final phone = _phone(b['phone'] as String);
    if (phone == null) {
      return _err(
        400,
        'phone must be an Iraqi mobile number, for example 07XXXXXXXXX or +9647XXXXXXXXX',
      );
    }
    final rfid = (b['rfid_tag'] as String?)?.trim();
    if (rfid != null &&
        rfid.isNotEmpty &&
        !RegExp(r'^[1-9][0-9]?$').hasMatch(rfid)) {
      return _err(
        400,
        "rfid_tag must be the teacher's user ID on the device: 1 to 99, digits only, not starting with 0",
      );
    }
    final id = create ? null : b['id'] as int?;
    if (!create && !teachers.any((t) => t['id'] == id)) {
      return _err(404, 'Teacher not found');
    }
    if (teachers.any((t) => t['id'] != id && t['phone'] == phone)) {
      return _err(409, 'phone is already used by another teacher');
    }
    if (rfid != null && rfid.isNotEmpty) {
      if (teachers.any((t) => t['id'] != id && t['rfid_tag'] == rfid)) {
        return _err(409, 'rfid_tag is already used by another teacher');
      }
      if (_students().any((s) => s['rfid_tag'] == rfid)) {
        return _err(409, 'rfid_tag is already used by a student');
      }
    }
    String? blank(String k) {
      final v = (b[k] as String?)?.trim();
      return v == null || v.isEmpty ? null : v;
    }

    final rec = {
      'id': id ?? _teacherId++,
      'first_name': (b['first_name'] as String).trim(),
      'father_name': (b['father_name'] as String).trim(),
      'grandfather_name': (b['grandfather_name'] as String).trim(),
      'full_name':
          '${(b['first_name'] as String).trim()} ${(b['father_name'] as String).trim()} ${(b['grandfather_name'] as String).trim()}',
      'phone': phone,
      'gender': b['gender'],
      'status': b['status'] ?? 'active',
      'specialization': blank('specialization'),
      'notes': blank('notes'),
      'rfid_tag': rfid == null || rfid.isEmpty ? null : rfid,
      'created_at': '2026-10-29T09:15:04+03:00',
      'updated_at': '2026-10-29T09:15:04+03:00',
    };
    if (create) {
      teachers.add(rec);
    } else {
      teachers[teachers.indexWhere((t) => t['id'] == id)] = rec;
    }
    return _json({
      'status': 'success',
      'message': create ? 'Teacher created' : 'Teacher updated',
      'data': rec,
    });
  }

  // ------------------------------------------------------------ الأقساط

  Map<String, dynamic>? _student(int id) {
    for (final s in _students()) {
      if (s['id'] == id) return s;
    }
    return null;
  }

  int _paid(int id) {
    final a = accounts[id];
    if (a == null) return 0;
    return [
      for (final p in a['payments'] as List<Map<String, dynamic>>)
        if (p['status'] == 'active') p['amount'] as int,
    ].fold(0, (x, y) => x + y);
  }

  Map<String, dynamic> _row(int id) {
    final s = _student(id)!;
    final a = accounts[id];
    final grade = (a?['grade'] ?? s['grade']) as String?;
    final fee = a != null ? a['fee'] as int? : gradeFees[grade];
    final discount = (a?['discount'] ?? 0) as int;
    final paid = _paid(id);
    return {
      'student_id': id,
      'full_name': s['name'],
      'grade': grade,
      'section': s['section'],
      'is_active': !leftStudents.contains(id),
      'fee': fee,
      'discount': discount,
      'paid': paid,
      'remaining': fee == null ? null : fee - discount - paid,
      'fee_set': fee != null,
    };
  }

  Map<String, dynamic> _detail(int id) => {
    ..._row(id),
    'discount_note': accounts[id]?['note'],
    'payments': [
      ...(accounts[id]?['payments'] as List? ?? const []),
    ].reversed.toList(),
  };

  http.Response _tuitionList(Map<String, String> q) {
    var rows = [for (final s in _students()) _row(s['id'] as int)];
    rows = rows.where((r) {
      if (q['grade'] != null && r['grade'] != q['grade']) return false;
      if (q['section'] != null && r['section'] != q['section']) return false;
      if (q['search'] != null &&
          !(r['full_name'] as String).contains(q['search']!)) {
        return false;
      }
      if (q['has_remaining'] == 'true') {
        final rem = r['remaining'] as int?;
        if (rem == null || rem <= 0) return false;
      }
      return true;
    }).toList();
    int sum(String k) => rows.fold(0, (a, r) => a + ((r[k] as int?) ?? 0));
    return _json({
      'status': 'success',
      'academic_year': academicYear,
      'summary': {
        'total_fee': sum('fee'),
        'total_discount': sum('discount'),
        'total_collected': sum('paid'),
        'total_remaining': sum('remaining'),
        'not_set_count': rows.where((r) => r['fee'] == null).length,
      },
      'data': rows,
    });
  }

  http.Response _setFee(Map<String, dynamic> b) {
    final fee = b['fee'];
    if (fee is! int || fee < 1 || fee > 1000000000) {
      return _err(400, 'fee must be from 1 to 1000000000');
    }
    final grade = ((b['grade'] ?? '') as String).trim();
    if (grade.isEmpty) return _err(400, 'grade is required');
    var updated = 0;
    if (b['apply_to_existing'] == true) {
      final bad = <int>[];
      for (final e in accounts.entries) {
        if (e.value['grade'] != grade) continue;
        final rem = fee - (e.value['discount'] as int) - _paid(e.key);
        if (rem < 0) bad.add(e.key);
      }
      if (bad.isNotEmpty) {
        return _err(
          409,
          'apply_to_existing would make ${bad.length} balances negative (student ids: ${bad.join(', ')})',
        );
      }
      for (final e in accounts.entries) {
        if (e.value['grade'] == grade) {
          e.value['fee'] = fee;
          updated++;
        }
      }
    }
    gradeFees[grade] = fee;
    return _json({
      'status': 'success',
      'message': 'Fee saved',
      'data': {
        'academic_year': academicYear,
        'grade': grade,
        'fee': fee,
        'updated_accounts': updated,
      },
    });
  }

  Map<String, dynamic> _account(int id) => accounts.putIfAbsent(id, () {
    final s = _student(id)!;
    return {
      'grade': s['grade'],
      'fee': gradeFees[s['grade']],
      'discount': 0,
      'note': null,
      'payments': <Map<String, dynamic>>[],
    };
  });

  http.Response _setDiscount(Map<String, dynamic> b) {
    final id = b['student_id'] as int?;
    final discount = b['discount'];
    if (id == null || _student(id) == null) {
      return _err(404, 'Student not found');
    }
    if (discount is! int || discount < 0 || discount > 1000000000) {
      return _err(400, 'discount must be from 0 to 1000000000');
    }
    final a = _account(id);
    final fee = a['fee'] as int?;
    if (fee == null) return _err(409, 'Set the fee for this grade first');
    if (discount > fee) return _err(409, 'Discount exceeds the fee');
    if (discount > fee - _paid(id)) {
      return _err(409, 'Discount exceeds the remaining balance');
    }
    a['discount'] = discount;
    final note = (b['note'] as String?)?.trim();
    a['note'] = note == null || note.isEmpty ? null : note;
    return _json({
      'status': 'success',
      'message': 'Discount saved',
      'academic_year': academicYear,
      'data': _detail(id),
    });
  }

  http.Response _pay(Map<String, dynamic> b) {
    final id = b['student_id'] as int?;
    final amount = b['amount'];
    if (id == null || _student(id) == null) {
      return _err(404, 'Student not found');
    }
    if (amount is! int || amount < 1 || amount > 1000000000) {
      return _err(400, 'amount must be from 1 to 1000000000');
    }
    final paidAt = (b['paid_at'] as String?) ?? today;
    if (paidAt.compareTo(today) > 0) {
      return _err(400, 'paid_at cannot be in the future');
    }
    final a = _account(id);
    final fee = a['fee'] as int?;
    if (fee == null) return _err(409, 'Set the fee for this grade first');
    if (amount > fee - (a['discount'] as int) - _paid(id)) {
      return _err(409, 'Payment exceeds the remaining balance');
    }
    (a['payments'] as List<Map<String, dynamic>>).add({
      'id': _payId++,
      'amount': amount,
      'paid_at': paidAt,
      'note': (b['note'] as String?)?.trim().isEmpty ?? true ? null : b['note'],
      'status': 'active',
      'created_at': '${today}T09:30:00+03:00',
      'voided_at': null,
      'void_reason': null,
    });
    return _json({
      'status': 'success',
      'message': 'Payment recorded',
      'academic_year': academicYear,
      'data': _detail(id),
    });
  }

  http.Response _voidPayment(Map<String, dynamic> b) {
    final reason = ((b['reason'] ?? '') as String).trim();
    if (reason.isEmpty) return _err(400, 'reason is required');
    for (final e in accounts.entries) {
      for (final p in e.value['payments'] as List<Map<String, dynamic>>) {
        if (p['id'] != b['id']) continue;
        if (p['status'] == 'voided') {
          return _err(409, 'Payment is already voided');
        }
        p['status'] = 'voided';
        p['voided_at'] = '${today}T10:00:00+03:00';
        p['void_reason'] = reason;
        return _json({
          'status': 'success',
          'message': 'Payment voided',
          'academic_year': academicYear,
          'data': _detail(e.key),
        });
      }
    }
    return _err(404, 'Payment not found');
  }

  // --------------------------------------------------------- المصروفات

  Map<String, dynamic>? _cat(int? id) {
    for (final c in categories) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  http.Response _createExpense(Map<String, dynamic> b) {
    final cat = _cat(b['category_id'] as int?);
    if (cat == null) return _err(404, 'Category not found');
    final amount = b['amount'];
    if (amount is! int || amount < 1 || amount > 1000000000) {
      return _err(400, 'amount must be from 1 to 1000000000');
    }
    final date = (b['expense_date'] as String?) ?? today;
    if (date.compareTo(today) > 0) {
      return _err(400, 'expense_date cannot be in the future');
    }
    Map<String, dynamic>? teacher;
    if (b['teacher_id'] != null) {
      if (cat['is_salary'] != true) {
        return _err(409, 'teacher_id is allowed only for the salary category');
      }
      teacher = teachers.cast<Map<String, dynamic>?>().firstWhere(
        (t) => t!['id'] == b['teacher_id'],
        orElse: () => null,
      );
      if (teacher == null) return _err(404, 'Teacher not found');
    }
    final e = {
      'id': _expId++,
      'category': {'id': cat['id'], 'name': cat['name']},
      'amount': amount,
      'expense_date': date,
      'note': b['note'],
      'teacher': teacher == null
          ? null
          : {'id': teacher['id'], 'full_name': teacher['full_name']},
      'academic_year': academicYear,
      'status': 'active',
      'created_at': '${today}T10:00:00+03:00',
      'voided_at': null,
      'void_reason': null,
    };
    expenses.add(e);
    return _json({
      'status': 'success',
      'message': 'Expense recorded',
      'data': e,
    });
  }

  http.Response _voidExpense(Map<String, dynamic> b) {
    final reason = ((b['reason'] ?? '') as String).trim();
    if (reason.isEmpty) return _err(400, 'reason is required');
    for (final e in expenses) {
      if (e['id'] != b['id']) continue;
      if (e['status'] == 'voided') {
        return _err(409, 'Expense is already voided');
      }
      e['status'] = 'voided';
      e['voided_at'] = '${today}T11:00:00+03:00';
      e['void_reason'] = reason;
      return _json({
        'status': 'success',
        'message': 'Expense voided',
        'data': e,
      });
    }
    return _err(404, 'Expense not found');
  }

  http.Response _expensesList(Map<String, String> q) {
    final list =
        expenses.where((e) {
          if (q['category_id'] != null &&
              '${(e['category'] as Map)['id']}' != q['category_id']) {
            return false;
          }
          if (q['month'] != null &&
              !(e['expense_date'] as String).startsWith(q['month']!)) {
            return false;
          }
          if (q['teacher_id'] != null &&
              '${(e['teacher'] as Map?)?['id']}' != q['teacher_id']) {
            return false;
          }
          return true;
        }).toList()..sort((a, b) {
          final c = (b['expense_date'] as String).compareTo(
            a['expense_date'] as String,
          );
          return c != 0 ? c : (b['id'] as int).compareTo(a['id'] as int);
        });
    final total = list
        .where((e) => e['status'] == 'active')
        .fold<int>(0, (a, e) => a + (e['amount'] as int));
    return _json({
      'status': 'success',
      'academic_year': academicYear,
      'summary': {'total': total},
      'data': list,
    });
  }

  http.Response _summary(Map<String, String> q) {
    final catId = int.tryParse(q['category_id'] ?? '');
    if (q['category_id'] != null && catId == null) {
      return _err(400, 'category_id must be a positive category id');
    }
    if (catId != null && _cat(catId) == null) {
      return _err(404, 'Category not found');
    }
    final active = expenses.where((e) => e['status'] == 'active').toList();
    int exp(Iterable<Map<String, dynamic>> l) =>
        l.fold(0, (a, e) => a + (e['amount'] as int));
    final scoped = catId == null
        ? active
        : active.where((e) => (e['category'] as Map)['id'] == catId).toList();
    var collected = 0;
    for (final a in accounts.values) {
      for (final p in a['payments'] as List<Map<String, dynamic>>) {
        if (p['status'] == 'active') collected += p['amount'] as int;
      }
    }
    final months = {
      for (final e in scoped) (e['expense_date'] as String).substring(0, 7),
    }.toList()..sort();
    return _json({
      'status': 'success',
      'academic_year': academicYear,
      'category_id': catId,
      'totals': {
        'expenses': exp(scoped),
        'collected': catId == null ? collected : null,
        'difference': catId == null ? collected - exp(scoped) : null,
      },
      'by_category': [
        for (final c in categories)
          if (catId == null || c['id'] == catId)
            {
              'category_id': c['id'],
              'name': c['name'],
              'total': exp(
                active.where((e) => (e['category'] as Map)['id'] == c['id']),
              ),
            },
      ],
      'by_month': [
        for (final mo in months)
          {
            'month': mo,
            'expenses': exp(
              scoped.where((e) => (e['expense_date'] as String).startsWith(mo)),
            ),
            'collected': null,
            'difference': null,
          },
      ],
    });
  }
}
