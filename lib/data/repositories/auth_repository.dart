import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/token_store.dart';
import '../models/models.dart';

class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  static final _skipAuth = Options(extra: {'skipAuth': true});

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
      options: _skipAuth,
    );
    return _persist(AuthResult.fromJson(asMap(res.data)));
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      options: _skipAuth,
    );
    return _persist(AuthResult.fromJson(asMap(res.data)));
  }

  Future<AuthResult> refresh() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw StateError('No refresh token');
    }
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refresh},
      options: _skipAuth,
    );
    return _persist(AuthResult.fromJson(asMap(res.data)));
  }

  Future<UserModel> me() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/me');
    final user = UserModel.fromJson(asMap(res.data));
    _currentUser = user;
    return user;
  }

  /// Restores session via refresh (preferred) or /auth/me with stored access.
  Future<UserModel?> restoreSession() async {
    final has = await _tokens.hasTokens();
    if (!has) return null;

    final refreshTok = await _tokens.readRefreshToken();
    if (refreshTok != null && refreshTok.isNotEmpty) {
      try {
        final result = await refresh();
        return result.user;
      } on ApiException catch (e) {
        if (e.isNetwork) return _currentUser;
        // Auth failure — try access token once more below.
      } catch (_) {
        // fall through to /auth/me
      }
    }

    try {
      return await me();
    } on ApiException catch (e) {
      if (e.isNetwork) {
        // Keep secure session when backend is unreachable.
        return _currentUser;
      }
      await _tokens.clear();
      _currentUser = null;
      return null;
    } catch (_) {
      await _tokens.clear();
      _currentUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post(
          '/auth/logout',
          data: {'refreshToken': refresh},
          options: _skipAuth,
        );
      }
    } catch (_) {
      // best-effort
    }
    await _tokens.clear();
    _currentUser = null;
  }

  Future<void> logoutAll() async {
    try {
      await _api.post('/auth/logout-all');
    } catch (_) {}
    await _tokens.clear();
    _currentUser = null;
  }

  Future<AuthResult> _persist(AuthResult result) async {
    await _tokens.saveTokens(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
    _currentUser = result.user;
    return result;
  }
}
