import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kJwtKey = 'gg_jwt';

class TokenStorage {
  const TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _kJwtKey, value: token);

  Future<String?> readToken() => _storage.read(key: _kJwtKey);

  Future<void> clearToken() => _storage.delete(key: _kJwtKey);
}
