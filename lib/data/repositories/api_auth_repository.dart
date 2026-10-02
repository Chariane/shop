import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/user_mapper.dart';
import 'package:shophub/domain/entities/app_user.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  final TokenStorage _tokens;

  const ApiAuthRepository(this._dio, this._tokens);

  Future<AppUser> _persistSession(Map<String, dynamic> payload) async {
    final accessToken = payload['accessToken'];
    final refreshToken = payload['refreshToken'];
    final rawUser = payload['user'];
    if (accessToken is! String || refreshToken is! String || rawUser is! Map) {
      throw const AppException('Réponse d’authentification invalide.');
    }
    final user = userFromJson(Map<String, dynamic>.from(rawUser));
    await _tokens.save(accessToken: accessToken, refreshToken: refreshToken);
    await _tokens.saveCachedUser(jsonEncode(userToJson(user)));
    return user;
  }

  Future<AppUser> _updateUser(
      String path, String method, Map<String, dynamic> data) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(method: method),
      );
      final rawUser = response.data?['user'];
      if (rawUser is! Map)
        throw const AppException('Réponse du serveur invalide.');
      final user = userFromJson(Map<String, dynamic>.from(rawUser));
      await _tokens.saveCachedUser(jsonEncode(userToJson(user)));
      return user;
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<AppUser> updateProfile(
          {required String name,
          required String email,
          required String? avatarUrl}) =>
      _updateUser('/auth/me', 'PATCH',
          {'name': name, 'email': email, 'avatarUrl': avatarUrl});

  @override
  Future<AppUser> updateShopProfile({
    required String shopName,
    required String shopTagline,
    required String shopDescription,
    required String shopBannerUrl,
    required String shopCity,
    required String shopCountry,
    required List<String> shopCategories,
  }) =>
      _updateUser('/auth/me/shop', 'PUT', {
        'shopName': shopName,
        'shopTagline': shopTagline,
        'shopDescription': shopDescription,
        'shopBannerUrl': shopBannerUrl,
        'shopCity': shopCity,
        'shopCountry': shopCountry,
        'shopCategories': shopCategories,
      });

  @override
  Future<AppUser> login(
      {required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _persistSession(response.data ?? const {});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? shopName,
    String? category,
  }) async {
    try {
      await _dio.post<void>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role == UserRole.vendor ? 'vendor' : 'client',
          if (shopName != null) 'shopName': shopName,
          if (category != null) 'shopCategories': [category],
          'shopCity': 'Cotonou',
          'shopCountry': 'Bénin',
        },
      );
      return;
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<AppUser> verifyEmail(
      {required String email, required String code}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/verification/confirm',
        data: {'email': email, 'code': code},
      );
      return _persistSession(response.data ?? const {});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<void> resendVerificationCode({required String email}) async {
    try {
      await _dio
          .post<void>('/auth/verification/resend', data: {'email': email});
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (await _tokens.readAccessToken() == null) return null;
    final cached = await _tokens.readCachedUser();
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final rawUser = response.data?['user'];
      if (rawUser is! Map) return null;
      final user = userFromJson(Map<String, dynamic>.from(rawUser));
      await _tokens.saveCachedUser(jsonEncode(userToJson(user)));
      return user;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokens.clear();
        return null;
      }
      if (cached != null) {
        try {
          final value = jsonDecode(cached);
          if (value is Map)
            return userFromJson(Map<String, dynamic>.from(value));
        } on FormatException {
          // Ignore a corrupt cache and report the API error.
        }
      }
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio
            .post<void>('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } finally {
      await _tokens.clear();
    }
  }
}
