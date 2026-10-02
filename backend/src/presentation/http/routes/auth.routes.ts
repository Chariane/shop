import { Router } from 'express';

import { AuthUseCases } from '../../../application/auth-use-cases';
import { ApplicationError } from '../../../domain/errors';
import { asyncHandler } from '../async-handler';
import type { AuthenticatedRequest } from '../auth-middleware';
import { presentUser } from '../presenters';
import { parseInput, z } from '../validation';

const registerSchema = z.object({
  name: z.string().trim().min(1),
  email: z.string().trim().email(),
  password: z.string().min(8),
  role: z.enum(['client', 'vendor']).default('client'),
  shopName: z.string().trim().optional(),
  shopTagline: z.string().optional(),
  shopDescription: z.string().optional(),
  shopCity: z.string().optional(),
  shopCountry: z.string().optional(),
  shopCategories: z.array(z.string()).optional(),
  avatarUrl: z.string().optional(),
});
const verificationSchema = z.object({ email: z.string().trim().email(), code: z.string().regex(/^\d{6}$/) });
const resendVerificationSchema = z.object({ email: z.string().trim().email() });
const loginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(1),
});
const refreshSchema = z.object({ refreshToken: z.string().min(1) });
const profileSchema = z.object({
  name: z.string().trim().min(1),
  email: z.string().trim().email(),
  avatarUrl: z.string().trim().nullable().optional(),
});
const vendorProfileSchema = z.object({
  shopName: z.string().trim().min(1),
  shopTagline: z.string().trim().nullable().optional(),
  shopDescription: z.string().trim().nullable().optional(),
  shopBannerUrl: z.string().trim().nullable().optional(),
  shopCity: z.string().trim().nullable().optional(),
  shopCountry: z.string().trim().nullable().optional(),
  shopCategories: z.array(z.string().trim().min(1)).default([]),
});


export function createAuthRouter(
  auth: AuthUseCases,
  requireAuth: ReturnType<typeof import('../auth-middleware').createAuthMiddleware>['requireAuth'],
) {
  const router = Router();

  router.post('/register', asyncHandler(async (request, response) => {
    const input = parseInput(registerSchema, request.body);
    const result = await auth.register(input);
    response.status(202).json({ ...result, message: 'Un code de vérification a été envoyé à cette adresse.' });
  }));

  router.post('/verification/confirm', asyncHandler(async (request, response) => {
    const input = parseInput(verificationSchema, request.body);
    const session = await auth.verifyEmail(input.email, input.code);
    response.json({ ...session, user: presentUser(session.user) });
  }));

  router.post('/verification/resend', asyncHandler(async (request, response) => {
    const input = parseInput(resendVerificationSchema, request.body);
    await auth.resendVerification(input.email);
    response.status(202).json({ message: 'Si ce compte attend une vérification, un nouveau code sera envoyé.' });
  }));

  router.post('/login', asyncHandler(async (request, response) => {
    const input = parseInput(loginSchema, request.body);
    const session = await auth.login(input.email, input.password);
    response.json({ ...session, user: presentUser(session.user) });
  }));

  router.post('/refresh', asyncHandler(async (request, response) => {
    const { refreshToken } = parseInput(refreshSchema, request.body);
    const session = await auth.refresh(refreshToken);
    response.json({ ...session, user: presentUser(session.user) });
  }));

  router.post('/logout', asyncHandler(async (request, response) => {
    const refreshToken = typeof request.body?.refreshToken === 'string'
      ? request.body.refreshToken
      : undefined;
    await auth.logout(refreshToken);
    response.status(204).send();
  }));

  router.get('/me', requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const user = await auth.getCurrentUser(authenticated.auth.userId);
    response.json({ user: presentUser(user) });
  }));
  router.patch('/me', requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const input = parseInput(profileSchema, request.body);
    const user = await auth.updateProfile(authenticated.auth.userId, {
      name: input.name,
      email: input.email,
      avatarUrl: input.avatarUrl ?? null,
    });
    response.json({ user: presentUser(user) });
  }));

  router.put('/me/shop', requireAuth, asyncHandler(async (request, response) => {
    const authenticated = request as AuthenticatedRequest;
    if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
    const input = parseInput(vendorProfileSchema, request.body);
    const user = await auth.updateVendorProfile(authenticated.auth.userId, {
      shopName: input.shopName,
      shopTagline: input.shopTagline ?? null,
      shopDescription: input.shopDescription ?? null,
      shopBannerUrl: input.shopBannerUrl ?? null,
      shopCity: input.shopCity ?? null,
      shopCountry: input.shopCountry ?? null,
      categories: input.shopCategories,
    });
    response.json({ user: presentUser(user) });
  }));


  return router;
}
