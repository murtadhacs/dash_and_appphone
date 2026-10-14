import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// عنوان الخادم. يُغيَّر عند التشغيل بـ:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://futurekids-staging.up.railway.app',
);

/// عميل HTTP رفيع: يضيف `Authorization: Bearer`، يفك JSON، ويحوّل الأخطاء إلى [ApiException].
class ApiClient {
  ApiClient({
    this.baseUrl = apiBaseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _http = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  String? token;

  /// يُستدعى عند 401/403 على طلب موثَّق (انتهت الجلسة أو تغيّر الرمز).
  void Function()? onUnauthorized;

  /// رابط كامل لمسار نسبي يبدأ بـ `/` (مثل صور البنرات)، وإلا يُعاد كما هو.
  String resolve(String pathOrUrl) {
    if (!pathOrUrl.startsWith('/')) return pathOrUrl;
    return '${baseUrl.replaceAll(RegExp(r'/+$'), '')}$pathOrUrl';
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: '${base.path.replaceAll(RegExp(r'/+$'), '')}$path',
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Map<String, String> _headers({bool json = false, bool auth = true}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (auth && token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) => _send(
    () => _http.get(_uri(path, query), headers: _headers(auth: auth)),
    auth: auth,
  );

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) => _send(
    () => _http.post(
      _uri(path),
      headers: _headers(json: true, auth: auth),
      body: jsonEncode(body),
    ),
    auth: auth,
  );

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) => _send(
    () => _http.put(
      _uri(path, query),
      headers: _headers(json: body != null),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> deleteJson(
    String path,
    Map<String, dynamic> body,
  ) => _send(
    () => _http.delete(
      _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send, {
    bool auth = true,
  }) async {
    http.Response response;
    try {
      response = await send().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        message: 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى',
      );
    } catch (_) {
      throw const ApiException(
        message: 'تعذر الاتصال بالخادم، تحقق من الإنترنت',
      );
    }

    final body = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body == null) {
        throw const ApiException(message: 'استجابة غير متوقعة من الخادم');
      }
      return body;
    }
    throw _toException(response, body, auth: auth);
  }

  Map<String, dynamic>? _decode(http.Response r) {
    try {
      final v = jsonDecode(utf8.decode(r.bodyBytes));
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      // 431 و502/503 من وكيل Railway ليست JSON.
      return null;
    }
  }

  ApiException _toException(
    http.Response r,
    Map<String, dynamic>? body, {
    required bool auth,
  }) {
    final serverMessage = body?['message'] as String?;
    final retry = int.tryParse(r.headers['retry-after'] ?? '');
    final code = r.statusCode;

    if ((code == 401 || code == 403) && auth) {
      onUnauthorized?.call();
      return ApiException(
        statusCode: code,
        message: 'انتهت الجلسة، سجّل الدخول من جديد',
        serverMessage: serverMessage,
      );
    }

    final message = switch (code) {
      400 => switch (serverMessage) {
        'pin is required' => 'أدخل رمز PIN لتأكيد حذف الحساب',
        'Incorrect PIN' => 'رمز PIN غير صحيح، حاول مرة أخرى',
        _ => serverMessage ?? 'بيانات غير صحيحة',
      },
      401 => 'رقم الهاتف أو كلمة المرور غير صحيحة',
      404 => 'العنصر المطلوب غير موجود',
      429 => _tooMany(retry),
      502 || 503 => 'الخادم غير متاح حالياً، حاول بعد قليل',
      >= 500 => 'حدث خطأ في الخادم، حاول لاحقاً',
      _ => 'تعذر تنفيذ الطلب',
    };

    return ApiException(
      statusCode: code,
      message: message,
      serverMessage: serverMessage,
      retryAfterSeconds: retry,
    );
  }

  String _tooMany(int? seconds) {
    if (seconds == null) return 'محاولات كثيرة، حاول لاحقاً';
    final minutes = (seconds / 60).ceil();
    return 'محاولات دخول خاطئة كثيرة، حاول بعد $minutes دقيقة';
  }
}
