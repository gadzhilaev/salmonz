import 'dart:async';

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

  Future<UserModel?>? _restoreInFlight;

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

  /// Uses [ApiClient.refreshSession] so restore + 401-retry share one HTTP call.
  Future<AuthResult> refresh() async {
    final outcome = await _api.refreshSession();
    if (outcome.status == RefreshStatus.networkFailed) {
      throw const ApiException(
        message: 'Нет соединения с сервером',
        isNetworkError: true,
      );
    }
    if (outcome.status != RefreshStatus.ok || outcome.data == null) {
      throw const ApiException(
        message: 'Сессия истекла. Войдите снова',
        statusCode: 401,
      );
    }
    // Tokens already saved by ApiClient; keep user from response body.
    final result = AuthResult.fromJson(asMap(outcome.data));
    _currentUser = result.user;
    return result;
  }

  Future<UserModel> me() async {
    final res = await _api.get<Map<String, dynamic>>('/auth/me');
    final user = UserModel.fromJson(asMap(res.data));
    _currentUser = user;
    return user;
  }

  /// Restores session via refresh (preferred) or /auth/me with stored access.
  Future<UserModel?> restoreSession() {
    return _restoreInFlight ??= _restoreOnce().whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<UserModel?> _restoreOnce() async {
    final has = await _tokens.hasTokens();
    if (!has) return null;

    // Backend restart can take a few seconds — retry before giving up.
    Object? lastError;
    for (var attempt = 0; attempt < 4; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
      try {
        final refreshTok = await _tokens.readRefreshToken();
        if (refreshTok != null && refreshTok.isNotEmpty) {
          final result = await refresh();
          return result.user;
        }
        return await me();
      } on ApiException catch (e) {
        lastError = e;
        if (e.isNetwork) {
          continue;
        }
        // Real auth failure (401/403) — stop retrying refresh.
        break;
      } catch (e) {
        lastError = e;
        break;
      }
    }

    // Last attempt: valid access token may still work.
    try {
      return await me();
    } on ApiException catch (e) {
      if (e.isNetwork) {
        // Keep tokens; UI may show login until backend is back, but next
        // successful restore will reuse the same refresh token.
        return _currentUser;
      }
      await _tokens.clear();
      _currentUser = null;
      return null;
    } catch (_) {
      if (lastError is ApiException && lastError.isNetwork) {
        return _currentUser;
      }
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
