import 'package:shophub/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});
  Future<AppUser> verifyEmail({required String email, required String code});
  Future<void> resendVerificationCode({required String email});
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? shopName,
    String? category,
  });
  Future<AppUser> updateProfile(
      {required String name,
      required String email,
      required String? avatarUrl});
  Future<AppUser> updateShopProfile({
    required String shopName,
    required String shopTagline,
    required String shopDescription,
    required String shopBannerUrl,
    required String shopCity,
    required String shopCountry,
    required List<String> shopCategories,
  });
  Future<AppUser?> restoreSession();
  Future<void> logout();
}
