/// تطبيع أرقام الهواتف العراقية إلى الصيغة القياسية `+9647XXXXXXXXX`
/// (مطابقاً لما يقبله الـ API: 07…، +9647…، 009647…، 9647…، وأرقام عربية/فارسية).
class IraqiPhone {
  IraqiPhone._();

  static final _canonical = RegExp(r'^\+9647[0-9]{9}$');

  /// يرجع الرقم بالصيغة القياسية، أو null إن لم يكن رقماً عراقياً صالحاً.
  static String? normalize(String input) {
    final digits = _toLatinDigits(input).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    String national;
    if (digits.startsWith('00964')) {
      national = digits.substring(5);
    } else if (digits.startsWith('964')) {
      national = digits.substring(3);
    } else if (digits.startsWith('0')) {
      national = digits.substring(1);
    } else {
      national = digits;
    }
    // يُتسامح بصفر بعد رمز الدولة.
    if (national.startsWith('0')) national = national.substring(1);

    final result = '+964$national';
    return _canonical.hasMatch(result) ? result : null;
  }

  /// يعرض الرقم القياسي بصيغة محلية `07XXXXXXXXX` للقراءة.
  static String display(String canonical) {
    if (_canonical.hasMatch(canonical)) return '0${canonical.substring(4)}';
    return canonical;
  }

  static String _toLatinDigits(String s) {
    final b = StringBuffer();
    for (final r in s.runes) {
      if (r >= 0x0660 && r <= 0x0669) {
        b.writeCharCode(r - 0x0660 + 0x30); // الأرقام العربية-الهندية
      } else if (r >= 0x06F0 && r <= 0x06F9) {
        b.writeCharCode(r - 0x06F0 + 0x30); // الأرقام الفارسية
      } else {
        b.writeCharCode(r);
      }
    }
    return b.toString();
  }
}
