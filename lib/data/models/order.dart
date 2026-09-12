import 'cart_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered;

  String get label => switch (this) {
        OrderStatus.pending => 'En attente',
        OrderStatus.confirmed => 'Confirmée',
        OrderStatus.shipped => 'Expédiée',
        OrderStatus.delivered => 'Livrée',
      };
}

class Order {
  final String id;
  final String clientId;
  final String clientName;
  final String vendorId;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.vendorId,
    required this.items,
    required this.total,
    required this.createdAt,
    this.status = OrderStatus.pending,
  });

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      clientId: clientId,
      clientName: clientName,
      vendorId: vendorId,
      items: items,
      total: total,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
