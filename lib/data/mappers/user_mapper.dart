import 'package:shophub/domain/entities/app_user.dart';

AppUser userFromJson(Map<String, dynamic> json) {
  return AppUser(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] == 'vendor' ? UserRole.vendor : UserRole.client,
    avatarUrl: json['avatarUrl'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    shopName: json['shopName'] as String?,
    shopTagline: json['shopTagline'] as String?,
    shopDescription: json['shopDescription'] as String?,
    shopBannerUrl: json['shopBannerUrl'] as String?,
    shopCity: json['shopCity'] as String?,
    shopCountry: json['shopCountry'] as String?,
    shopCategories: (json['shopCategories'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    isVerified: json['isVerified'] as bool? ?? false,
    shopSales: (json['shopSales'] as num?)?.toInt() ?? 0,
    shopRating: (json['shopRating'] as num?)?.toDouble() ?? 0,
    shopReviewCount: (json['shopReviewCount'] as num?)?.toInt() ?? 0,
    shopProductCount: (json['shopProductCount'] as num?)?.toInt() ?? 0,
    shopResponseTimeMinutes:
        (json['shopResponseTimeMinutes'] as num?)?.toInt() ?? 0,
    shopFoundedYear: (json['shopFoundedYear'] as num?)?.toInt(),
  );
}

Map<String, dynamic> userToJson(AppUser user) => {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.isVendor ? 'vendor' : 'client',
      'avatarUrl': user.avatarUrl,
      'createdAt': user.createdAt?.toIso8601String(),
      'shopName': user.shopName,
      'shopTagline': user.shopTagline,
      'shopDescription': user.shopDescription,
      'shopBannerUrl': user.shopBannerUrl,
      'shopCity': user.shopCity,
      'shopCountry': user.shopCountry,
      'shopCategories': user.shopCategories,
      'isVerified': user.isVerified,
      'shopSales': user.shopSales,
      'shopRating': user.shopRating,
      'shopReviewCount': user.shopReviewCount,
      'shopProductCount': user.shopProductCount,
      'shopResponseTimeMinutes': user.shopResponseTimeMinutes,
      'shopFoundedYear': user.shopFoundedYear,
    };
