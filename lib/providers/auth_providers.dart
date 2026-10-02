import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import 'package:shophub/domain/entities/app_user.dart';
import '../domain/usecases/auth_use_cases.dart';
import '../data/datasources/mocks/vendors_mock.dart';
import 'platform_config_provider.dart';

class AuthNotifier extends StateNotifier<AppUser?> {
  final AuthUseCases _useCases;
  bool isDemoSession = false;

  AuthNotifier(this._useCases) : super(null) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      state = await _useCases.restoreSession();
      isDemoSession = false;
    } catch (_) {
      state = null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = await _useCases.login(email: email, password: password);
    isDemoSession = false;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? shopName,
    String? category,
  }) async {
    await _useCases.register(
      name: name,
      email: email,
      password: password,
      role: role,
      shopName: shopName,
      category: category,
    );
  }

  Future<void> verifyEmail(
      {required String email, required String code}) async {
    state = await _useCases.verifyEmail(email: email, code: code);
    isDemoSession = false;
  }

  Future<void> resendVerificationCode({required String email}) =>
      _useCases.resendVerificationCode(email: email);

  Future<void> updateProfile({
    required String name,
    required String email,
    required String avatarUrl,
  }) async {
    state = await _useCases.updateProfile(
      name: name,
      email: email,
      avatarUrl: avatarUrl.trim().isEmpty ? null : avatarUrl.trim(),
    );
  }

  Future<AppUser> updateShopProfile({
    required String shopName,
    required String shopTagline,
    required String shopDescription,
    required String shopBannerUrl,
    required String shopCity,
    required String shopCountry,
    required List<String> shopCategories,
  }) async {
    final updated = await _useCases.updateShopProfile(
      shopName: shopName,
      shopTagline: shopTagline,
      shopDescription: shopDescription,
      shopBannerUrl: shopBannerUrl,
      shopCity: shopCity,
      shopCountry: shopCountry,
      shopCategories: shopCategories,
    );
    state = updated;
    return updated;
  }

  void enterDemoVendor() {
    isDemoSession = true;
    state = VendorsMock.vendor1;
  }

  void enterDemoClient() {
    isDemoSession = true;
    state = const AppUser(
      id: 'demo-client',
      name: 'Visiteur démo',
      email: 'demo@shophub.local',
      role: UserRole.client,
      createdAt: null,
    );
  }

  Future<void> logout() async {
    try {
      await _useCases.logout();
    } finally {
      state = null;
      isDemoSession = false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier(ref.watch(authUseCasesProvider));
});

final isDemoModeProvider = Provider<bool>((ref) {
  ref.watch(authProvider);
  return ref.watch(platformConfigProvider).demoMode ||
      ref.watch(authProvider.notifier).isDemoSession;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

final isVendorProvider = Provider<bool>((ref) {
  return ref.watch(authProvider)?.isVendor ?? false;
});
