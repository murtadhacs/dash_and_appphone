import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// عنوان الخادم. يُغيَّر عند التشغيل بـ:
/// `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
///
/// قيمة فارغة (`--dart-define=API_BASE_URL=`) تعني "نفس نطاق الموقع": نسخة الويب
/// تُستضاف خلف وكيل يمرّر `/api/*` إلى الخادم، لأن الخادم لا يدعم CORS.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://futurekids-staging.up.railway.app',
);

/// ملف ثنائي مُنزَّل من الخادم (مثل تقرير Excel).
class ApiFile {
  final Uint8List bytes;
  final String? fileName;
  const ApiFile(this.bytes, this.fileName);
}

/// عميل HTTP رفيع: يضيف `Authorization: Bearer`، يفك JSON، ويحوّل الأخطاء إلى [ApiException].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _http = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  String? token;

  /// يُستدعى عند 401 على طلب موثَّق (انتهت الجلسة).
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.isEmpty
        ? Uri.parse(Uri.base.origin)
        : Uri.parse(baseUrl);
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
  }) => _sendJson(() => _http.get(_uri(path, query), headers: _headers()));

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) => _sendJson(
    () => _http.post(
      _uri(path),
      headers: _headers(json: true, auth: auth),
      body: jsonEncode(body),
    ),
    auth: auth,
  );

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) => _sendJson(
    () => _http.put(
      _uri(path),
      headers: _headers(json: true),
      body: jsonEncode(body),
    ),
  );

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? query,
  }) => _sendJson(() => _http.delete(_uri(path, query), headers: _headers()));

  Future<ApiFile> getFile(String path, {Map<String, String>? query}) async {
    final response = await _guard(
      () => _http.get(_uri(path, query), headers: _headers()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiFile(
        response.bodyBytes,
        _fileNameFrom(response.headers['content-disposition']),
      );
    }
    throw _toException(response, auth: true);
  }

  String resolve(String path) {
    final base = baseUrl.isEmpty ? Uri.base.origin : baseUrl;
    return Uri.parse('$base/').resolve(path).toString();
  }

  /// الصور القديمة المستضافة خارج الخادم لا تستقبل توكن الإدارة.
  Future<Uint8List> getPublicImage(String url) async {
    final response = await _guard(
      () => _http.get(Uri.parse(resolve(url)), headers: {'Accept': 'image/*'}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    throw _toException(response, auth: false);
  }

  Future<Map<String, dynamic>> sendMultipart({
    required String method,
    required String path,
    Map<String, String>? query,
    required Map<String, String> fields,
    Uint8List? image,
    String? fileName,
    String fileField = 'image',
  }) => _sendJson(() async {
    final request = http.MultipartRequest(method, _uri(path, query));
    request.headers.addAll(_headers());
    request.fields.addAll(fields);
    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          image,
          filename: fileName ?? 'banner.jpg',
        ),
      );
    }
    return http.Response.fromStream(await _http.send(request));
  }, requestTimeout: const Duration(minutes: 2));

  Future<Map<String, dynamic>> _sendJson(
    Future<http.Response> Function() send, {
    bool auth = true,
    Duration? requestTimeout,
  }) async {
    final response = await _guard(send, requestTimeout: requestTimeout);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = _decode(response);
      if (decoded == null) {
        throw const ApiException(message: 'استجابة غير متوقعة من الخادم');
      }
      return decoded;
    }
    throw _toException(response, auth: auth);
  }

  Future<http.Response> _guard(
    Future<http.Response> Function() send, {
    Duration? requestTimeout,
  }) async {
    try {
      return await send().timeout(requestTimeout ?? timeout);
    } on TimeoutException {
      throw const ApiException(
        message: 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'تعذر الاتصال بالخادم، تحقق من الإنترنت',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ApiException(
        message: 'تعذر الاتصال بالخادم، تحقق من الإنترنت',
      );
    }
  }

  Map<String, dynamic>? _decode(http.Response r) {
    try {
      final v = jsonDecode(utf8.decode(r.bodyBytes));
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  ApiException _toException(http.Response r, {required bool auth}) {
    final body = _decode(r);
    final serverMessage = body?['message'] as String?;
    final retry = int.tryParse(r.headers['retry-after'] ?? '');
    final code = r.statusCode;

    if (code == 401 && auth) {
      onUnauthorized?.call();
      return ApiException(
        statusCode: 401,
        message: 'انتهت الجلسة، سجّل الدخول من جديد',
        serverMessage: serverMessage,
      );
    }

    final message = switch (code) {
      400 => 'بيانات غير صحيحة، راجع الحقول وحاول مرة أخرى',
      // رسالة 401 في تسجيل الدخول عربية من الخادم نفسه.
      401 => serverMessage ?? 'بيانات الدخول غير صحيحة',
      403 => 'غير مصرّح لك بهذا الإجراء',
      404 => 'العنصر المطلوب غير موجود',
      409 => 'العنصر موجود مسبقاً',
      413 => 'حجم الطلب كبير جداً',
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
      suggestedRfidTag: body?['suggested_rfid_tag'] as String?,
      errors: [
        for (final e in body?['errors'] as List? ?? const [])
          if (e is Map<String, dynamic>) e,
      ],
    );
  }

  String _tooMany(int? seconds) {
    if (seconds == null) return 'محاولات كثيرة، حاول لاحقاً';
    final minutes = (seconds / 60).ceil();
    return 'محاولات دخول فاشلة كثيرة، حاول بعد $minutes دقيقة';
  }

  String? _fileNameFrom(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final extended = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (extended != null) {
      try {
        return Uri.decodeComponent(extended.group(1)!.trim());
      } catch (_) {
        /* Fall back to filename. */
      }
    }
    final m = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
    return m?.group(1);
  }

  void close() => _http.close();
}
