import { z, ZodError, type ZodType } from 'zod';

import { ApplicationError } from '../../domain/errors';

export function parseInput<T>(schema: ZodType<T>, value: unknown): T {
  const result = schema.safeParse(value);
  if (!result.success) {
    const message = result.error.issues.map((issue) => issue.message).join(' ');
    throw new ApplicationError('VALIDATION', message || 'Données invalides.');
  }
  return result.data;
}

export { z, ZodError };
