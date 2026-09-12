import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_user.dart';

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  void loginAsClient({
    String name = 'Alex Martin',
    String email = 'alex@example.com',
  }) {
    state = AppUser(
      id: 'c1',
      name: name,
      email: email,
      role: UserRole.client,
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
    );
  }

  void loginAsVendor(AppUser vendor) => state = vendor;

  void registerVendorAccount({
    required String ownerName,
    required String email,
    required String shopName,
    required String category,
  }) {
    state = AppUser(
      id: 'vendor-${DateTime.now().millisecondsSinceEpoch}',
      name: ownerName,
      email: email,
      role: UserRole.vendor,
      avatarUrl: 'https://i.pravatar.cc/150?u=$email',
      shopName: shopName,
      shopTagline: 'Nouvelle boutique sur ShopHub',
      shopDescription:
          'Boutique créée sur ShopHub. Retrouvez une sélection de produits '
          'préparés avec soin et un suivi de commande clair.',
      shopBannerUrl:
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1400&q=80',
      shopCity: 'Cotonou',
      shopCountry: 'Bénin',
      shopCategories: [category],
      shopResponseTimeMinutes: 60,
      shopFoundedYear: DateTime.now().year,
    );
  }

  void updateProfile({
    required String name,
    required String email,
    required String avatarUrl,
  }) {
    final current = state;
    if (current == null) return;

    state = AppUser(
      id: current.id,
      name: name,
      email: email,
      role: current.role,
      avatarUrl: avatarUrl,
      shopName: current.shopName,
      shopTagline: current.shopTagline,
      shopDescription: current.shopDescription,
      shopBannerUrl: current.shopBannerUrl,
      shopCity: current.shopCity,
      shopCountry: current.shopCountry,
      shopCategories: current.shopCategories,
      isVerified: current.isVerified,
      shopSales: current.shopSales,
      shopRating: current.shopRating,
      shopReviewCount: current.shopReviewCount,
      shopProductCount: current.shopProductCount,
      shopResponseTimeMinutes: current.shopResponseTimeMinutes,
      shopFoundedYear: current.shopFoundedYear,
    );
  }

  void updateShopProfile({
    required String shopName,
    required String shopTagline,
    required String shopDescription,
    required String shopBannerUrl,
    required String shopCity,
    required String shopCountry,
    required List<String> shopCategories,
  }) {
    final current = state;
    if (current == null) return;

    state = current.copyWith(
      shopName: shopName,
      shopTagline: shopTagline,
      shopDescription: shopDescription,
      shopBannerUrl: shopBannerUrl,
      shopCity: shopCity,
      shopCountry: shopCountry,
      shopCategories: shopCategories,
    );
  }

  void logout() => state = null;
}

final authProvider = StateNotifierProvider<AuthNotifier, AppUser?>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) != null;
});

final isVendorProvider = Provider<bool>((ref) {
  return ref.watch(authProvider)?.isVendor ?? false;
});
