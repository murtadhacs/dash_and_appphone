/// خطأ من الـ API أو من الاتصال بالخادم.
class ApiException implements Exception {
  /// رمز HTTP، أو null عند فشل الاتصال أصلاً.
  final int? statusCode;

  /// رسالة عربية صالحة للعرض على المستخدم.
  final String message;

  /// رسالة الخادم الأصلية (للتشخيص فقط، غالباً بالإنجليزية).
  final String? serverMessage;

  /// ثوانٍ للانتظار عند 429.
  final int? retryAfterSeconds;
  final List<Map<String, dynamic>> errors;
  final String? suggestedRfidTag;

  const ApiException({
    this.statusCode,
    required this.message,
    this.serverMessage,
    this.retryAfterSeconds,
    this.errors = const [],
    this.suggestedRfidTag,
  });

  bool get isNetwork => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message [$serverMessage]';
}
