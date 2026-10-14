import 'dart:math';

/// كلمة مرور جديدة: ASCII مطبوع دون مسافات مع حرف ورقم ورمز.
/// يضمن كل نوع، ثم يخلط المواضع بالمصدر الآمن نفسه.
String generateParentPin() {
  final random = Random.secure();
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  const digits = '0123456789';
  final symbols = String.fromCharCodes([
    for (var code = 33; code <= 126; code++)
      if (!RegExp(r'[A-Za-z0-9]').hasMatch(String.fromCharCode(code))) code,
  ]);
  final all = '$letters$digits$symbols';
  final chars = [
    letters[random.nextInt(letters.length)],
    digits[random.nextInt(digits.length)],
    symbols[random.nextInt(symbols.length)],
    for (var i = 3; i < 16; i++) all[random.nextInt(all.length)],
  ];
  for (var i = chars.length - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final swap = chars[i];
    chars[i] = chars[j];
    chars[j] = swap;
  }
  return chars.join();
}

bool isValidParentPin(String pin) =>
    pin.length >= 16 &&
    pin.length <= 72 &&
    pin.codeUnits.every((code) => code >= 33 && code <= 126) &&
    RegExp(r'[A-Za-z]').hasMatch(pin) &&
    RegExp(r'[0-9]').hasMatch(pin) &&
    RegExp(r'[^A-Za-z0-9]').hasMatch(pin);
