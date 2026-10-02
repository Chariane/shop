import { Prisma, PrismaClient } from '@prisma/client';

import { ApplicationError } from '../../domain/errors';
import { defaultPlatformConfig } from '../../application/platform-config-use-cases';
import type {
  AuthRepository,
  CatalogRepository,
  CheckoutPaymentsRepository,
  OrdersRepository,
  ShopReviewRepository,
} from '../../domain/repositories';
import type {
  CartLine,
  DeliveryAddress,
  NewProduct,
  ProductFilter,
  ProductView,
  UserProfile,
  VendorView,
  OrderView,
  ShopReviewView,
} from '../../domain/models';

const userInclude = {
  vendorProfile: { include: { _count: { select: { products: true } } } },
} as const;
const productInclude = {
  vendor: { include: { user: true } },
  gallery: true,
} as const;
const vendorInclude = {
  user: true,
  _count: { select: { products: true } },
} as const;
const orderInclude = {
  client: true,
  vendor: { include: { user: true } },
  items: { include: { product: true } },
  shopReview: true,
  checkoutPayment: true,
} as const;

function toUserProfile(user: Prisma.UserGetPayload<{ include: typeof userInclude }>): UserProfile {
  const vendor = user.vendorProfile;
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role === 'vendor' ? 'vendor' : 'client',
    avatarUrl: user.avatarUrl,
    createdAt: user.createdAt,
    vendorProfile: vendor ? {
      id: vendor.id,
      userId: vendor.userId,
      shopName: vendor.shopName,
      shopTagline: vendor.shopTagline,
      shopDescription: vendor.shopDescription,
      shopBannerUrl: vendor.shopBannerUrl,
      shopCity: vendor.shopCity,
      shopCountry: vendor.shopCountry,
      shopCategoriesJson: vendor.shopCategoriesJson,
      isVerified: vendor.isVerified,
      shopSales: vendor.shopSales,
      shopRating: vendor.shopRating,
      shopReviewCount: vendor.shopReviewCount,
      shopResponseMinutes: vendor.shopResponseMinutes,
      shopFoundedYear: vendor.shopFoundedYear,
      productCount: vendor._count.products,
    } : null,
  };
}

function toProduct(product: Prisma.ProductGetPayload<{ include: typeof productInclude }>): ProductView {
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
    tagsJson: product.tagsJson,
    specificationsJson: product.specificationsJson,
    rating: product.rating,
    reviewCount: product.reviewCount,
    stock: product.stock,
    isActive: product.isActive,
    freeShipping: product.freeShipping,
    warrantyMonths: product.warrantyMonths,
    createdAt: product.createdAt,
  };
}

function toVendor(vendor: Prisma.VendorProfileGetPayload<{ include: typeof vendorInclude }>): VendorView {
  return {
    id: vendor.id,
    name: vendor.user.name,
    email: vendor.user.email,
    role: 'vendor',
    avatarUrl: vendor.user.avatarUrl,
    createdAt: vendor.user.createdAt,
    vendorProfile: {
      id: vendor.id,
      userId: vendor.userId,
      shopName: vendor.shopName,
      shopTagline: vendor.shopTagline,
      shopDescription: vendor.shopDescription,
      shopBannerUrl: vendor.shopBannerUrl,
      shopCity: vendor.shopCity,
      shopCountry: vendor.shopCountry,
      shopCategoriesJson: vendor.shopCategoriesJson,
      isVerified: vendor.isVerified,
      shopSales: vendor.shopSales,
      shopRating: vendor.shopRating,
      shopReviewCount: vendor.shopReviewCount,
      shopResponseMinutes: vendor.shopResponseMinutes,
      shopFoundedYear: vendor.shopFoundedYear,
      productCount: vendor._count.products,
    },
  };
}

