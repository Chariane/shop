import type { Product, ProductImage, User, VendorProfile } from '@prisma/client';

type ProductWithVendor = Product & {
  vendor: VendorProfile & { user: User };
  gallery: ProductImage[];
};

type VendorWithUser = VendorProfile & { user: User; _count?: { products: number } };

function parseList(value: string): string[] {
  try {
    const parsed: unknown = JSON.parse(value);
    return Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === 'string') : [];
  } catch {
    return [];
  }
}

function parseSpecifications(value: string): Record<string, string> {
  try {
    const parsed: unknown = JSON.parse(value);
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return Object.fromEntries(
        Object.entries(parsed).filter((entry): entry is [string, string] => typeof entry[1] === 'string'),
      );
    }
  } catch {
    // A malformed optional JSON field should not make the public catalogue fail.
  }
  return {};
}

export function serializeVendor(vendor: VendorWithUser) {
  return {
    id: vendor.id,
    name: vendor.user.name,
    email: vendor.user.email,
    role: 'vendor',
    avatarUrl: vendor.user.avatarUrl,
    shopName: vendor.shopName,
    shopTagline: vendor.shopTagline,
    shopDescription: vendor.shopDescription,
    shopBannerUrl: vendor.shopBannerUrl,
    shopCity: vendor.shopCity,
    shopCountry: vendor.shopCountry,
    shopCategories: parseList(vendor.shopCategoriesJson),
    isVerified: vendor.isVerified,
    shopSales: vendor.shopSales,
    shopRating: vendor.shopRating,
    shopReviewCount: vendor.shopReviewCount,
    shopProductCount: vendor._count?.products ?? 0,
    shopResponseTimeMinutes: vendor.shopResponseMinutes,
    shopFoundedYear: vendor.shopFoundedYear,
  };
}

export function serializeUser(user: User & { vendorProfile?: VendorWithUser | null }) {
  if (user.vendorProfile) return serializeVendor(user.vendorProfile);

  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: 'client',
    avatarUrl: user.avatarUrl,
    shopCategories: [],
    isVerified: false,
    shopSales: 0,
    shopRating: 0,
    shopReviewCount: 0,
    shopProductCount: 0,
    shopResponseTimeMinutes: 0,
  };
}

export function serializeProduct(product: ProductWithVendor) {
  return {
    id: product.id,
    vendorId: product.vendorId,
    vendorName: product.vendor.shopName,
    name: product.name,
    shortDescription: product.shortDescription,
    longDescription: product.longDescription,
    price: product.price,
    originalPrice: product.originalPrice,
    imageUrl: product.imageUrl,
    gallery: product.gallery.sort((a, b) => a.position - b.position).map((image) => image.url),
    category: product.category,
    tags: parseList(product.tagsJson),
    specifications: parseSpecifications(product.specificationsJson),
    rating: product.rating,
    reviewCount: product.reviewCount,
    stock: product.stock,
    isActive: product.isActive,
    freeShipping: product.freeShipping,
    warrantyMonths: product.warrantyMonths,
    createdAt: product.createdAt.toISOString(),
  };
}
