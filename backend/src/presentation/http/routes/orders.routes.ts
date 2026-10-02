import { Router } from 'express';

import { OrderUseCases } from '../../../application/order-use-cases';
import { ReviewUseCases } from '../../../application/review-use-cases';
import { CheckoutPaymentUseCases } from '../../../application/checkout-payment-use-cases';
import { ApplicationError } from '../../../domain/errors';
import type { DeliveryAddress } from '../../../domain/models';
import { asyncHandler } from '../async-handler';
import { createAuthMiddleware, type AuthenticatedRequest } from '../auth-middleware';
import { presentOrder } from '../presenters';
import { parseInput, z } from '../validation';

const createOrderSchema = z.object({
  items: z.array(z.object({
    productId: z.string().min(1),
    quantity: z.coerce.number().int().positive(),
  })).min(1),
  deliveryMethod: z.string().optional(),
  deliveryFee: z.coerce.number().nonnegative().default(0),
  deliveryAddress: z.object({
    fullName: z.string().trim().min(1),
    phone: z.string().trim().min(1),
    street: z.string().trim().min(1),
    city: z.string().trim().min(1),
    country: z.string().trim().min(1),
  }),
});
const statusSchema = z.object({
  status: z.enum(['pending', 'confirmed', 'shipped', 'delivered']),
});
const reviewSchema = z.object({
  rating: z.coerce.number().int().min(1).max(5),
  comment: z.string().trim().max(500).optional(),
});

export function createOrdersRouter(
  orders: OrderUseCases,
  reviews: ReviewUseCases,
  payments: CheckoutPaymentUseCases,
  middleware: ReturnType<typeof createAuthMiddleware>,
) {
  const router = Router();

  router.get('/notifications/me', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const notifications = await orders.listNotifications(authenticated.auth.userId);
    response.json({ notifications: notifications.map((item) => ({ ...item, isRead: item.readAt !== null })) });
  }));

  router.patch('/notifications/me/read', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const input = parseInput(z.object({ id: z.string().optional() }), request.body ?? {});
    await orders.markNotificationRead(authenticated.auth.userId, input.id);
    response.status(204).end();
  }));

  router.get('/loyalty/me', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    response.json({ points: await orders.loyaltyPoints(authenticated.auth.userId) });
  }));

  router.get('/orders/me', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const role = authenticated.auth.role === 'vendor' ? 'vendor' : 'client';
    const result = await orders.listMine(authenticated.auth.userId, role);
    response.json({ orders: result.map(presentOrder) });
  }));

  router.post('/orders/checkout', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const input = parseInput(createOrderSchema, request.body);
    if (authenticated.auth.role !== 'client') throw new ApplicationError('FORBIDDEN', 'Seuls les clients peuvent commander.');
    const customerEmail = parseInput(z.string().email(), request.body.customerEmail);
    const result = await orders.place({
      userId: authenticated.auth.userId,
      role: authenticated.auth.role,
      items: input.items,
      deliveryMethod: input.deliveryMethod ?? 'standard',
      deliveryFee: input.deliveryFee,
      address: input.deliveryAddress as DeliveryAddress,
    });
    const payment = await payments.start({
      clientId: authenticated.auth.userId,
      orderIds: result.map((order) => order.id),
      name: input.deliveryAddress.fullName,
      email: customerEmail,
      phone: input.deliveryAddress.phone,
    });
    response.status(201).json({
      orders: result.map(presentOrder),
      payment: { id: payment.id, amount: payment.amount, amountXof: payment.amountXof, currency: 'XOF', status: payment.status, checkoutUrl: payment.checkoutUrl },
    });
  }));


  router.get('/payments/:id', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const payment = await payments.refresh(parseInput(z.string().min(1), request.params.id), authenticated.auth.userId);
    response.json({ payment: { id: payment.id, amount: payment.amount, amountXof: payment.amountXof, status: payment.status } });
  }));

  router.post('/orders/:id/review', middleware.requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const input = parseInput(reviewSchema, request.body);
    const review = await reviews.rateOrder({
      userId: authenticated.auth.userId,
      role: authenticated.auth.role,
      orderId: parseInput(z.string().min(1), request.params.id),
      rating: input.rating,
      comment: input.comment,
    });
    response.status(201).json({ review: { ...review, createdAt: review.createdAt.toISOString() } });
  }));

  router.patch(
    '/orders/:id/status',
    middleware.requireAuth,
    middleware.requireRole('vendor'),
    asyncHandler(async (request, response) => {
      const authenticated = request as AuthenticatedRequest;
      if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
      const { status } = parseInput(statusSchema, request.body);
      const order = await orders.changeStatus({
        userId: authenticated.auth.userId,
        role: authenticated.auth.role,
        orderId: parseInput(z.string().min(1), request.params.id),
        status,
      });
      response.json({ order: presentOrder(order) });
    }),
  );

  return router;
}