function toOrder(order: Prisma.OrderGetPayload<{ include: typeof orderInclude }>): OrderView {
  return {
    id: order.id,
    clientId: order.clientId,
    clientName: order.client.name,
    vendorId: order.vendorId,
    vendorName: order.vendor.shopName,
    status: order.status as OrderView['status'],
    paymentStatus: order.paymentStatus as OrderView['paymentStatus'],
    paymentId: order.checkoutPaymentId,
    total: order.total,
    shopReview: order.shopReview ? { rating: order.shopReview.rating, comment: order.shopReview.comment } : null,
    deliveryMethod: order.deliveryMethod,
    deliveryFee: order.deliveryFee,
    deliveryAddress: {
      fullName: order.deliveryName,
      phone: order.deliveryPhone,
      street: order.deliveryStreet,
      city: order.deliveryCity,
      country: order.deliveryCountry,
    },
    items: order.items.map((item) => ({
      productId: item.productId,
      productName: item.productName,
      imageUrl: item.product.imageUrl,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      stock: item.product.stock,
      productCreatedAt: item.product.createdAt,
    })),
    createdAt: order.createdAt,
  };
}

export class PrismaAuthRepository implements AuthRepository {
  constructor(private readonly db: PrismaClient) {}

  async findUserByEmail(email: string) {
    const user = await this.db.user.findUnique({ where: { email }, include: userInclude });
    if (!user) return null;
    return { profile: toUserProfile(user), passwordHash: user.passwordHash, emailVerified: user.emailVerified };
  }

  async findUserById(id: string) {
    const user = await this.db.user.findUnique({ where: { id }, include: userInclude });
    return user ? toUserProfile(user) : null;
  }

  async updateUserProfile(id: string, input: { name: string; email: string; avatarUrl: string | null }) {
    const user = await this.db.user.update({ where: { id }, data: input, include: userInclude });
    return toUserProfile(user);
  }

  async updateVendorProfile(userId: string, input: {
    shopName: string; shopTagline: string | null; shopDescription: string | null;
    shopBannerUrl: string | null; shopCity: string | null; shopCountry: string | null; categories: string[];
  }) {
    await this.db.vendorProfile.update({
      where: { userId },
      data: {
        shopName: input.shopName, shopTagline: input.shopTagline,
        shopDescription: input.shopDescription, shopBannerUrl: input.shopBannerUrl,
        shopCity: input.shopCity, shopCountry: input.shopCountry,
        shopCategoriesJson: JSON.stringify(input.categories),
      },
    });
    const user = await this.db.user.findUniqueOrThrow({ where: { id: userId }, include: userInclude });
    return toUserProfile(user);
  }

  async createUser(input: Parameters<AuthRepository['createUser']>[0]) {
    const user = await this.db.user.create({
      data: {
        name: input.name,
        email: input.email,
        passwordHash: input.passwordHash,
        role: input.role,
        avatarUrl: input.avatarUrl,
        vendorProfile: input.vendor ? {
          create: {
            shopName: input.vendor.shopName,
            shopTagline: input.vendor.shopTagline,
            shopDescription: input.vendor.shopDescription,
            shopCity: input.vendor.shopCity,
            shopCountry: input.vendor.shopCountry,
            shopCategoriesJson: JSON.stringify(input.vendor.categories),
            shopFoundedYear: new Date().getFullYear(),
          },
        } : undefined,
      },
      include: userInclude,
    });
    return toUserProfile(user);
  }

  async saveEmailVerification(input: { email: string; codeHash: string; expiresAt: Date; sentAt: Date }) {
    await this.db.emailVerificationChallenge.upsert({
      where: { email: input.email },
      create: input,
      update: { codeHash: input.codeHash, expiresAt: input.expiresAt, sentAt: input.sentAt, attempts: 0 },
    });
  }

  async findEmailVerification(email: string) {
    return this.db.emailVerificationChallenge.findUnique({
      where: { email },
      select: { codeHash: true, attempts: true, expiresAt: true, sentAt: true },
    });
  }

  async incrementEmailVerificationAttempts(email: string) {
    await this.db.emailVerificationChallenge.updateMany({
      where: { email, attempts: { lt: 5 } },
      data: { attempts: { increment: 1 } },
    });
  }

  async completeEmailVerification(email: string, codeHash: string, now: Date) {
    return this.db.$transaction(async (tx) => {
      const challenge = await tx.emailVerificationChallenge.findUnique({ where: { email } });
      if (!challenge || challenge.codeHash !== codeHash || challenge.expiresAt <= now || challenge.attempts >= 5) return false;
      const updated = await tx.user.updateMany({ where: { email, emailVerified: false }, data: { emailVerified: true } });
      if (updated.count !== 1) return false;
      await tx.emailVerificationChallenge.delete({ where: { email } });
      return true;
    });
  }

