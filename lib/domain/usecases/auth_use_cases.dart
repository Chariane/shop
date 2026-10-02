import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthUseCases {
  final AuthRepository _repository;

  const AuthUseCases(this._repository);

  Future<AppUser> login({required String email, required String password}) =>
      _repository.login(email: email, password: password);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? shopName,
    String? category,
  }) =>
      _repository.register(
        name: name,
        email: email,
        password: password,
        role: role,
        shopName: shopName,
        category: category,
      );

  Future<AppUser> verifyEmail({required String email, required String code}) =>
      _repository.verifyEmail(email: email, code: code);

  Future<void> resendVerificationCode({required String email}) =>
      _repository.resendVerificationCode(email: email);

  Future<AppUser> updateProfile(
          {required String name,
          required String email,
          required String? avatarUrl}) =>
      _repository.updateProfile(name: name, email: email, avatarUrl: avatarUrl);

  Future<AppUser> updateShopProfile({
    required String shopName,
    required String shopTagline,
    required String shopDescription,
    required String shopBannerUrl,
    required String shopCity,
    required String shopCountry,
    required List<String> shopCategories,
  }) =>
      _repository.updateShopProfile(
        shopName: shopName,
        shopTagline: shopTagline,
        shopDescription: shopDescription,
        shopBannerUrl: shopBannerUrl,
        shopCity: shopCity,
        shopCountry: shopCountry,
        shopCategories: shopCategories,
      );

  Future<AppUser?> restoreSession() => _repository.restoreSession();

  Future<void> logout() => _repository.logout();
}
