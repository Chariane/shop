import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

import { env } from '../config/environment';

type TokenType = 'access' | 'refresh';

interface JwtPayload {
  sub: string;
  role: string;
  tokenType: TokenType;
}

export class JwtTokenService {
  issueAccessToken(user: { id: string; role: string }): string {
    return jwt.sign(
      { role: user.role, tokenType: 'access' },
      env.accessSecret,
      { subject: user.id, jwtid: crypto.randomUUID(), expiresIn: env.accessExpiresIn as jwt.SignOptions['expiresIn'] },
    );
  }

  issueRefreshToken(user: { id: string; role: string }): string {
    return jwt.sign(
      { role: user.role, tokenType: 'refresh' },
      env.refreshSecret,
      { subject: user.id, jwtid: crypto.randomUUID(), expiresIn: env.refreshExpiresIn as jwt.SignOptions['expiresIn'] },
    );
  }

  verifyAccessToken(token: string): { userId: string; role: string } {
    const payload = this.verify(token, 'access');
    return { userId: payload.sub, role: payload.role };
  }

  verifyRefreshToken(token: string): { userId: string; role: string } {
    const payload = this.verify(token, 'refresh');
    return { userId: payload.sub, role: payload.role };
  }

  hash(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  expiresAt(): Date {
    const match = /^(\d+)([dhm])$/.exec(env.refreshExpiresIn);
    if (!match) return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const factor = match[2] === 'd' ? 86400000 : match[2] === 'h' ? 3600000 : 60000;
    return new Date(Date.now() + Number(match[1]) * factor);
  }

  private verify(token: string, type: TokenType): JwtPayload {
    const secret = type === 'access' ? env.accessSecret : env.refreshSecret;
    const decoded = jwt.verify(token, secret) as jwt.JwtPayload & {
      role?: string;
      tokenType?: TokenType;
    };
    if (!decoded.sub || !decoded.role || decoded.tokenType !== type) {
      throw new Error('Jeton invalide.');
    }
    return { sub: decoded.sub, role: decoded.role, tokenType: decoded.tokenType };
  }
}
