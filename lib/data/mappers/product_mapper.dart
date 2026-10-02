import 'package:shophub/domain/entities/product.dart';

Product productFromJson(Map<String, dynamic> json) {
  double number(String key, [double fallback = 0]) =>
      (json[key] as num?)?.toDouble() ?? fallback;
  int integer(String key, [int fallback = 0]) =>
      (json[key] as num?)?.toInt() ?? fallback;
  final rawSpecs = json['specifications'];

  return Product(
    id: json['id'] as String,
    vendorId: json['vendorId'] as String,
    vendorName: json['vendorName'] as String? ?? 'Boutique ShopHub',
    name: json['name'] as String,
    shortDescription: json['shortDescription'] as String? ?? '',
    longDescription: json['longDescription'] as String? ?? '',
    price: number('price'),
    originalPrice: (json['originalPrice'] as num?)?.toDouble(),
    imageUrl: json['imageUrl'] as String? ?? '',
    gallery: (json['gallery'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    category: json['category'] as String? ?? 'Autre',
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    specifications: rawSpecs is Map
        ? rawSpecs
            .map((key, value) => MapEntry(key.toString(), value.toString()))
        : const {},
    rating: number('rating'),
    reviewCount: integer('reviewCount'),
    stock: integer('stock', 100),
    isActive: json['isActive'] as bool? ?? true,
    freeShipping: json['freeShipping'] as bool? ?? false,
    warrantyMonths: integer('warrantyMonths', 12),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

Map<String, dynamic> productToJson(Product product) => {
      'id': product.id,
      'vendorId': product.vendorId,
      'vendorName': product.vendorName,
      'name': product.name,
      'shortDescription': product.shortDescription,
      'longDescription': product.longDescription,
      'price': product.price,
      'originalPrice': product.originalPrice,
      'imageUrl': product.imageUrl,
      'gallery': product.gallery,
      'category': product.category,
      'tags': product.tags,
      'specifications': product.specifications,
      'rating': product.rating,
      'reviewCount': product.reviewCount,
      'stock': product.stock,
      'isActive': product.isActive,
      'freeShipping': product.freeShipping,
      'warrantyMonths': product.warrantyMonths,
      'createdAt': product.createdAt.toIso8601String(),
    };
