import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kJwtKey = 'gg_jwt';
const _kProfileKey = 'gg_profile';

class TokenStorage {
  const TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _kJwtKey, value: token);

  Future<String?> readToken() => _storage.read(key: _kJwtKey);

  Future<void> clearToken() => _storage.delete(key: _kJwtKey);

  Future<void> saveProfile(Map<String, dynamic> profile) =>
      _storage.write(key: _kProfileKey, value: jsonEncode(profile));

  Future<Map<String, dynamic>?> readProfile() async {
    final json = await _storage.read(key: _kProfileKey);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearProfile() => _storage.delete(key: _kProfileKey);
}
