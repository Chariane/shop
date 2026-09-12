enum UserRole { client, vendor }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;

  // ---- Champs vendeur (null pour client) ----
  final String? shopName;
  final String? shopTagline;      // Phrase d'accroche courte
  final String? shopDescription;  // Bio longue
  final String? shopBannerUrl;    // Image de bannière
  final String? shopCity;
  final String? shopCountry;
  final List<String> shopCategories; // Catégories vendues
  final bool isVerified;
  final int shopSales;
  final double shopRating;
  final int shopReviewCount;
  final int shopProductCount;
  final int shopResponseTimeMinutes;
  final int? shopFoundedYear;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.shopName,
    this.shopTagline,
    this.shopDescription,
    this.shopBannerUrl,
    this.shopCity,
    this.shopCountry,
    this.shopCategories = const [],
    this.isVerified = false,
    this.shopSales = 0,
    this.shopRating = 0,
    this.shopReviewCount = 0,
    this.shopProductCount = 0,
    this.shopResponseTimeMinutes = 0,
    this.shopFoundedYear,
  });

  bool get isVendor => role == UserRole.vendor;

  /// "Répond en ~2h" formaté depuis les minutes.
  String get responseTimeLabel {
    if (shopResponseTimeMinutes < 60) {
      return '~${shopResponseTimeMinutes}min';
    }
    final hours = (shopResponseTimeMinutes / 60).round();
    return '~${hours}h';
  }

  AppUser copyWith({
    String? name,
    String? shopName,
    String? shopTagline,
    String? shopDescription,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      avatarUrl: avatarUrl,
      shopName: shopName ?? this.shopName,
      shopTagline: shopTagline ?? this.shopTagline,
      shopDescription: shopDescription ?? this.shopDescription,
      shopBannerUrl: shopBannerUrl,
      shopCity: shopCity,
      shopCountry: shopCountry,
      shopCategories: shopCategories,
      isVerified: isVerified,
      shopSales: shopSales,
      shopRating: shopRating,
      shopReviewCount: shopReviewCount,
      shopProductCount: shopProductCount,
      shopResponseTimeMinutes: shopResponseTimeMinutes,
      shopFoundedYear: shopFoundedYear,
    );
  }
}