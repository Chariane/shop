class Product {
  final String id;
  final String vendorId;
  final String vendorName;
  final String name;
  final String shortDescription;
  final String longDescription;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> gallery;
  final String category;
  final List<String> tags;
  final Map<String, String> specifications;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool isActive;
  final bool freeShipping;
  final int warrantyMonths;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.gallery = const [],
    required this.category,
    this.tags = const [],
    this.specifications = const {},
    this.rating = 0,
    this.reviewCount = 0,
    this.stock = 100,
    this.isActive = true,
    this.freeShipping = false,
    this.warrantyMonths = 12,
    required this.createdAt,
  });

  // --- Getters calculés (jamais stockés) ---

  bool get isOnSale => originalPrice != null && originalPrice! > price;

  int get discountPercent => isOnSale
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;

  bool get isInStock => stock > 0 && isActive;

  bool get isLowStock => isInStock && stock <= 5;

  /// Toutes les images (principale + galerie) sans doublons.
  List<String> get allImages => [imageUrl, ...gallery];

  Product copyWith({
    String? name,
    String? shortDescription,
    double? price,
    int? stock,
    bool? isActive,
  }) {
    return Product(
      id: id,
      vendorId: vendorId,
      vendorName: vendorName,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription,
      price: price ?? this.price,
      originalPrice: originalPrice,
      imageUrl: imageUrl,
      gallery: gallery,
      category: category,
      tags: tags,
      specifications: specifications,
      rating: rating,
      reviewCount: reviewCount,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      freeShipping: freeShipping,
      warrantyMonths: warrantyMonths,
      createdAt: createdAt,
    );
  }
}