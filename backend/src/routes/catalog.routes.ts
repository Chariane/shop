import { PrismaClient } from '@prisma/client';
import { Router } from 'express';

import { AppError } from '../lib/errors';
import { serializeProduct, serializeVendor } from '../lib/serializers';
import { AuthenticatedRequest, requireAuth, requireRole } from '../middleware/auth';

const prisma = new PrismaClient();
const router = Router();

const productInclude = {
  vendor: { include: { user: true } },
  gallery: true,
} as const;

const vendorInclude = {
  user: true,
  _count: { select: { products: true } },
} as const;

router.get('/products', async (req, res, next) => {
  try {
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const query = typeof req.query.q === 'string' ? req.query.q.trim() : '';
    const products = await prisma.product.findMany({
      where: {
        isActive: true,
        ...(category ? { category } : {}),
        ...(query ? { name: { contains: query } } : {}),
      },
      include: productInclude,
      orderBy: { createdAt: 'desc' },
    });
    res.json({ products: products.map(serializeProduct) });
  } catch (error) {
    next(error);
  }
});

router.get('/products/:id', async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({ where: { id: req.params.id }, include: productInclude });
    if (!product || !product.isActive) throw new AppError(404, 'Produit introuvable.');
    res.json({ product: serializeProduct(product) });
  } catch (error) {
    next(error);
  }
});

router.get('/vendors', async (_req, res, next) => {
  try {
    const vendors = await prisma.vendorProfile.findMany({
      include: vendorInclude,
      orderBy: { createdAt: 'desc' },
    });
    res.json({ vendors: vendors.map(serializeVendor) });
  } catch (error) {
    next(error);
  }
});

router.get('/vendors/:id', async (req, res, next) => {
  try {
    const vendor = await prisma.vendorProfile.findUnique({ where: { id: req.params.id }, include: vendorInclude });
    if (!vendor) throw new AppError(404, 'Boutique introuvable.');
    res.json({ vendor: serializeVendor(vendor) });
  } catch (error) {
    next(error);
  }
});

router.post('/products', requireAuth, requireRole('vendor'), async (req: AuthenticatedRequest, res, next) => {
  try {
    const vendor = await prisma.vendorProfile.findUnique({ where: { userId: req.auth!.userId } });
    if (!vendor) throw new AppError(403, 'Profil vendeur introuvable.');
    const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
    const price = Number(req.body?.price);
    const imageUrl = typeof req.body?.imageUrl === 'string' ? req.body.imageUrl.trim() : '';
    const category = typeof req.body?.category === 'string' ? req.body.category.trim() : '';
    if (!name || !imageUrl || !category || !Number.isFinite(price) || price <= 0) {
      throw new AppError(400, 'Nom, prix positif, image et catégorie sont requis.');
    }

    const product = await prisma.product.create({
      data: {
        vendorId: vendor.id,
        name,
        price,
        imageUrl,
        category,
        shortDescription: typeof req.body?.shortDescription === 'string' ? req.body.shortDescription : name,
        longDescription: typeof req.body?.longDescription === 'string' ? req.body.longDescription : name,
        originalPrice: Number.isFinite(Number(req.body?.originalPrice)) ? Number(req.body.originalPrice) : null,
        stock: Math.max(0, Number(req.body?.stock) || 0),
        freeShipping: Boolean(req.body?.freeShipping),
        warrantyMonths: Math.max(0, Number(req.body?.warrantyMonths) || 0),
        tagsJson: JSON.stringify(Array.isArray(req.body?.tags) ? req.body.tags : []),
        specificationsJson: JSON.stringify(req.body?.specifications ?? {}),
      },
      include: productInclude,
    });
    res.status(201).json({ product: serializeProduct(product) });
  } catch (error) {
    next(error);
  }
});

export { router as catalogRouter };
