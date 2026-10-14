import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// تخزين جلسة المدير (التوكن واسم المستخدم) بين مرات تشغيل التطبيق.
abstract class TokenStore {
  Future<String?> readToken();
  Future<String?> readUsername();
  Future<void> save({required String token, required String username});
  Future<void> clear();
}

/// تخزين آمن في نظام التشغيل (Credential Manager على Windows).
class SecureTokenStore implements TokenStore {
  static const _tokenKey = 'admin_token';
  static const _userKey = 'admin_username';
  final FlutterSecureStorage _storage;

  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> readUsername() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save({required String token, required String username}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: username);
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }
}

/// تخزين في الذاكرة (للاختبارات).
class MemoryTokenStore implements TokenStore {
  String? _token;
  String? _user;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<String?> readUsername() async => _user;

  @override
  Future<void> save({required String token, required String username}) async {
    _token = token;
    _user = username;
  }

  @override
  Future<void> clear() async {
    _token = null;
    _user = null;
  }
}
