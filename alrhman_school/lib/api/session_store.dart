import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

/// جلسة ولي الأمر المحفوظة: التوكن وبيانات الملف الشخصي.
/// (كلمة مرور ولي الأمر لا تُحفظ أبداً.)
class StoredSession {
  final String token;
  final ParentProfile parent;
  const StoredSession(this.token, this.parent);
}

abstract class SessionStore {
  Future<StoredSession?> read();
  Future<void> save(StoredSession session);
  Future<void> clear();
}

/// تخزين آمن في نظام التشغيل (Keystore على أندرويد، Keychain على iOS).
class SecureSessionStore implements SessionStore {
  static const _key = 'parent_session';
  final FlutterSecureStorage _storage;

  SecureSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<StoredSession?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return StoredSession(
        json['token'] as String,
        ParentProfile.fromJson(json['parent'] as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(StoredSession session) => _storage.write(
    key: _key,
    value: jsonEncode({
      'token': session.token,
      'parent': session.parent.toJson(),
    }),
  );

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

/// تخزين في الذاكرة (للاختبارات).
class MemorySessionStore implements SessionStore {
  StoredSession? _session;

  @override
  Future<StoredSession?> read() async => _session;

  @override
  Future<void> save(StoredSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}
