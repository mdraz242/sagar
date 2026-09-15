import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage();

  Future<void> save(
    String access,
    String refresh, {
    Map<String, dynamic>? user,
  }) async {
    await _storage.write(key: 'accessToken', value: access);
    await _storage.write(key: 'refreshToken', value: refresh);
    if (user != null) {
      await _storage.write(key: 'cachedUserProfile', value: jsonEncode(user));
    }
  }

  Future<String?> accessToken() => _storage.read(key: 'accessToken');
  Future<String?> refreshToken() => _storage.read(key: 'refreshToken');

  Future<Map<String, dynamic>?> cachedUserProfile() async {
    final raw = await _storage.read(key: 'cachedUserProfile');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  Future<void> clear() => _storage.deleteAll();
}