  async deleteEmailVerification(email: string) {
    await this.db.emailVerificationChallenge.deleteMany({ where: { email } });
  }

  async createRefreshToken(input: { tokenHash: string; userId: string; expiresAt: Date }) {
    await this.db.refreshToken.create({ data: input });
  }

  async findRefreshToken(tokenHash: string) {
    return this.db.refreshToken.findUnique({
      where: { tokenHash },
      select: { id: true, userId: true, expiresAt: true, revokedAt: true },
    });
  }

  async revokeRefreshToken(tokenHash: string, revokedAt: Date) {
    await this.db.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt },
    });
  }
}

export class PrismaCatalogRepository implements CatalogRepository {
  constructor(private readonly db: PrismaClient) {}

  async listProducts(filter: ProductFilter) {
    const products = await this.db.product.findMany({
      where: {
        isActive: true,
        ...(filter.category ? { category: filter.category } : {}),
        ...(filter.query ? { name: { contains: filter.query } } : {}),
      },
      include: productInclude,
      orderBy: { createdAt: 'desc' },
    });
    return products.map(toProduct);
  }

  async findProduct(id: string) {
    const product = await this.db.product.findUnique({ where: { id }, include: productInclude });
    return product ? toProduct(product) : null;
  }

  async listVendors() {
    const vendors = await this.db.vendorProfile.findMany({
      include: vendorInclude,
      orderBy: { createdAt: 'desc' },
    });
    return vendors.map(toVendor);
  }

  async findVendor(id: string) {
    const vendor = await this.db.vendorProfile.findUnique({
      where: { id },
      include: vendorInclude,
    });
    return vendor ? toVendor(vendor) : null;
  }

  async updateProduct(userId: string, productId: string, input: NewProduct) {
    const vendor = await this.db.vendorProfile.findUnique({ where: { userId } });
    if (!vendor) throw new ApplicationError('FORBIDDEN', 'Profil vendeur introuvable.');
    const product = await this.db.product.findFirst({ where: { id: productId, vendorId: vendor.id } });
    if (!product) throw new ApplicationError('NOT_FOUND', 'Produit introuvable.');
    const updated = await this.db.product.update({
      where: { id: productId },
      data: {
        name: input.name.trim(), shortDescription: input.shortDescription,
        longDescription: input.longDescription, price: input.price, originalPrice: input.originalPrice,
        imageUrl: input.imageUrl, category: input.category, stock: input.stock,
        freeShipping: input.freeShipping, warrantyMonths: input.warrantyMonths,
        isActive: input.isActive, tagsJson: JSON.stringify(input.tags),
        specificationsJson: JSON.stringify(input.specifications),
        gallery: { deleteMany: {}, create: input.gallery.map((url, position) => ({ url, position })) },
      },
      include: productInclude,
    });
    return toProduct(updated);
  }

  async createProduct(userId: string, input: NewProduct) {
    const vendor = await this.db.vendorProfile.findUnique({ where: { userId } });
    if (!vendor) throw new ApplicationError('FORBIDDEN', 'Profil vendeur introuvable.');

    const product = await this.db.product.create({
      data: {
        vendorId: vendor.id,
        name: input.name.trim(),
        price: input.price,
        imageUrl: input.imageUrl,
        category: input.category,
        shortDescription: input.shortDescription,
        longDescription: input.longDescription,
        originalPrice: input.originalPrice,
        stock: input.stock,
        isActive: input.isActive ?? true,
        freeShipping: input.freeShipping,
        warrantyMonths: input.warrantyMonths,
        gallery: { create: input.gallery.map((url, position) => ({ url, position })) },
        tagsJson: JSON.stringify(input.tags),
        specificationsJson: JSON.stringify(input.specifications),
      },
      include: productInclude,
    });
    return toProduct(product);
  }
}

function toShopReview(review: Prisma.ShopReviewGetPayload<{ include: { client: true } }>): ShopReviewView {
  return {
    id: review.id,
    orderId: review.orderId,
    vendorId: review.vendorId,
    clientName: review.client.name,
    rating: review.rating,
    comment: review.comment,
    createdAt: review.createdAt,
  };
}

