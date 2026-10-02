import crypto from 'node:crypto';
import jwt from 'jsonwebtoken';

import { env } from '../config/env';

type TokenType = 'access' | 'refresh';

export interface JwtPayload {
  sub: string;
  role: string;
  tokenType: TokenType;
}

export function signAccessToken(userId: string, role: string): string {
  return jwt.sign(
    { role, tokenType: 'access' },
    env.accessSecret,
    { subject: userId, expiresIn: env.accessExpiresIn as jwt.SignOptions['expiresIn'] },
  );
}

export function signRefreshToken(userId: string, role: string): string {
  return jwt.sign(
    { role, tokenType: 'refresh' },
    env.refreshSecret,
    { subject: userId, expiresIn: env.refreshExpiresIn as jwt.SignOptions['expiresIn'] },
  );
}

export function verifyToken(token: string, type: TokenType): JwtPayload {
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

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function refreshTokenExpiry(): Date {
  const duration = env.refreshExpiresIn;
  const match = /^(\d+)([dhm])$/.exec(duration);
  if (!match) return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  const amount = Number(match[1]);
  const factor = match[2] === 'd' ? 86400000 : match[2] === 'h' ? 3600000 : 60000;
  return new Date(Date.now() + amount * factor);
}
