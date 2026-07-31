import 'dart:async';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

typedef OnSessionExpired = void Function();

/// Dio client with Bearer auth, single-flight refresh, and one retry.
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenStore tokenStore,
    this.onSessionExpired,
    Dio? dio,
  }) : _tokenStore = tokenStore,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: config.apiV1Base,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
               headers: {'Content-Type': 'application/json'},
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final TokenStore _tokenStore;
  final Dio _dio;
  final OnSessionExpired? onSessionExpired;

  /// In-flight refresh; shared so parallel 401s wait on one refresh.
  Future<_RefreshOutcome>? _refreshFuture;

  Dio get raw => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _wrap(
    () => _dio.get<T>(path, queryParameters: queryParameters, options: options),
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _wrap(
    () => _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _wrap(
    () => _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _wrap(
    () => _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = await _tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    final skipRefresh = err.requestOptions.extra['skipAuth'] == true;
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');

    if (status != 401 || alreadyRetried || skipRefresh || isRefreshCall) {
      handler.next(err);
      return;
    }

    final outcome = await _refreshSingleFlight();
    if (outcome == _RefreshOutcome.networkFailed) {
      // Keep secure session when refresh fails due to connectivity.
      handler.next(err);
      return;
    }
    if (outcome != _RefreshOutcome.ok) {
      await _tokenStore.clear();
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    try {
      final access = await _tokenStore.readAccessToken();
      final opts = err.requestOptions;
      opts.headers['Authorization'] = 'Bearer $access';
      opts.extra['retried'] = true;
      final response = await _dio.fetch(opts);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<_RefreshOutcome> _refreshSingleFlight() {
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<_RefreshOutcome> _doRefresh() async {
    final refresh = await _tokenStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return _RefreshOutcome.authFailed;
    }

    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = res.data;
      if (data == null) return _RefreshOutcome.authFailed;
      final access = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (access == null ||
          access.isEmpty ||
          newRefresh == null ||
          newRefresh.isEmpty) {
        return _RefreshOutcome.authFailed;
      }
      await _tokenStore.saveTokens(
        accessToken: access,
        refreshToken: newRefresh,
      );
      return _RefreshOutcome.ok;
    } on DioException catch (e) {
      final mapped = ApiException.fromDio(e);
      if (mapped.isNetwork) return _RefreshOutcome.networkFailed;
      return _RefreshOutcome.authFailed;
    } catch (_) {
      return _RefreshOutcome.authFailed;
    }
  }
}

enum _RefreshOutcome { ok, authFailed, networkFailed }