export class PrismaOrdersRepository implements OrdersRepository {
  constructor(private readonly db: PrismaClient) {}

  async listForUser(userId: string, role: 'client' | 'vendor') {
    const where: Prisma.OrderWhereInput = role === 'vendor'
      ? { vendor: { userId }, paymentStatus: { in: ['paid', 'not_required'] } }
      : { clientId: userId };
    const orders = await this.db.order.findMany({
      where,
      include: orderInclude,
      orderBy: { createdAt: 'desc' },
    });
    return orders.map(toOrder);
  }

  async placeOrder(input: {
    clientId: string;
    items: CartLine[];
    deliveryMethod: string;
    deliveryFee: number;
    address: DeliveryAddress;
  }) {
    return this.db.$transaction(async (tx) => {
      const config = await tx.platformConfig.findUnique({ where: { id: 'default' } });
      const options = config
        ? JSON.parse(config.deliveryOptionsJson) as Array<{ id: string; fee: number }>
        : defaultPlatformConfig.deliveryOptions;
      const selected = options.find((option) => option.id === input.deliveryMethod);
      if (!selected) throw new ApplicationError('VALIDATION', 'Mode de livraison indisponible.');
      const deliveryFee = selected.fee;
      const products = await tx.product.findMany({
        where: { id: { in: input.items.map((item) => item.productId) }, isActive: true },
        include: { vendor: true },
      });
      if (products.length !== input.items.length) {
        throw new ApplicationError('VALIDATION', 'Un produit du panier est indisponible.');
      }

      const quantities = new Map(input.items.map((item) => [item.productId, item.quantity]));
      for (const product of products) {
        const quantity = quantities.get(product.id)!;
        const changed = await tx.product.updateMany({
          where: { id: product.id, isActive: true, stock: { gte: quantity } },
          data: { stock: { decrement: quantity } },
        });
        if (!changed.count) {
          throw new ApplicationError('INSUFFICIENT_STOCK', `${product.name} n'est plus suffisamment en stock.`);
        }
      }

      const grouped = new Map<string, typeof products>();
      for (const product of products) {
        const group = grouped.get(product.vendorId) ?? [];
        group.push(product);
        grouped.set(product.vendorId, group);
      }

      let feeApplied = false;
      const created = await Promise.all([...grouped.entries()].map(async ([vendorId, vendorProducts]) => {
        const subtotal = vendorProducts.reduce(
          (sum, product) => sum + product.price * quantities.get(product.id)!,
          0,
        );
        const vendorDeliveryFee = feeApplied ? 0 : deliveryFee;
        feeApplied = true;
        const order = await tx.order.create({
          data: {
            clientId: input.clientId,
            vendorId,
            deliveryMethod: input.deliveryMethod,
            deliveryFee: vendorDeliveryFee,
            deliveryName: input.address.fullName,
            deliveryPhone: input.address.phone,
            deliveryStreet: input.address.street,
            deliveryCity: input.address.city,
            deliveryCountry: input.address.country,
            total: subtotal + vendorDeliveryFee,
            paymentStatus: 'pending',
            items: {
              create: vendorProducts.map((product) => ({
                productId: product.id,
                productName: product.name,
                unitPrice: product.price,
                quantity: quantities.get(product.id)!,
              })),
            },
          },
          include: orderInclude,
        });
        await tx.appNotification.create({ data: { userId: input.clientId, type: 'payment', title: 'Paiement en attente', message: `Terminez le paiement pour confirmer la commande ${order.id}.` } });
        return toOrder(order);
      }));
      return created;
    });
  }

  async updateVendorOrderStatus(input: {
    orderId: string;
    vendorUserId: string;
    status: 'pending' | 'confirmed' | 'shipped' | 'delivered';
  }) {
    const order = await this.db.order.findUnique({
      where: { id: input.orderId },
      include: { vendor: true },
    });
    if (!order || order.vendor.userId !== input.vendorUserId) {
      throw new ApplicationError('NOT_FOUND', 'Commande introuvable.');
    }
    if (order.paymentStatus !== 'paid' && order.paymentStatus !== 'not_required') {
      throw new ApplicationError('FORBIDDEN', 'La commande doit être payée avant sa préparation.');
    }
    const updated = await this.db.$transaction(async (tx) => {
      const changed = await tx.order.update({ where: { id: order.id }, data: { status: input.status }, include: orderInclude });
      if (order.status !== input.status) {
        await tx.appNotification.create({ data: { userId: order.clientId, type: 'delivery', title: 'Mise à jour de commande', message: `Votre commande ${order.id} est maintenant ${input.status}.` } });
      }
      if (input.status === 'delivered' && order.status !== 'delivered') {
        await tx.loyaltyTransaction.upsert({ where: { orderId: order.id }, create: { userId: order.clientId, orderId: order.id, points: Math.floor(order.total) }, update: {} });
      }
      return changed;
    });
    return toOrder(updated);
  }

