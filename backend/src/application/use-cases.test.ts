import assert from 'node:assert/strict';
import test from 'node:test';

import { AuthUseCases } from './auth-use-cases';
import { CatalogUseCases } from './catalog-use-cases';
import { OrderUseCases } from './order-use-cases';
import { ReviewUseCases } from './review-use-cases';
import { CheckoutPaymentUseCases } from './checkout-payment-use-cases';
import { ApplicationError } from '../domain/errors';
import type { AuthRepository, CatalogRepository, OrdersRepository } from '../domain/repositories';

const unusedAuthRepository = {} as AuthRepository;
const unusedCatalogRepository = {} as CatalogRepository;
const unusedOrdersRepository = {} as OrdersRepository;
const passwordHasher = {
  hash: async (value: string) => value,
  verify: async () => false,
};
const tokenService = {
  issueAccessToken: () => 'access',
  issueRefreshToken: () => 'refresh',
  verifyRefreshToken: () => ({ userId: 'u1', role: 'client' }),
  hash: (value: string) => value,
  expiresAt: () => new Date(Date.now() + 60_000),
};
const emailSender = {
  isConfigured: () => true,
  sendVerificationCode: async () => {},
};
const verificationSecret = 'test-verification-secret';

test('login refuse des identifiants inconnus', async () => {
  const users = {
    findUserByEmail: async () => null,
  } as unknown as AuthRepository;
  const auth = new AuthUseCases(users, passwordHasher, tokenService, emailSender, verificationSecret);

  await assert.rejects(
    auth.login('absent@example.com', 'password'),
    (error: unknown) => error instanceof ApplicationError && error.code === 'UNAUTHORIZED',
  );
});

test('inscription vendeur exige un nom de boutique', async () => {
  const users = {
    findUserByEmail: async () => null,
  } as unknown as AuthRepository;
  const auth = new AuthUseCases(users, passwordHasher, tokenService, emailSender, verificationSecret);

  await assert.rejects(
    auth.register({
      name: 'Awa',
      email: 'awa@example.com',
      password: 'secure-password',
      role: 'vendor',
    }),
    (error: unknown) => error instanceof ApplicationError && error.code === 'VALIDATION',
  );
});

test('un vendeur ne peut pas passer une commande client', async () => {
  const orders = new OrderUseCases(unusedOrdersRepository);

  await assert.rejects(
    orders.place({
      userId: 'v1',
      role: 'vendor',
      items: [{ productId: 'p1', quantity: 1 }],
      deliveryMethod: 'standard',
      deliveryFee: 0,
      address: { fullName: 'Awa', phone: '1', street: 'Rue 1', city: 'Cotonou', country: 'Bénin' },
    }),
    (error: unknown) => error instanceof ApplicationError && error.code === 'FORBIDDEN',
  );
});

test('un produit inexistant produit une erreur not found', async () => {
  const catalog = new CatalogUseCases({
    findProduct: async () => null,
  } as unknown as CatalogRepository);

  await assert.rejects(
    catalog.getProduct('missing'),
    (error: unknown) => error instanceof ApplicationError && error.code === 'NOT_FOUND',
  );
});


test('inscription crée un compte en attente et ouvre une session seulement après confirmation', async () => {
  const profile = {
    id: 'u1', name: 'Awa', email: 'awa@example.com', role: 'client' as const,
    avatarUrl: null, createdAt: new Date(), vendorProfile: null,
  };
  let verified = false;
  let challenge: { codeHash: string; attempts: number; expiresAt: Date; sentAt: Date } | null = null;
  let sentCode = '';
  const users = {
    findUserByEmail: async () => ({ profile, passwordHash: 'hashed', emailVerified: verified }),
    createUser: async () => profile,
    saveEmailVerification: async (input: { codeHash: string; expiresAt: Date; sentAt: Date; email: string }) => {
      challenge = { codeHash: input.codeHash, attempts: 0, expiresAt: input.expiresAt, sentAt: input.sentAt };
    },
    findEmailVerification: async () => challenge,
    incrementEmailVerificationAttempts: async () => { if (challenge) challenge.attempts += 1; },
    completeEmailVerification: async (_email: string, hash: string) => {
      if (!challenge || challenge.codeHash !== hash) return false;
      verified = true;
      challenge = null;
      return true;
    },
    createRefreshToken: async () => {},
  } as unknown as AuthRepository;
  const sender = {
    isConfigured: () => true,
    sendVerificationCode: async (_email: string, code: string) => { sentCode = code; },
  };
  const passwords = { hash: async () => 'hashed', verify: async () => true };
  const auth = new AuthUseCases(users, passwords, tokenService, sender, verificationSecret);

  const result = await auth.register({ name: 'Awa', email: 'AWA@example.com', password: 'secure-password', role: 'client' });
  assert.deepEqual(result, { email: 'awa@example.com', verificationRequired: true });
  assert.match(sentCode, /^\d{6}$/);
  await assert.rejects(auth.login('awa@example.com', 'secure-password'), (error: unknown) =>
    error instanceof ApplicationError && error.code === 'FORBIDDEN',
  );
  const session = await auth.verifyEmail('awa@example.com', sentCode);
  assert.equal(session.user.id, 'u1');
  assert.equal(verified, true);
});


test('une note de boutique exige un client et une note de 1 à 5', async () => {
  const reviews = new ReviewUseCases({
    rateDeliveredOrder: async () => { throw new Error('Le repository ne doit pas être appelé'); },
    listForVendor: async () => [],
  });

  assert.throws(
    () => reviews.rateOrder({ userId: 'v1', role: 'vendor', orderId: 'o1', rating: 5 }),
    (error: unknown) => error instanceof ApplicationError && error.code === 'FORBIDDEN',
  );
  assert.throws(
    () => reviews.rateOrder({ userId: 'c1', role: 'client', orderId: 'o1', rating: 6 }),
    (error: unknown) => error instanceof ApplicationError && error.code === 'VALIDATION',
  );
});


test('checkout crée une transaction sandbox à partir des commandes validées', async () => {
  let requestedAmount = 0;
  const paymentUseCases = new CheckoutPaymentUseCases({
    createForOrders: async (clientId, orderIds) => ({
      id: 'pay1', clientId, orderIds, amount: 6559, amountXof: 6559, status: 'pending',
      providerTransactionId: null, checkoutUrl: null,
    }),
    attachProviderSession: async (id, providerTransactionId, checkoutUrl) => ({
      id, clientId: 'client1', orderIds: ['order1'], amount: 6559, amountXof: 6559, status: 'pending',
      providerTransactionId, checkoutUrl,
    }),
    getForClient: async () => { throw new Error('non appelé'); },
    syncProviderStatus: async () => { throw new Error('non appelé'); },
  }, {
    createSession: async ({ amountXof }) => {
      requestedAmount = amountXof;
      return { transactionId: 'fedapay-tx1', checkoutUrl: 'https://sandbox.fedapay.com/pay/1' };
    },
    getStatus: async () => 'pending',
  });
  const result = await paymentUseCases.start({
    clientId: 'client1', orderIds: ['order1'], name: 'Awa',
    email: 'awa@example.com', phone: '+22990000000',
  });
  assert.equal(requestedAmount, 6559);
  assert.equal(result.providerTransactionId, 'fedapay-tx1');
});
