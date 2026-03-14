import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'role';
  static const _fullNameKey = 'full_name';
  static const _emailKey = 'email';
  static const _orgNameKey = 'org_name';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<void> saveUserInfo({
    required String role,
    required String fullName,
    required String email,
    String? orgName,
  }) async {
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _fullNameKey, value: fullName);
    await _storage.write(key: _emailKey, value: email);
    if (orgName != null) {
      await _storage.write(key: _orgNameKey, value: orgName);
    }
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<String?> getRole() => _storage.read(key: _roleKey);

  static Future<String?> getFullName() => _storage.read(key: _fullNameKey);

  static Future<String?> getEmail() => _storage.read(key: _emailKey);

  static Future<String?> getOrgName() => _storage.read(key: _orgNameKey);

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
