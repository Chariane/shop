import type { PrismaClient } from '@prisma/client';

export const defaultPlatformConfig = {
  categories: [
    { name: 'Tech', imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80' },
    { name: 'Mode', imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80' },
    { name: 'Maison', imageUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80' },
    { name: 'Sport', imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&q=80' },
  ],
  featuredSlides: [
    { tag: 'Tech', title: 'Tech qui change\nle quotidien', subtitle: 'Sélection premium', imageUrl: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&q=80' },
    { tag: 'Mode', title: 'Style urbain,\nattitude libre', subtitle: 'Nouvelle collection', imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=1200&q=80' },
    { tag: 'Maison', title: 'Votre intérieur\nmérite mieux', subtitle: 'Design scandinave', imageUrl: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=1200&q=80' },
  ],
  deliveryOptions: [
    { id: 'standard', name: 'Livraison standard', description: 'Livraison à domicile par coursier partenaire', estimatedLabel: '2 à 4 jours', fee: 3275 },
    { id: 'express', name: 'Livraison express', description: 'Traitement prioritaire et livraison rapide', estimatedLabel: '24 à 48 h', fee: 6556 },
    { id: 'pickup', name: 'Point relais', description: 'Retrait dans un point partenaire proche', estimatedLabel: '1 à 3 jours', fee: 1633 },
  ],
};

export class PlatformConfigUseCases {
  constructor(private readonly db: PrismaClient) {}

  async get() {
    try {
      let config = await this.db.platformConfig.findUnique({ where: { id: 'default' } });
      if (!config) {
        config = await this.db.platformConfig.create({
          data: {
            id: 'default',
            categoriesJson: JSON.stringify(defaultPlatformConfig.categories),
            featuredSlidesJson: JSON.stringify(defaultPlatformConfig.featuredSlides),
            deliveryOptionsJson: JSON.stringify(defaultPlatformConfig.deliveryOptions),
          },
        });
      }
      return {
        categories: JSON.parse(config.categoriesJson),
        featuredSlides: JSON.parse(config.featuredSlidesJson),
        deliveryOptions: JSON.parse(config.deliveryOptionsJson),
        demoMode: false,
      };
    } catch (_) {
      return { ...defaultPlatformConfig, demoMode: true };
    }
  }
}