  listNotifications(userId: string) {
    return this.db.appNotification.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 100 });
  }

  async markNotificationRead(userId: string, id?: string) {
    await this.db.appNotification.updateMany({ where: { userId, readAt: null, ...(id ? { id } : {}) }, data: { readAt: new Date() } });
  }

  async loyaltyPoints(userId: string) {
    const result = await this.db.loyaltyTransaction.aggregate({ where: { userId }, _sum: { points: true } });
    return result._sum.points ?? 0;
  }
}


export class PrismaShopReviewRepository implements ShopReviewRepository {
  constructor(private readonly db: PrismaClient) {}

  async rateDeliveredOrder(input: { orderId: string; clientId: string; rating: number; comment: string | null }) {
    const order = await this.db.order.findFirst({
      where: { id: input.orderId, clientId: input.clientId },
      select: { id: true, vendorId: true, status: true },
    });
    if (!order) throw new ApplicationError('NOT_FOUND', 'Commande introuvable.');
    if (order.status !== 'delivered') {
      throw new ApplicationError('FORBIDDEN', 'Vous pourrez noter la boutique après la livraison.');
    }

    return this.db.$transaction(async (tx) => {
      const review = await tx.shopReview.create({
        data: {
          orderId: order.id,
          vendorId: order.vendorId,
          clientId: input.clientId,
          rating: input.rating,
          comment: input.comment,
        },
        include: { client: true },
      });
      const aggregate = await tx.shopReview.aggregate({
        where: { vendorId: order.vendorId },
        _avg: { rating: true },
        _count: { _all: true },
      });
      await tx.vendorProfile.update({
        where: { id: order.vendorId },
        data: {
          shopRating: aggregate._avg.rating ?? 0,
          shopReviewCount: aggregate._count._all,
        },
      });
      return toShopReview(review);
    });
  }

