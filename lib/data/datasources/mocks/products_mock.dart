import '../../models/product.dart';

abstract final class ProductsMock {
  static List<Product> generate() {
    final now = DateTime.now();
    return [
      Product(
        id: 'p1',
        vendorId: 'v1',
        vendorName: 'TechNova',
        name: 'Casque Audio Pro X2',
        shortDescription: 'Réduction de bruit active, 30h d\'autonomie',
        longDescription:
            'Le Casque Audio Pro X2 redéfinit l\'écoute mobile. Sa '
            'réduction de bruit adaptative analyse en temps réel votre '
            'environnement. Transducteurs 40 mm pour des basses profondes.',
        price: 179.99,
        originalPrice: 249.99,
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80',
        gallery: const [
          'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=800&q=80',
          'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=800&q=80',
        ],
        category: 'Tech',
        tags: const ['Best-seller', 'Sans fil', 'ANC'],
        specifications: const {
          'Autonomie': '30 heures',
          'Connectivité': 'Bluetooth 5.3',
          'Réduction de bruit': 'Active adaptative',
          'Poids': '250 g',
        },
        rating: 4.8,
        reviewCount: 234,
        stock: 42,
        freeShipping: true,
        warrantyMonths: 24,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Product(
        id: 'p2',
        vendorId: 'v1',
        vendorName: 'TechNova',
        name: 'Montre Connectée Aura',
        shortDescription: 'GPS, AMOLED, suivi santé avancé',
        longDescription:
            'La Montre Aura vous accompagne dans chaque effort. Écran '
            'AMOLED de 1,4" lisible en plein soleil, GPS bi-bande, '
            'plus de 150 modes sport, étanche 50 mètres.',
        price: 299.00,
        originalPrice: 399.00,
        imageUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80',
        gallery: const [
          'https://images.unsplash.com/photo-1546868871-7041f2a55e12?w=800&q=80',
        ],
        category: 'Tech',
        tags: const ['Nouveau', 'GPS', 'AMOLED'],
        specifications: const {
          'Écran': 'AMOLED 1.4"',
          'Autonomie': '14 jours',
          'Étanchéité': '5 ATM',
          'GPS': 'Bi-bande',
        },
        rating: 4.7,
        reviewCount: 89,
        stock: 18,
        freeShipping: true,
        warrantyMonths: 24,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Product(
        id: 'p3',
        vendorId: 'v1',
        vendorName: 'TechNova',
        name: 'Enceinte Bluetooth Boom',
        shortDescription: 'Son 360°, waterproof IPX7, 20h',
        longDescription:
            'Emportez la fête partout avec Boom. Ses 4 haut-parleurs '
            'diffusent un son 360° puissant. Certifiée IPX7, elle '
            'résiste à une immersion complète.',
        price: 69.99,
        imageUrl:
            'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=800&q=80',
        gallery: const [],
        category: 'Tech',
        tags: const ['Waterproof', 'Portable'],
        specifications: const {
          'Puissance': '30 W',
          'Autonomie': '20 heures',
          'Étanchéité': 'IPX7',
        },
        rating: 4.6,
        reviewCount: 145,
        stock: 76,
        freeShipping: true,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Product(
        id: 'p4',
        vendorId: 'v2',
        vendorName: 'UrbanWear',
        name: 'Sneakers Urban White',
        shortDescription: 'Cuir pleine fleur, semelle coussinée',
        longDescription: 'Les Sneakers Urban White sont le fruit de 3 ans de '
            'développement. Cuir pleine fleur italien, semelle à mémoire '
            'de forme. Fabriquées au Portugal.',
        price: 119.00,
        originalPrice: 149.00,
        imageUrl:
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&q=80',
        gallery: const [
          'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&q=80',
          'https://images.unsplash.com/photo-1600185365926-3a2ce3cdb9eb?w=800&q=80',
        ],
        category: 'Mode',
        tags: const ['Cuir italien', 'Europe'],
        specifications: const {
          'Matière': 'Cuir pleine fleur',
          'Semelle': 'Caoutchouc naturel',
          'Fabrication': 'Portugal',
        },
        rating: 4.5,
        reviewCount: 156,
        stock: 24,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Product(
        id: 'p5',
        vendorId: 'v2',
        vendorName: 'UrbanWear',
        name: 'Sac Cuir Élégant',
        shortDescription: 'Cuir italien, finitions soignées',
        longDescription: 'Un sac qui traverse les années. Cuir tanné végétal, '
            'coutures sellier, doublure coton bio. Compartiment 13".',
        price: 229.00,
        originalPrice: 289.00,
        imageUrl:
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800&q=80',
        gallery: const [
          'https://images.unsplash.com/photo-1591561954557-26941169b49e?w=800&q=80',
        ],
        category: 'Mode',
        tags: const ['Fait main', 'Cuir végétal'],
        specifications: const {
          'Matière': 'Cuir tanné végétal',
          'Dimensions': '38 × 28 × 12 cm',
          'Compartiment PC': 'Jusqu\'à 13"',
        },
        rating: 4.9,
        reviewCount: 312,
        stock: 8,
        freeShipping: true,
        warrantyMonths: 24,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Product(
        id: 'p6',
        vendorId: 'v2',
        vendorName: 'UrbanWear',
        name: 'Lunettes Horizon',
        shortDescription: 'Verres polarisés UV400, monture acétate',
        longDescription: 'Protégez vos yeux sans sacrifier le style. Verres '
            'polarisés, protection UV400, monture acétate bio-sourcée.',
        price: 139.00,
        imageUrl:
            'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=800&q=80',
        gallery: const [],
        category: 'Mode',
        tags: const ['UV400', 'Polarisé'],
        specifications: const {
          'Verres': 'Polarisés UV400',
          'Monture': 'Acétate bio-sourcé',
        },
        rating: 4.3,
        reviewCount: 98,
        stock: 45,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Product(
        id: 'p7',
        vendorId: 'v3',
        vendorName: 'Casa Déco',
        name: 'Lampe Nordique',
        shortDescription: 'Bois de chêne massif, LED chaleureuse',
        longDescription:
            'Inspirée des intérieurs scandinaves, la Lampe Nordique '
            'diffuse une lumière chaude. Pied en chêne massif FSC.',
        price: 79.90,
        originalPrice: 99.00,
        imageUrl:
            'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=800&q=80',
        gallery: const [
          'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800&q=80',
        ],
        category: 'Maison',
        tags: const ['Bois massif', 'LED incluse'],
        specifications: const {
          'Matière': 'Chêne massif FSC',
          'Ampoule': 'LED E27 incluse',
          'Hauteur': '42 cm',
        },
        rating: 4.4,
        reviewCount: 67,
        stock: 32,
        freeShipping: true,
        warrantyMonths: 24,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Product(
        id: 'p8',
        vendorId: 'v3',
        vendorName: 'Casa Déco',
        name: 'Vase Céramique Artisanal',
        shortDescription: 'Fait main, chaque pièce est unique',
        longDescription:
            'Façonné à la main dans notre atelier, ce vase en céramique '
            'grès émaillé apporte une touche d\'authenticité à votre '
            'intérieur.',
        price: 42.00,
        imageUrl:
            'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=800&q=80',
        gallery: const [],
        category: 'Maison',
        tags: const ['Fait main', 'Pièce unique'],
        specifications: const {
          'Matière': 'Grès émaillé',
          'Dimensions': '22 × 12 cm',
        },
        rating: 4.8,
        reviewCount: 42,
        stock: 4,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
