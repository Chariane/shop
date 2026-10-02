import 'delivery_option.dart';

class PlatformCategory {
  final String name;
  final String imageUrl;
  const PlatformCategory({required this.name, required this.imageUrl});
}

class FeaturedSlideConfig {
  final String tag;
  final String title;
  final String subtitle;
  final String imageUrl;
  const FeaturedSlideConfig(
      {required this.tag,
      required this.title,
      required this.subtitle,
      required this.imageUrl});
}

class PlatformConfig {
  final List<PlatformCategory> categories;
  final List<FeaturedSlideConfig> featuredSlides;
  final List<DeliveryOption> deliveryOptions;
  final bool demoMode;

  const PlatformConfig(
      {required this.categories,
      required this.featuredSlides,
      required this.deliveryOptions,
      this.demoMode = false});

  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => PlatformCategory(
            name: item['name'] as String? ?? '',
            imageUrl: item['imageUrl'] as String? ?? ''))
        .where((item) => item.name.isNotEmpty)
        .toList();
    final slides = (json['featuredSlides'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => FeaturedSlideConfig(
            tag: item['tag'] as String? ?? '',
            title: item['title'] as String? ?? '',
            subtitle: item['subtitle'] as String? ?? '',
            imageUrl: item['imageUrl'] as String? ?? ''))
        .where((item) => item.imageUrl.isNotEmpty)
        .toList();
    final options = (json['deliveryOptions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => DeliveryOption(
            id: item['id'] as String? ?? '',
            name: item['name'] as String? ?? '',
            description: item['description'] as String? ?? '',
            estimatedLabel: item['estimatedLabel'] as String? ?? '',
            fee: (item['fee'] as num?)?.toDouble() ?? 0))
        .where((item) => item.id.isNotEmpty)
        .toList();
    return PlatformConfig(
        categories: categories.isEmpty ? fallback.categories : categories,
        featuredSlides: slides.isEmpty ? fallback.featuredSlides : slides,
        deliveryOptions: options.isEmpty ? fallback.deliveryOptions : options,
        demoMode: json['demoMode'] as bool? ?? false);
  }

  static const fallback = PlatformConfig(
    demoMode: true,
    categories: [
      PlatformCategory(
          name: 'Tech',
          imageUrl:
              'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80'),
      PlatformCategory(
          name: 'Mode',
          imageUrl:
              'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80'),
      PlatformCategory(
          name: 'Maison',
          imageUrl:
              'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80'),
      PlatformCategory(
          name: 'Sport',
          imageUrl:
              'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&q=80'),
    ],
    featuredSlides: [
      FeaturedSlideConfig(
          tag: 'Tech',
          title: 'Tech qui change\nle quotidien',
          subtitle: 'Sélection premium',
          imageUrl:
              'https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&q=80'),
      FeaturedSlideConfig(
          tag: 'Mode',
          title: 'Style urbain,\nattitude libre',
          subtitle: 'Nouvelle collection',
          imageUrl:
              'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&q=80'),
      FeaturedSlideConfig(
          tag: 'Maison',
          title: 'Votre intérieur\nmérite mieux',
          subtitle: 'Design scandinave',
          imageUrl:
              'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200&q=80'),
    ],
    deliveryOptions: [
      DeliveryOption(
          id: 'standard',
          name: 'Livraison standard',
          description: 'Livraison à domicile par coursier partenaire',
          estimatedLabel: '2 à 4 jours',
          fee: 3275),
      DeliveryOption(
          id: 'express',
          name: 'Livraison express',
          description: 'Traitement prioritaire et livraison rapide',
          estimatedLabel: '24 à 48 h',
          fee: 6556),
      DeliveryOption(
          id: 'pickup',
          name: 'Point relais',
          description: 'Retrait dans un point partenaire proche',
          estimatedLabel: '1 à 3 jours',
          fee: 1633),
    ],
  );
}