  async listForVendor(vendorId: string) {
    const reviews = await this.db.shopReview.findMany({
      where: { vendorId },
      include: { client: true },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return reviews.map(toShopReview);
  }
}


export class PrismaCheckoutPaymentsRepository implements CheckoutPaymentsRepository {
  constructor(private readonly db: PrismaClient) {}

  private toRecord(payment: { id: string; clientId: string; orderIdsJson: string; amount: number; amountXof: number; status: string; providerTransactionId: string | null; checkoutUrl: string | null }) {
    return {
      ...payment,
      orderIds: JSON.parse(payment.orderIdsJson) as string[],
      status: payment.status as 'pending' | 'paid' | 'failed' | 'refunded',
    };
  }

  async createForOrders(clientId: string, orderIds: string[]) {
    const uniqueIds = [...new Set(orderIds)];
    if (uniqueIds.length !== orderIds.length) throw new ApplicationError('VALIDATION', 'Commande dupliquée.');
    return this.db.$transaction(async (tx) => {
      const orders = await tx.order.findMany({ where: { id: { in: uniqueIds }, clientId } });
      if (orders.length !== uniqueIds.length) throw new ApplicationError('NOT_FOUND', 'Une commande est introuvable.');
      if (orders.some((order) => order.paymentStatus === 'paid' || order.paymentStatus === 'not_required')) {
        throw new ApplicationError('CONFLICT', 'Une commande est déjà réglée.');
      }
      const amount = orders.reduce((sum, order) => sum + order.total, 0);
      const amountXof = Math.round(amount);
      const payment = await tx.checkoutPayment.create({
        data: {
          clientId,
          orderIdsJson: JSON.stringify(uniqueIds),
          amount,
          amountXof,
          orders: { connect: uniqueIds.map((id) => ({ id })) },
        },
      });
      await tx.order.updateMany({ where: { id: { in: uniqueIds } }, data: { paymentStatus: 'pending' } });
      return this.toRecord(payment);
    });
  }

  async attachProviderSession(paymentId: string, providerTransactionId: string, checkoutUrl: string) {
    const payment = await this.db.checkoutPayment.update({ where: { id: paymentId }, data: { providerTransactionId, checkoutUrl } });
    return this.toRecord(payment);
  }

  async getForClient(paymentId: string, clientId: string) {
    const payment = await this.db.checkoutPayment.findFirst({ where: { id: paymentId, clientId } });
    if (!payment) throw new ApplicationError('NOT_FOUND', 'Paiement introuvable.');
    return this.toRecord(payment);
  }

  async getByProviderTransactionId(transactionId: string) {
    const payment = await this.db.checkoutPayment.findUnique({ where: { providerTransactionId: transactionId } });
    return payment ? this.toRecord(payment) : null;
  }

  async syncProviderStatus(paymentId: string, status: 'pending' | 'paid' | 'failed' | 'refunded') {
    return this.db.$transaction(async (tx) => {
      const payment = await tx.checkoutPayment.findUnique({ where: { id: paymentId } });
      if (!payment) throw new ApplicationError('NOT_FOUND', 'Paiement introuvable.');
      const orderIds = JSON.parse(payment.orderIdsJson) as string[];
      if (payment.status === 'paid' && status !== 'refunded') return this.toRecord(payment);
      if (payment.status === 'failed' && status === 'pending') return this.toRecord(payment);
      await tx.checkoutPayment.update({ where: { id: payment.id }, data: { status } });
      if (status === 'paid') {
        await tx.order.updateMany({ where: { id: { in: orderIds }, paymentStatus: 'pending' }, data: { paymentStatus: 'paid', status: 'confirmed' } });
        const orders = await tx.order.findMany({ where: { id: { in: orderIds } }, select: { id: true, clientId: true, vendorId: true } });
        for (const order of orders) {
          const vendor = await tx.vendorProfile.findUniqueOrThrow({ where: { id: order.vendorId } });
          await tx.appNotification.create({ data: { userId: vendor.userId, type: 'order', title: 'Commande payée', message: 'Une commande payée est prête à être préparée.' } });
          await tx.appNotification.create({ data: { userId: order.clientId, type: 'payment', title: 'Paiement confirmé', message: 'Votre paiement a été confirmé. La boutique prépare votre commande.' } });
        }
      } else if (status === 'failed' && payment.status === 'pending') {
        const orders = await tx.order.findMany({ where: { id: { in: orderIds } }, include: { items: true } });
        for (const order of orders) {
          for (const item of order.items) {
            await tx.product.update({ where: { id: item.productId }, data: { stock: { increment: item.quantity } } });
          }
        }
        await tx.order.updateMany({ where: { id: { in: orderIds }, paymentStatus: 'pending' }, data: { paymentStatus: 'failed' } });
        for (const order of orders) {
          await tx.appNotification.create({ data: { userId: order.clientId, type: 'payment', title: 'Paiement échoué', message: `Le paiement de la commande ${order.id} a échoué. Le stock a été libéré ; vous pouvez réessayer.` } });
        }
      } else if (status === 'refunded') {
        await tx.order.updateMany({ where: { id: { in: orderIds } }, data: { paymentStatus: 'refunded' } });
        const orders = await tx.order.findMany({ where: { id: { in: orderIds } }, select: { id: true, clientId: true, vendorId: true } });
        for (const order of orders) {
          const vendor = await tx.vendorProfile.findUniqueOrThrow({ where: { id: order.vendorId } });
          await tx.appNotification.create({ data: { userId: order.clientId, type: 'payment', title: 'Paiement remboursé', message: `Le paiement de la commande ${order.id} a été remboursé.` } });
          await tx.appNotification.create({ data: { userId: vendor.userId, type: 'payment', title: 'Commande remboursée', message: `La commande ${order.id} a été remboursée.` } });
        }
      }
      const updated = await tx.checkoutPayment.findUniqueOrThrow({ where: { id: paymentId } });
      return this.toRecord(updated);
    });
  }
}
