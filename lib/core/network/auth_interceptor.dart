import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _client;
  final TokenStorage _tokens;
  Completer<bool>? _refreshing;

  AuthInterceptor(this._client, this._tokens);

  bool _isAuth(RequestOptions options) =>
      options.path.contains('/auth/login') ||
      options.path.contains('/auth/register') ||
      options.path.contains('/auth/refresh') ||
      options.path.contains('/auth/logout');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuth(options)) {
      final token = await _tokens.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        _isAuth(request) ||
        request.extra['tokenRefreshed'] == true) {
      handler.next(err);
      return;
    }
    if (!await _refreshTokens()) {
      handler.next(err);
      return;
    }
    try {
      request.extra['tokenRefreshed'] = true;
      handler.resolve(await _client.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshTokens() async {
    final current = _refreshing;
    if (current != null) return current.future;
    final completer = Completer<bool>();
    _refreshing = completer;
    try {
      final refreshToken = await _tokens.readRefreshToken();
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }
      final response = await Dio(BaseOptions(baseUrl: _client.options.baseUrl))
          .post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data ?? const <String, dynamic>{};
      final access = data['accessToken'];
      final refresh = data['refreshToken'];
      if (access is! String || refresh is! String) {
        completer.complete(false);
        return false;
      }
      await _tokens.save(accessToken: access, refreshToken: refresh);
      completer.complete(true);
      return true;
    } catch (_) {
      await _tokens.clear();
      completer.complete(false);
      return false;
    } finally {
      _refreshing = null;
    }
  }
}
