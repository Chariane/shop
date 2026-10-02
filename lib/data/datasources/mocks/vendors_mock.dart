import 'package:shophub/domain/entities/app_user.dart';

abstract final class VendorsMock {
  static const vendor1 = AppUser(
    id: 'v1',
    name: 'Karim Benali',
    email: 'karim@technova.com',
    role: UserRole.vendor,
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
    shopName: 'TechNova',
    shopTagline: 'La tech qui simplifie la vie',
    shopDescription:
        'Depuis 2018, TechNova sélectionne les meilleurs gadgets du '
        'marché. Chaque produit est testé par notre équipe. Livraison '
        'rapide, garantie 2 ans, service client en moins de 2 heures.',
    shopBannerUrl:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=1400&q=80',
    shopCity: 'Paris',
    shopCountry: 'France',
    shopCategories: ['Tech', 'Audio', 'Wearables'],
    isVerified: true,
    shopSales: 1284,
    shopRating: 4.8,
    shopReviewCount: 892,
    shopProductCount: 3,
    shopResponseTimeMinutes: 45,
    shopFoundedYear: 2018,
  );

  static const vendor2 = AppUser(
    id: 'v2',
    name: 'Sarah Lopez',
    email: 'sarah@urbanwear.com',
    role: UserRole.vendor,
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
    shopName: 'UrbanWear',
    shopTagline: 'Le style urbain, sans compromis',
    shopDescription:
        'UrbanWear est née à Lyon en 2020. Nous dessinons et fabriquons '
        'nos pièces en Europe avec des matériaux durables.',
    shopBannerUrl:
        'https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=1400&q=80',
    shopCity: 'Lyon',
    shopCountry: 'France',
    shopCategories: ['Mode', 'Accessoires'],
    isVerified: true,
    shopSales: 967,
    shopRating: 4.6,
    shopReviewCount: 541,
    shopProductCount: 3,
    shopResponseTimeMinutes: 120,
    shopFoundedYear: 2020,
  );

  static const vendor3 = AppUser(
    id: 'v3',
    name: 'Marc Dubois',
    email: 'marc@casadeco.com',
    role: UserRole.vendor,
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
    shopName: 'Casa Déco',
    shopTagline: 'Le coin qui vous ressemble',
    shopDescription: 'Casa Déco propose une sélection de pièces artisanales et '
        'design scandinave. Chaque objet a une histoire.',
    shopBannerUrl:
        'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1400&q=80',
    shopCity: 'Copenhague',
    shopCountry: 'Danemark',
    shopCategories: ['Maison', 'Luminaires', 'Textile'],
    isVerified: true,
    shopSales: 2103,
    shopRating: 4.9,
    shopReviewCount: 1276,
    shopProductCount: 2,
    shopResponseTimeMinutes: 90,
    shopFoundedYear: 2015,
  );

  static const all = [vendor1, vendor2, vendor3];
}
