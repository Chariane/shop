enum UserRole { client, vendor }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final DateTime? createdAt;

  final String? shopName;
  final String? shopTagline;
  final String? shopDescription;
  final String? shopBannerUrl;
  final String? shopCity;
  final String? shopCountry;
  final List<String> shopCategories;
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
    this.createdAt,
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

  String get responseTimeLabel {
    if (shopResponseTimeMinutes < 60) {
      return '~${shopResponseTimeMinutes}min';
    }
    final hours = (shopResponseTimeMinutes / 60).round();
    return '~${hours}h';
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? shopName,
    String? shopTagline,
    String? shopDescription,
    String? shopBannerUrl,
    String? shopCity,
    String? shopCountry,
    List<String>? shopCategories,
    int? shopResponseTimeMinutes,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      shopName: shopName ?? this.shopName,
      shopTagline: shopTagline ?? this.shopTagline,
      shopDescription: shopDescription ?? this.shopDescription,
      shopBannerUrl: shopBannerUrl ?? this.shopBannerUrl,
      shopCity: shopCity ?? this.shopCity,
      shopCountry: shopCountry ?? this.shopCountry,
      shopCategories: shopCategories ?? this.shopCategories,
      isVerified: isVerified,
      shopSales: shopSales,
      shopRating: shopRating,
      shopReviewCount: shopReviewCount,
      shopProductCount: shopProductCount,
      shopResponseTimeMinutes:
          shopResponseTimeMinutes ?? this.shopResponseTimeMinutes,
      shopFoundedYear: shopFoundedYear,
    );
  }
}
