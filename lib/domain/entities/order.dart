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
  final String vendorName;
  final String deliveryCity;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final String paymentStatus;
  final String? paymentId;
  final int? shopReviewRating;
  final String? shopReviewComment;

  const Order({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.vendorId,
    this.vendorName = '',
    this.deliveryCity = '',
    required this.items,
    required this.total,
    required this.createdAt,
    this.status = OrderStatus.pending,
    this.paymentStatus = 'not_required',
    this.paymentId,
    this.shopReviewRating,
    this.shopReviewComment,
  });

  Order copyWith(
      {OrderStatus? status, String? paymentStatus, String? paymentId}) {
    return Order(
      id: id,
      clientId: clientId,
      clientName: clientName,
      vendorId: vendorId,
      vendorName: vendorName,
      deliveryCity: deliveryCity,
      items: items,
      total: total,
      createdAt: createdAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentId: paymentId ?? this.paymentId,
      shopReviewRating: shopReviewRating,
      shopReviewComment: shopReviewComment,
    );
  }
}
