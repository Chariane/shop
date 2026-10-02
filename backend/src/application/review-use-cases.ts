import { ApplicationError } from '../domain/errors';
import type { ShopReviewRepository } from '../domain/repositories';

export class ReviewUseCases {
  constructor(private readonly reviews: ShopReviewRepository) {}

  rateOrder(input: { userId: string; role: string; orderId: string; rating: number; comment?: string }) {
    if (input.role !== 'client') {
      throw new ApplicationError('FORBIDDEN', 'Seuls les clients peuvent noter une boutique.');
    }
    if (!Number.isInteger(input.rating) || input.rating < 1 || input.rating > 5) {
      throw new ApplicationError('VALIDATION', 'La note doit être comprise entre 1 et 5 étoiles.');
    }
    const comment = input.comment?.trim() || null;
    if (comment && comment.length > 500) {
      throw new ApplicationError('VALIDATION', 'Le commentaire ne peut pas dépasser 500 caractères.');
    }
    return this.reviews.rateDeliveredOrder({
      orderId: input.orderId,
      clientId: input.userId,
      rating: input.rating,
      comment,
    });
  }

  listForVendor(vendorId: string) {
    return this.reviews.listForVendor(vendorId);
  }
}
