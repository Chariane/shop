import { AuthUseCases } from './application/auth-use-cases';
import { CatalogUseCases } from './application/catalog-use-cases';
import { OrderUseCases } from './application/order-use-cases';
import { PlatformConfigUseCases } from './application/platform-config-use-cases';
import { ReviewUseCases } from './application/review-use-cases';
import { CheckoutPaymentUseCases } from './application/checkout-payment-use-cases';
import { SandboxFedaPayGateway } from './infrastructure/payments/fedapay-gateway';
import { env } from './infrastructure/config/environment';
import { SmtpEmailVerificationSender } from './infrastructure/email/smtp-email-verification-sender';
import { prisma } from './infrastructure/database/prisma-client';
import {
  PrismaAuthRepository,
  PrismaCatalogRepository,
  PrismaOrdersRepository,
  PrismaShopReviewRepository,
  PrismaCheckoutPaymentsRepository,
} from './infrastructure/database/prisma-repositories';
import {
  BcryptPasswordHasher,
  JwtTokenService,
} from './infrastructure/security/security-services';
import { createHttpApp } from './presentation/http/app';

const tokens = new JwtTokenService();
const auth = new AuthUseCases(
  new PrismaAuthRepository(prisma),
  new BcryptPasswordHasher(),
  tokens,
  new SmtpEmailVerificationSender(),
  env.accessSecret,
);
const catalog = new CatalogUseCases(new PrismaCatalogRepository(prisma));
const orders = new OrderUseCases(new PrismaOrdersRepository(prisma));
const reviews = new ReviewUseCases(new PrismaShopReviewRepository(prisma));
const checkoutPayments = new CheckoutPaymentUseCases(
  new PrismaCheckoutPaymentsRepository(prisma),
  new SandboxFedaPayGateway(env.fedapaySecretKey ?? '', env.fedapayEnvironment),
);

const app = createHttpApp({
  auth,
  catalog,
  orders,
  reviews,
  checkoutPayments,
  platformConfig: new PlatformConfigUseCases(prisma),
  tokens,
  corsOrigin: env.corsOrigin,
  fedapayWebhookSecret: env.fedapayWebhookSecret,
  checkDatabase: async () => {
    await prisma.$queryRaw`SELECT 1`;
  },
});

const server = app.listen(env.port, () => {
  console.log(`ShopHub API disponible sur http://localhost:${env.port}`);
});

async function shutdown() {
  server.close();
  await prisma.$disconnect();
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
