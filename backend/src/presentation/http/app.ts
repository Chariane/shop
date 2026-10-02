import cors from 'cors';
import express from 'express';
import path from 'node:path';
import { getFedaPayTransactionEvent, verifyFedaPayWebhook } from '../../infrastructure/payments/fedapay-webhook';

import type { AuthUseCases } from '../../application/auth-use-cases';
import type { CatalogUseCases } from '../../application/catalog-use-cases';
import type { OrderUseCases } from '../../application/order-use-cases';
import type { PlatformConfigUseCases } from '../../application/platform-config-use-cases';
import type { ReviewUseCases } from '../../application/review-use-cases';
import type { CheckoutPaymentUseCases } from '../../application/checkout-payment-use-cases';
import type { JwtTokenService } from '../../infrastructure/security/security-services';
import { asyncHandler } from './async-handler';
import { createAuthMiddleware } from './auth-middleware';
import { errorHandler, notFound } from './error-handler';
import { createAuthRouter } from './routes/auth.routes';
import { createCatalogRouter } from './routes/catalog.routes';
import { createOrdersRouter } from './routes/orders.routes';

export interface HttpAppDependencies {
  auth: AuthUseCases;
  catalog: CatalogUseCases;
  orders: OrderUseCases;
  reviews: ReviewUseCases;
  checkoutPayments: CheckoutPaymentUseCases;
  platformConfig: PlatformConfigUseCases;
  tokens: JwtTokenService;
  checkDatabase: () => Promise<void>;
  corsOrigin: string;
  fedapayWebhookSecret?: string;
}

export function createHttpApp(dependencies: HttpAppDependencies) {
  const app = express();
  const authMiddleware = createAuthMiddleware(dependencies.tokens);

  app.use(cors({
    origin: dependencies.corsOrigin === '*'
      ? true
      : dependencies.corsOrigin.split(',').map((origin) => origin.trim()),
  }));
  app.post('/api/webhooks/fedapay', express.raw({ type: ['application/json', 'application/*+json'], limit: '1mb' }), asyncHandler(async (request, response) => {
    if (!dependencies.fedapayWebhookSecret) {
      response.status(503).json({ message: 'Le webhook FedaPay n’est pas configuré.' });
      return;
    }
    if (!Buffer.isBuffer(request.body) || !verifyFedaPayWebhook(
      request.body,
      request.header('x-fedapay-signature'),
      dependencies.fedapayWebhookSecret,
    )) {
      response.status(400).json({ message: 'Signature FedaPay invalide.' });
      return;
    }
    let payload: unknown;
    try {
      payload = JSON.parse(request.body.toString('utf8'));
    } catch {
      response.status(400).json({ message: 'Payload webhook invalide.' });
      return;
    }
    const event = getFedaPayTransactionEvent(payload);
    if (!event) {
      response.status(200).json({ received: true, ignored: true });
      return;
    }
    const processed = await dependencies.checkoutPayments.processProviderEvent(event.transactionId);
    response.status(200).json({ received: true, processed });
  }));
  app.use(express.json({ limit: '40mb' }));
  app.use('/uploads', express.static(path.resolve(process.cwd(), 'uploads')));

  app.get('/api/app-config', asyncHandler(async (_request, response) => {
    response.json(await dependencies.platformConfig.get());
  }));

  app.get('/health', asyncHandler(async (_request, response) => {
    await dependencies.checkDatabase();
    response.json({ status: 'ok' });
  }));
  app.use('/api/auth', createAuthRouter(dependencies.auth, authMiddleware.requireAuth));
  app.use('/api', createCatalogRouter(dependencies.catalog, dependencies.reviews, authMiddleware));
  app.use('/api', createOrdersRouter(dependencies.orders, dependencies.reviews, dependencies.checkoutPayments, authMiddleware));
  app.use(notFound);
  app.use(errorHandler);

  return app;
}
