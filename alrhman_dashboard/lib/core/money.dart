import 'package:intl/intl.dart';

/// المبالغ في النظام أعداد صحيحة بالدينار العراقي، تُرسل أرقاماً لا نصوصاً.
class Money {
  Money._();

  static const max = 1000000000;
  static final _fmt = NumberFormat('#,##0', 'en');

  /// `1,500,000` بأرقام لاتينية دائماً.
  static String format(int value) => _fmt.format(value);

  /// `1,500,000 د.ع`، وشرطة عندما لا توجد قيمة (null) بدل صفر مضلِّل.
  static String dinar(int? value) =>
      value == null ? '—' : '${format(value)} د.ع';

  /// يقرأ مبلغاً مكتوباً (يتجاهل الفواصل والمسافات والأرقام العربية)،
  /// ويرجع null إن لم يكن عدداً صحيحاً موجباً لا يتجاوز [max].
  static int? parse(String input) {
    final latin = _latinDigits(input).replaceAll(RegExp(r'[,\s٬،]'), '');
    if (!RegExp(r'^[0-9]{1,10}$').hasMatch(latin)) return null;
    final v = int.parse(latin);
    return v >= 1 && v <= max ? v : null;
  }

  /// مثل [parse] لكن الصفر مقبول (للخصم).
  static int? parseAllowZero(String input) {
    final latin = _latinDigits(input).replaceAll(RegExp(r'[,\s٬،]'), '');
    if (latin == '0') return 0;
    return parse(latin);
  }

  static String _latinDigits(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x0660 && r <= 0x0669) {
        b.writeCharCode(r - 0x0660 + 0x30);
      } else if (r >= 0x06F0 && r <= 0x06F9) {
        b.writeCharCode(r - 0x06F0 + 0x30);
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }
}

/// ترتيب الصفوف الدراسية: الخادم يرجعها أبجدياً، والواجهة تعرضها من الأول إلى السادس.
class Grades {
  Grades._();

  static const _ordinals = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  static int rank(String grade) {
    final normalized = grade.replaceAll(RegExp('[إأآ]'), 'ا');
    for (var i = 0; i < _ordinals.length; i++) {
      final w = _ordinals[i].replaceAll(RegExp('[إأآ]'), 'ا');
      if (normalized.contains(w)) return i;
    }
    return _ordinals.length;
  }

  static int compare(String a, String b) {
    final r = rank(a).compareTo(rank(b));
    return r != 0 ? r : a.compareTo(b);
  }

  static List<String> sorted(Iterable<String> grades) =>
      grades.toSet().toList()..sort(compare);
}
