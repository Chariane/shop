import type { NextFunction, Request, Response } from 'express';

import { AppError } from '../lib/errors';

export function notFound(_req: Request, _res: Response, next: NextFunction) {
  next(new AppError(404, 'Ressource introuvable.'));
}

export function errorHandler(
  error: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
) {
  const status = error instanceof AppError ? error.statusCode : 500;
  if (status === 500) console.error(error);
  res.status(status).json({ message: error.message || 'Erreur interne du serveur.' });
}
