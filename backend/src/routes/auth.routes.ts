import { Prisma, PrismaClient } from '@prisma/client';
import { Router } from 'express';

import { AppError } from '../lib/errors';
import { hashPassword, verifyPassword } from '../lib/password';
import { serializeUser } from '../lib/serializers';
import { hashToken, refreshTokenExpiry, signAccessToken, signRefreshToken, verifyToken } from '../lib/tokens';
import { AuthenticatedRequest, requireAuth } from '../middleware/auth';

const prisma = new PrismaClient();
const router = Router();

const userInclude = {
  vendorProfile: { include: { user: true, _count: { select: { products: true } } } },
} as const;

type UserWithVendor = Prisma.UserGetPayload<{ include: typeof userInclude }>;

function stringValue(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function tokenResponse(user: UserWithVendor) {
  const accessToken = signAccessToken(user.id, user.role);
  const refreshToken = signRefreshToken(user.id, user.role);
  return { accessToken, refreshToken, user: serializeUser(user) };
}

async function issueTokens(user: UserWithVendor) {
  const result = tokenResponse(user);
  await prisma.refreshToken.create({
    data: {
      tokenHash: hashToken(result.refreshToken),
      userId: user.id,
      expiresAt: refreshTokenExpiry(),
    },
  });
  return result;
}

router.post('/register', async (req, res, next) => {
  try {
    const name = stringValue(req.body?.name);
    const email = stringValue(req.body?.email).toLowerCase();
    const password = stringValue(req.body?.password);
    const role = stringValue(req.body?.role) === 'vendor' ? 'vendor' : 'client';

    if (!name || !email || password.length < 8) {
      throw new AppError(400, 'Nom, email et mot de passe de 8 caractères minimum requis.');
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw new AppError(409, 'Un compte utilise déjà cet email.');

    const shopName = stringValue(req.body?.shopName);
    if (role === 'vendor' && !shopName) {
      throw new AppError(400, 'Le nom de la boutique est requis pour un vendeur.');
    }

    const categories = Array.isArray(req.body?.shopCategories)
      ? req.body.shopCategories.filter((item: unknown): item is string => typeof item === 'string')
      : [];
    const user = await prisma.user.create({
      data: {
        name,
        email,
        passwordHash: await hashPassword(password),
        role,
        avatarUrl: stringValue(req.body?.avatarUrl) || null,
        vendorProfile: role === 'vendor'
            ? {
                create: {
                  shopName,
                  shopTagline: stringValue(req.body?.shopTagline) || null,
                  shopDescription: stringValue(req.body?.shopDescription) || null,
                  shopCity: stringValue(req.body?.shopCity) || 'Cotonou',
                  shopCountry: stringValue(req.body?.shopCountry) || 'Bénin',
                  shopCategoriesJson: JSON.stringify(categories),
                  shopFoundedYear: new Date().getFullYear(),
                },
              }
            : undefined,
      },
      include: userInclude,
    });

    res.status(201).json(await issueTokens(user));
  } catch (error) {
    next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const email = stringValue(req.body?.email).toLowerCase();
    const password = stringValue(req.body?.password);
    const user = await prisma.user.findUnique({ where: { email }, include: userInclude });

    if (!user || !(await verifyPassword(password, user.passwordHash))) {
      throw new AppError(401, 'Email ou mot de passe incorrect.');
    }

    res.json(await issueTokens(user));
  } catch (error) {
    next(error);
  }
});

router.post('/refresh', async (req, res, next) => {
  try {
    const refreshToken = stringValue(req.body?.refreshToken);
    if (!refreshToken) throw new AppError(401, 'Refresh token requis.');

    let payload;
    try {
      payload = verifyToken(refreshToken, 'refresh');
    } catch {
      throw new AppError(401, 'Refresh token invalide ou expiré.');
    }

    const savedToken = await prisma.refreshToken.findUnique({
      where: { tokenHash: hashToken(refreshToken) },
    });
    if (
      !savedToken ||
      savedToken.userId !== payload.sub ||
      savedToken.revokedAt ||
      savedToken.expiresAt <= new Date()
    ) {
      throw new AppError(401, 'Refresh token révoqué ou expiré.');
    }

    await prisma.refreshToken.update({
      where: { id: savedToken.id },
      data: { revokedAt: new Date() },
    });
    const user = await prisma.user.findUniqueOrThrow({ where: { id: payload.sub }, include: userInclude });
    res.json(await issueTokens(user));
  } catch (error) {
    next(error);
  }
});

router.post('/logout', async (req, res, next) => {
  try {
    const refreshToken = stringValue(req.body?.refreshToken);
    if (refreshToken) {
      await prisma.refreshToken.updateMany({
        where: { tokenHash: hashToken(refreshToken), revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

router.get('/me', requireAuth, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.auth!.userId }, include: userInclude });
    if (!user) throw new AppError(401, 'Utilisateur introuvable.');
    res.json({ user: serializeUser(user) });
  } catch (error) {
    next(error);
  }
});

export { router as authRouter };
