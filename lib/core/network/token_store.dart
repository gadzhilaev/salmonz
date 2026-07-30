import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure persistence for JWT access / refresh tokens.
///
/// Prefers [FlutterSecureStorage]; falls back to [SharedPreferences] if the
/// platform keystore/keychain is unavailable (rare Simulator / CI edge cases).
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const _accessKey = 'salmonz_access_token';
  static const _refreshKey = 'salmonz_refresh_token';
  static const _prefsAccess = 'salmonz_access_token_fallback';
  static const _prefsRefresh = 'salmonz_refresh_token_fallback';

  final FlutterSecureStorage _storage;
  bool _usePrefsFallback = false;

  Future<String?> readAccessToken() async {
    if (_usePrefsFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsAccess);
    }
    try {
      return await _storage.read(key: _accessKey);
    } catch (_) {
      _usePrefsFallback = true;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsAccess);
    }
  }

  Future<String?> readRefreshToken() async {
    if (_usePrefsFallback) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsRefresh);
    }
    try {
      return await _storage.read(key: _refreshKey);
    } catch (_) {
      _usePrefsFallback = true;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsRefresh);
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (_usePrefsFallback) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsAccess, accessToken);
      await prefs.setString(_prefsRefresh, refreshToken);
      return;
    }
    try {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } catch (_) {
      _usePrefsFallback = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsAccess, accessToken);
      await prefs.setString(_prefsRefresh, refreshToken);
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsAccess);
    await prefs.remove(_prefsRefresh);
  }

  Future<bool> hasTokens() async {
    final access = await readAccessToken();
    final refresh = await readRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }
}
