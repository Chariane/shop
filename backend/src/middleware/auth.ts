import type { NextFunction, Request, Response } from 'express';

import { AppError } from '../lib/errors';
import { verifyToken } from '../lib/tokens';

export interface AuthenticatedRequest extends Request {
  auth?: { userId: string; role: string };
}

export function requireAuth(req: AuthenticatedRequest, _res: Response, next: NextFunction) {
  const authorization = req.header('authorization');
  if (!authorization?.startsWith('Bearer ')) {
    return next(new AppError(401, 'Authentification requise.'));
  }

  try {
    const token = authorization.substring('Bearer '.length);
    const payload = verifyToken(token, 'access');
    req.auth = { userId: payload.sub, role: payload.role };
    return next();
  } catch {
    return next(new AppError(401, 'Session expirée ou invalide.'));
  }
}

export function requireRole(role: 'vendor') {
  return (req: AuthenticatedRequest, _res: Response, next: NextFunction) => {
    if (req.auth?.role !== role) {
      return next(new AppError(403, 'Cette action est réservée aux vendeurs.'));
    }
    return next();
  };
}
