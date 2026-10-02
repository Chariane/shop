enum VendorOrderStatus {
  pending,
  confirmed,
  shipped,
  delivered;

  String get label => switch (this) {
        VendorOrderStatus.pending => 'En attente',
        VendorOrderStatus.confirmed => 'Confirmée',
        VendorOrderStatus.shipped => 'Expédiée',
        VendorOrderStatus.delivered => 'Livrée',
      };
}

class VendorOrder {
  final String id;
  final String vendorId;
  final String clientName;
  final String productName;
  final int quantity;
  final double total;
  final String deliveryCity;
  final DateTime createdAt;
  final VendorOrderStatus status;

  const VendorOrder({
    required this.id,
    required this.vendorId,
    required this.clientName,
    required this.productName,
    required this.quantity,
    required this.total,
    required this.deliveryCity,
    required this.createdAt,
    required this.status,
  });

  VendorOrder copyWith({VendorOrderStatus? status}) {
    return VendorOrder(
      id: id,
      vendorId: vendorId,
      clientName: clientName,
      productName: productName,
      quantity: quantity,
      total: total,
      deliveryCity: deliveryCity,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}
