import { PrismaClient } from '@prisma/client';

import { hashPassword } from '../src/lib/password';

const prisma = new PrismaClient();

async function upsertVendor(input: {
  userId: string;
  vendorId: string;
  name: string;
  email: string;
  shopName: string;
  category: string;
  city: string;
}) {
  const passwordHash = await hashPassword('password');
  const user = await prisma.user.upsert({
    where: { email: input.email },
    update: { name: input.name, passwordHash, role: 'vendor', emailVerified: true },
    create: {
      id: input.userId,
      name: input.name,
      email: input.email,
      passwordHash,
      role: 'vendor',
      emailVerified: true,
      avatarUrl: `https://i.pravatar.cc/150?u=${input.email}`,
    },
  });
  return prisma.vendorProfile.upsert({
    where: { userId: user.id },
    update: { shopName: input.shopName, shopCategoriesJson: JSON.stringify([input.category]) },
    create: {
      id: input.vendorId,
      userId: user.id,
      shopName: input.shopName,
      shopTagline: `Une sélection ${input.category.toLowerCase()} livrée au Bénin.`,
      shopDescription: `${input.shopName} propose des produits sélectionnés avec soin.`,
      shopBannerUrl: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1400&q=80',
      shopCity: input.city,
      shopCountry: 'Bénin',
      shopCategoriesJson: JSON.stringify([input.category]),
      isVerified: true,
      shopSales: 128,
      shopRating: 4.7,
      shopReviewCount: 42,
      shopResponseMinutes: 45,
      shopFoundedYear: 2023,
    },
  });
}

async function main() {
  const clientPassword = await hashPassword('password');
  await prisma.user.upsert({
    where: { email: 'alex@example.com' },
    update: { passwordHash: clientPassword, role: 'client', name: 'Alex Martin', emailVerified: true },
    create: {
      id: 'c1',
      name: 'Alex Martin',
      email: 'alex@example.com',
      passwordHash: clientPassword,
      role: 'client',
      emailVerified: true,
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
    },
  });

  const tech = await upsertVendor({
    userId: 'vendor-user-1', vendorId: 'v1', name: 'Awa Kouassi', email: 'contact@tech.bj',
    shopName: 'Tech & Co', category: 'Tech', city: 'Cotonou',
  });
  const mode = await upsertVendor({
    userId: 'vendor-user-2', vendorId: 'v2', name: 'Maya Lawson', email: 'contact@mode.bj',
    shopName: 'Urban Mode', category: 'Mode', city: 'Porto-Novo',
  });
  const maison = await upsertVendor({
    userId: 'vendor-user-3', vendorId: 'v3', name: 'Nora Hounsou', email: 'contact@maison.bj',
    shopName: 'Maison Douce', category: 'Maison', city: 'Abomey-Calavi',
  });

  const products = [
    { id: 'p1', vendorId: tech.id, name: 'Casque Audio Pro X2', price: 118066, originalPrice: 144304, imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=900&q=80', category: 'Tech', stock: 18 },
    { id: 'p2', vendorId: tech.id, name: 'Montre Connectée Aura', price: 196131, originalPrice: null, imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=900&q=80', category: 'Tech', stock: 11 },
    { id: 'p3', vendorId: mode.id, name: 'Sneakers Urban White', price: 78059, originalPrice: 97738, imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=900&q=80', category: 'Mode', stock: 22 },
    { id: 'p4', vendorId: maison.id, name: 'Lampe Nordique', price: 52411, originalPrice: null, imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=900&q=80', category: 'Maison', stock: 8 },
  ];

  for (const product of products) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: product,
      create: {
        ...product,
        shortDescription: `${product.name}, disponible sur ShopHub.`,
        longDescription: `${product.name} est sélectionné par une boutique locale partenaire de ShopHub.`,
        rating: 4.6,
        reviewCount: 24,
        freeShipping: false,
        warrantyMonths: 12,
        tagsJson: JSON.stringify([product.category, 'Sélection ShopHub']),
        specificationsJson: JSON.stringify({ Garantie: '12 mois', Livraison: 'Bénin' }),
      },
    });
  }

  console.log('Base ShopHub initialisée. Comptes: alex@example.com / password et contact@tech.bj / password');
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
