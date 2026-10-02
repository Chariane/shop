import { Prisma, PrismaClient } from '@prisma/client';
import { Router } from 'express';

import { AppError } from '../lib/errors';
import { AuthenticatedRequest, requireAuth, requireRole } from '../middleware/auth';

const prisma = new PrismaClient();
const router = Router();

const orderInclude = {
  client: true,
  vendor: { include: { user: true } },
  items: { include: { product: true } },
} as const;

type OrderWithRelations = Prisma.OrderGetPayload<{ include: typeof orderInclude }>;

function serializeOrder(order: OrderWithRelations) {
  return {
    id: order.id,
    clientId: order.clientId,
    clientName: order.client.name,
    vendorId: order.vendorId,
    vendorName: order.vendor.shopName,
    status: order.status,
    total: order.total,
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
    })),
    createdAt: order.createdAt.toISOString(),
  };
}

router.get('/orders/me', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const where = req.auth!.role === 'vendor'
      ? { vendor: { userId: req.auth!.userId } }
      : { clientId: req.auth!.userId };
    const orders = await prisma.order.findMany({ where, include: orderInclude, orderBy: { createdAt: 'desc' } });
    res.json({ orders: orders.map(serializeOrder) });
  } catch (error) {
    next(error);
  }
});

router.post('/orders', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    if (req.auth!.role !== 'client') throw new AppError(403, 'Seuls les clients peuvent créer une commande.');
    const rawItems = Array.isArray(req.body?.items) ? req.body.items : [];
    if (!rawItems.length) throw new AppError(400, 'Le panier ne peut pas être vide.');

    const quantities = new Map<string, number>();
    for (const item of rawItems) {
      const productId = typeof item?.productId === 'string' ? item.productId : '';
      const quantity = Number(item?.quantity);
      if (!productId || !Number.isInteger(quantity) || quantity < 1) {
        throw new AppError(400, 'Chaque article doit avoir un produit et une quantité valide.');
      }
      quantities.set(productId, (quantities.get(productId) ?? 0) + quantity);
    }

    const products = await prisma.product.findMany({
      where: { id: { in: [...quantities.keys()] }, isActive: true },
      include: { vendor: true },
    });
    if (products.length !== quantities.size) throw new AppError(400, 'Un produit du panier est indisponible.');
    for (const product of products) {
      if (product.stock < (quantities.get(product.id) ?? 0)) {
        throw new AppError(400, `${product.name} n'est plus suffisamment en stock.`);
      }
    }

    const address = req.body?.deliveryAddress ?? {};
    const deliveryName = typeof address.fullName === 'string' ? address.fullName.trim() : '';
    const deliveryPhone = typeof address.phone === 'string' ? address.phone.trim() : '';
    const deliveryStreet = typeof address.street === 'string' ? address.street.trim() : '';
    const deliveryCity = typeof address.city === 'string' ? address.city.trim() : '';
    const deliveryCountry = typeof address.country === 'string' ? address.country.trim() : '';
    if (![deliveryName, deliveryPhone, deliveryStreet, deliveryCity, deliveryCountry].every(Boolean)) {
      throw new AppError(400, 'Adresse de livraison incomplète.');
    }

    const grouped = new Map<string, typeof products>();
    for (const product of products) {
      const group = grouped.get(product.vendorId) ?? [];
      group.push(product);
      grouped.set(product.vendorId, group);
    }
    const deliveryFee = Math.max(0, Number(req.body?.deliveryFee) || 0);
    const created = await prisma.$transaction(async (tx) => {
      for (const product of products) {
        const quantity = quantities.get(product.id) ?? 0;
        const update = await tx.product.updateMany({
          where: { id: product.id, isActive: true, stock: { gte: quantity } },
          data: { stock: { decrement: quantity } },
        });
        if (update.count === 0) {
          throw new AppError(400, `${product.name} n'est plus suffisamment en stock.`);
        }
      }
      let deliveryFeeCharged = false;
      return Promise.all([...grouped.entries()].map(([vendorId, vendorProducts]) => {
        const subtotal = vendorProducts.reduce(
          (total, product) => total + product.price * (quantities.get(product.id) ?? 0),
          0,
        );
        const vendorDeliveryFee = deliveryFeeCharged ? 0 : deliveryFee;
        deliveryFeeCharged = true;
        return tx.order.create({
          data: {
            clientId: req.auth!.userId,
            vendorId,
            deliveryMethod: typeof req.body?.deliveryMethod === 'string' ? req.body.deliveryMethod : 'standard',
            deliveryFee: vendorDeliveryFee,
            deliveryName,
            deliveryPhone,
            deliveryStreet,
            deliveryCity,
            deliveryCountry,
            total: subtotal + vendorDeliveryFee,
            items: { create: vendorProducts.map((product) => ({
              productId: product.id,
              productName: product.name,
              unitPrice: product.price,
              quantity: quantities.get(product.id) ?? 0,
            })) },
          },
          include: orderInclude,
        });
      }));
    });
    res.status(201).json({ orders: created.map(serializeOrder) });
  } catch (error) {
    next(error);
  }
});

router.patch('/orders/:id/status', requireAuth, requireRole('vendor'), async (req: AuthenticatedRequest, res, next) => {
  try {
    const status = typeof req.body?.status === 'string' ? req.body.status : '';
    if (!['pending', 'confirmed', 'shipped', 'delivered'].includes(status)) {
      throw new AppError(400, 'Statut de commande invalide.');
    }
    const orderId = req.params.id;
    if (typeof orderId !== 'string') throw new AppError(400, 'Identifiant de commande invalide.');
    const order = await prisma.order.findUnique({ where: { id: orderId }, include: { vendor: true } });
    if (!order || order.vendor.userId !== req.auth!.userId) {
      throw new AppError(404, 'Commande introuvable.');
    }
    const updated = await prisma.order.update({ where: { id: order.id }, data: { status }, include: orderInclude });
    res.json({ order: serializeOrder(updated) });
  } catch (error) {
    next(error);
  }
});

export { router as ordersRouter };
