import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Prints every API request/response to the debug console (`flutter run`).
///
/// Tokens and password-like fields are redacted. Enabled only in debug builds.
class ApiLogInterceptor extends Interceptor {
  static const _sensitiveHeaderKeys = {
    'authorization',
    'cookie',
    'set-cookie',
  };

  static const _sensitiveBodyKeys = {
    'password',
    'passwordhash',
    'accesstoken',
    'refreshtoken',
    'token',
    'authorization',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final uri = options.uri;
      debugPrint('── HTTP → ${options.method} $uri');
      final query = options.queryParameters;
      if (query.isNotEmpty) {
        debugPrint('   query: ${_safeJson(query)}');
      }
      debugPrint('   headers: ${_redactMap(options.headers)}');
      if (options.data != null) {
        debugPrint('   body: ${_safeJson(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final opts = response.requestOptions;
      debugPrint(
        '── HTTP ← ${response.statusCode} ${opts.method} ${opts.uri}',
      );
      debugPrint('   body: ${_safeJson(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final opts = err.requestOptions;
      final status = err.response?.statusCode;
      debugPrint(
        '── HTTP ✕ ${status ?? err.type.name} ${opts.method} ${opts.uri}',
      );
      if (err.response?.data != null) {
        debugPrint('   body: ${_safeJson(err.response!.data)}');
      } else if (err.message != null) {
        debugPrint('   error: ${err.message}');
      }
    }
    handler.next(err);
  }

  Object? _redactMap(Map<dynamic, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      final k = key.toString();
      if (_sensitiveHeaderKeys.contains(k.toLowerCase()) ||
          _sensitiveBodyKeys.contains(k.toLowerCase())) {
        out[k] = _mask(value);
      } else if (value is Map) {
        out[k] = _redactMap(value);
      } else if (value is List) {
        out[k] = value.map(_redactValue).toList();
      } else {
        out[k] = value;
      }
    });
    return out;
  }

  Object? _redactValue(Object? value) {
    if (value is Map) return _redactMap(value);
    if (value is List) return value.map(_redactValue).toList();
    return value;
  }

  Object? _mask(Object? value) {
    final s = value?.toString() ?? '';
    if (s.isEmpty) return '***';
    if (s.length <= 8) return '***';
    return '***${s.substring(s.length - 4)}';
  }

  String _safeJson(Object? data) {
    try {
      if (data is FormData) {
        final fields = {
          for (final e in data.fields) e.key: e.value,
          for (final f in data.files) f.key: '<file:${f.value.filename}>',
        };
        return jsonEncode(_redactMap(fields));
      }
      if (data is Map) {
        return jsonEncode(_redactMap(data));
      }
      if (data is List) {
        return jsonEncode(data.map(_redactValue).toList());
      }
      if (data is String) {
        final trimmed = data.trim();
        if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
          final decoded = jsonDecode(trimmed);
          return _safeJson(decoded);
        }
        return data;
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }
}
