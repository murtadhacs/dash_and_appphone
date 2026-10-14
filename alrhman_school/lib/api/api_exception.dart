/// خطأ من الـ API أو من الاتصال بالخادم.
class ApiException implements Exception {
  /// رمز HTTP، أو null عند فشل الاتصال أصلاً.
  final int? statusCode;

  /// رسالة عربية صالحة للعرض.
  final String message;

  /// رسالة الخادم الأصلية (للتشخيص فقط).
  final String? serverMessage;

  /// ثوانٍ للانتظار عند 429.
  final int? retryAfterSeconds;

  const ApiException({
    this.statusCode,
    required this.message,
    this.serverMessage,
    this.retryAfterSeconds,
  });

  bool get isNetwork => statusCode == null;

  /// انتهت الجلسة (401) أو التوكن ليس توكن ولي أمر (403): يلزم تسجيل الدخول.
  bool get needsLogin => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'ApiException($statusCode): $message [$serverMessage]';
}
