import type { ErrorRequestHandler, RequestHandler } from 'express';
import { Prisma } from '@prisma/client';

import { ApplicationError } from '../../domain/errors';

const httpStatus: Record<string, number> = {
  VALIDATION: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INSUFFICIENT_STOCK: 409,
  SERVICE_UNAVAILABLE: 503,
  UPSTREAM: 502,
};

export const notFound: RequestHandler = (_request, _response, next) => {
  next(new ApplicationError('NOT_FOUND', 'Route introuvable.'));
};

export const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => {
  if (error instanceof ApplicationError) {
    response.status(httpStatus[error.code] ?? 400).json({ message: error.message });
    return;
  }
  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    response.status(409).json({ message: 'Cette valeur existe déjà.' });
    return;
  }

  console.error(error);
  response.status(500).json({ message: 'Une erreur interne est survenue.' });
};
