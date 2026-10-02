import { ApplicationError } from '../domain/errors';
import type { OrdersRepository } from '../domain/repositories';
import type { CartLine, DeliveryAddress } from '../domain/models';

export class OrderUseCases {
  constructor(private readonly orders: OrdersRepository) {}

  listMine(userId: string, role: 'client' | 'vendor') {
    return this.orders.listForUser(userId, role);
  }

  listNotifications(userId: string) { return this.orders.listNotifications(userId); }
  markNotificationRead(userId: string, id?: string) { return this.orders.markNotificationRead(userId, id); }
  loyaltyPoints(userId: string) { return this.orders.loyaltyPoints(userId); }

  async place(input: {
    userId: string;
    role: string;
    items: CartLine[];
    deliveryMethod: string;
    deliveryFee: number;
    address: DeliveryAddress;
  }) {
    if (input.role !== 'client') {
      throw new ApplicationError('FORBIDDEN', 'Seuls les clients peuvent créer une commande.');
    }
    if (!input.items.length) throw new ApplicationError('VALIDATION', 'Le panier ne peut pas être vide.');

    const quantities = new Map<string, number>();
    for (const item of input.items) {
      if (!item.productId || !Number.isInteger(item.quantity) || item.quantity < 1) {
        throw new ApplicationError('VALIDATION', 'Chaque article doit avoir un produit et une quantité valide.');
      }
      quantities.set(item.productId, (quantities.get(item.productId) ?? 0) + item.quantity);
    }

    const address = input.address;
    if (![address.fullName, address.phone, address.street, address.city, address.country].every((part) => part.trim())) {
      throw new ApplicationError('VALIDATION', 'Adresse de livraison incomplète.');
    }

    return this.orders.placeOrder({
      clientId: input.userId,
      items: [...quantities].map(([productId, quantity]) => ({ productId, quantity })),
      deliveryMethod: input.deliveryMethod || 'standard',
      deliveryFee: Math.max(0, input.deliveryFee || 0),
      address,
    });
  }

  async changeStatus(input: {
    userId: string;
    role: string;
    orderId: string;
    status: string;
  }) {
    if (input.role !== 'vendor') {
      throw new ApplicationError('FORBIDDEN', 'Cette action est réservée aux vendeurs.');
    }
    const allowed = ['pending', 'confirmed', 'shipped', 'delivered'];
    if (!allowed.includes(input.status)) throw new ApplicationError('VALIDATION', 'Statut de commande invalide.');
    return this.orders.updateVendorOrderStatus({
      orderId: input.orderId,
      vendorUserId: input.userId,
      status: input.status as 'pending' | 'confirmed' | 'shipped' | 'delivered',
    });
  }
}
