import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _kProfileKey = 'gg_profile';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    await _storage.write(key: _kProfileKey, value: jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> readProfile() async {
    final json = await _storage.read(key: _kProfileKey);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearProfile() async {
    await _storage.delete(key: _kProfileKey);
  }
}
