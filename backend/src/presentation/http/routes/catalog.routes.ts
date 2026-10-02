import { Router, type Request } from 'express';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { randomUUID } from 'node:crypto';

import { CatalogUseCases } from '../../../application/catalog-use-cases';
import { ReviewUseCases } from '../../../application/review-use-cases';
import { ApplicationError } from '../../../domain/errors';
import type { NewProduct } from '../../../domain/models';
import { asyncHandler } from '../async-handler';
import { createAuthMiddleware, type AuthenticatedRequest } from '../auth-middleware';
import { presentProduct, presentVendor } from '../presenters';
import { parseInput, z } from '../validation';

const createProductSchema = z.object({
  name: z.string().trim().min(1),
  price: z.coerce.number().int().positive(),
  imageUrl: z.string().trim().min(1),
  gallery: z.array(z.string().trim().min(1)).max(4).default([]),
  category: z.string().trim().min(1),
  shortDescription: z.string().optional(),
  longDescription: z.string().optional(),
  originalPrice: z.coerce.number().int().positive().nullable().optional(),
  stock: z.coerce.number().int().nonnegative().default(0),
  freeShipping: z.boolean().default(false),
  warrantyMonths: z.coerce.number().int().nonnegative().default(12),
  isActive: z.boolean().default(true),
  tags: z.array(z.string()).default([]),
  specifications: z.record(z.string(), z.string()).default({}),
});

async function persistImage(request: Request, image: { name: string; data: string }): Promise<string> {
  if (!/^[A-Za-z0-9+/]*={0,2}$/.test(image.data) || image.data.length > 7 * 1024 * 1024) {
    throw new ApplicationError('VALIDATION', 'Image invalide ou trop volumineuse.');
  }
  const bytes = Buffer.from(image.data, 'base64');
  if (!bytes.length || bytes.length > 5 * 1024 * 1024) {
    throw new ApplicationError('VALIDATION', 'Chaque image doit faire 5 Mo maximum.');
  }
  let extension: string | null = null;
  if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) extension = 'jpg';
  else if (bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) extension = 'png';
  else if (bytes.toString('ascii', 0, 4) === 'RIFF' && bytes.toString('ascii', 8, 12) === 'WEBP') extension = 'webp';
  if (!extension) throw new ApplicationError('VALIDATION', 'Format accepté : JPEG, PNG ou WebP.');

  const directory = path.resolve(process.cwd(), 'uploads');
  await mkdir(directory, { recursive: true });
  const filename = randomUUID() + '.' + extension;
  await writeFile(path.join(directory, filename), bytes, { flag: 'wx' });
  return request.protocol + '://' + request.get('host') + '/uploads/' + filename;
}

export function createCatalogRouter(
  catalog: CatalogUseCases,
  reviews: ReviewUseCases,
  middleware: ReturnType<typeof createAuthMiddleware>,
) {
  const router = Router();

  router.post('/uploads/profile-image', middleware.requireAuth, asyncHandler(async (request, response) => {
    const input = parseInput(z.object({ image: z.object({ name: z.string(), data: z.string().min(1) }) }), request.body);
    const image = await persistImage(request, input.image);
    response.status(201).json({ image });
  }));

  router.post('/uploads/images', middleware.requireAuth, middleware.requireRole('vendor'), asyncHandler(async (request, response) => {
    const input = parseInput(z.object({ images: z.array(z.object({ name: z.string(), data: z.string() })).min(1).max(5) }), request.body);
    const images: string[] = [];
    for (const image of input.images) images.push(await persistImage(request, image));
    response.status(201).json({ images });
  }));

  router.get('/products', asyncHandler(async (request, response) => {
    const products = await catalog.listProducts({
      category: typeof request.query.category === 'string' ? request.query.category : undefined,
      query: typeof request.query.q === 'string' ? request.query.q.trim() : undefined,
    });
    response.json({ products: products.map(presentProduct) });
  }));

  router.get('/products/:id', asyncHandler(async (request, response) => {
    const id = parseInput(z.string().min(1), request.params.id);
    const product = await catalog.getProduct(id);
    response.json({ product: presentProduct(product) });
  }));

  router.get('/vendors', asyncHandler(async (_request, response) => {
    const vendors = await catalog.listVendors();
    response.json({ vendors: vendors.map(presentVendor) });
  }));

  router.get('/vendors/:id/reviews', asyncHandler(async (request, response) => {
    const vendorId = parseInput(z.string().min(1), request.params.id);
    const rows = await reviews.listForVendor(vendorId);
    response.json({ reviews: rows.map((review) => ({ ...review, createdAt: review.createdAt.toISOString() })) });
  }));

  router.get('/vendors/:id', asyncHandler(async (request, response) => {
    const id = parseInput(z.string().min(1), request.params.id);
    const vendor = await catalog.getVendor(id);
    response.json({ vendor: presentVendor(vendor) });
  }));

  router.patch(
    '/products/:id',
    middleware.requireAuth,
    middleware.requireRole('vendor'),
    asyncHandler(async (request, response) => {
      const authenticated = request as AuthenticatedRequest;
      if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
      const id = parseInput(z.string().min(1), request.params.id);
      const parsed = parseInput(createProductSchema, request.body);
      const product = await catalog.updateProduct(authenticated.auth.userId, id, {
        ...parsed,
        shortDescription: parsed.shortDescription ?? parsed.name,
        longDescription: parsed.longDescription ?? parsed.name,
        originalPrice: parsed.originalPrice,
      });
      response.json({ product: presentProduct(product) });
    }),
  );

  router.post(
    '/products',
    middleware.requireAuth,
    middleware.requireRole('vendor'),
    asyncHandler(async (request, response) => {
      const authenticated = request as AuthenticatedRequest;
      if (!authenticated.auth) throw new ApplicationError('UNAUTHORIZED', 'Authentification requise.');
      const parsed = parseInput(createProductSchema, request.body);
      const input: NewProduct = {
        ...parsed,
        shortDescription: parsed.shortDescription ?? parsed.name,
        longDescription: parsed.longDescription ?? parsed.name,
        originalPrice: parsed.originalPrice,
      };
      const product = await catalog.createProduct(authenticated.auth.userId, input);
      response.status(201).json({ product: presentProduct(product) });
    }),
  );

  return router;
}
