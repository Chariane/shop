import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'session_user';
  final FlutterSecureStorage _storage;

  const TokenStorage(this._storage);

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  Future<String?> readCachedUser() => _storage.read(key: _userKey);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> saveCachedUser(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<void> clear() => _storage.deleteAll();
}
