import type { NextFunction, Request, Response } from 'express';

import { ApplicationError } from '../../domain/errors';
import type { JwtTokenService } from '../../infrastructure/security/security-services';

export interface AuthenticatedRequest extends Request {
  auth?: { userId: string; role: string };
}

export function createAuthMiddleware(tokens: JwtTokenService) {
  const requireAuth = (request: AuthenticatedRequest, _response: Response, next: NextFunction) => {
    const authorization = request.header('authorization');
    if (!authorization?.startsWith('Bearer ')) {
      return next(new ApplicationError('UNAUTHORIZED', 'Authentification requise.'));
    }

    try {
      request.auth = tokens.verifyAccessToken(authorization.slice('Bearer '.length));
      return next();
    } catch {
      return next(new ApplicationError('UNAUTHORIZED', 'Session expirée ou invalide.'));
    }
  };

  const requireRole = (role: 'vendor') =>
    (request: AuthenticatedRequest, _response: Response, next: NextFunction) => {
      if (request.auth?.role !== role) {
        return next(new ApplicationError('FORBIDDEN', 'Cette action est réservée aux vendeurs.'));
      }
      next();
    };

  return { requireAuth, requireRole };
}
