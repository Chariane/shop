import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/vendor_order.dart';

class VendorOrdersNotifier extends StateNotifier<List<VendorOrder>> {
  VendorOrdersNotifier() : super(_initialOrders);

  static final _initialOrders = [
    VendorOrder(
      id: '#SH-1284',
      vendorId: 'v1',
      clientName: 'Alex Martin',
      productName: 'Casque Audio Pro X2',
      quantity: 1,
      total: 179.99,
      deliveryCity: 'Cotonou',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: VendorOrderStatus.pending,
    ),
    VendorOrder(
      id: '#SH-1271',
      vendorId: 'v1',
      clientName: 'Maya Lawson',
      productName: 'Montre Connectée Aura',
      quantity: 2,
      total: 598,
      deliveryCity: 'Porto-Novo',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: VendorOrderStatus.confirmed,
    ),
    VendorOrder(
      id: '#SH-1268',
      vendorId: 'v2',
      clientName: 'Chris Mensah',
      productName: 'Sneakers Urban White',
      quantity: 1,
      total: 119,
      deliveryCity: 'Abomey-Calavi',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: VendorOrderStatus.shipped,
    ),
    VendorOrder(
      id: '#SH-1262',
      vendorId: 'v3',
      clientName: 'Nora Hounsou',
      productName: 'Lampe Nordique',
      quantity: 1,
      total: 79.90,
      deliveryCity: 'Cotonou',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      status: VendorOrderStatus.delivered,
    ),
  ];

  void updateStatus(String orderId, VendorOrderStatus status) {
    state = [
      for (final order in state)
        if (order.id == orderId) order.copyWith(status: status) else order,
    ];
  }

  void advance(String orderId) {
    final order = state.firstWhere((item) => item.id == orderId);
    final next = switch (order.status) {
      VendorOrderStatus.pending => VendorOrderStatus.confirmed,
      VendorOrderStatus.confirmed => VendorOrderStatus.shipped,
      VendorOrderStatus.shipped => VendorOrderStatus.delivered,
      VendorOrderStatus.delivered => VendorOrderStatus.delivered,
    };
    updateStatus(orderId, next);
  }
}

final vendorOrdersProvider =
    StateNotifierProvider<VendorOrdersNotifier, List<VendorOrder>>((ref) {
  return VendorOrdersNotifier();
});

final vendorOrdersByVendorProvider = Provider.family<List<VendorOrder>, String>(
  (ref, vendorId) {
    return ref
        .watch(vendorOrdersProvider)
        .where((order) => order.vendorId == vendorId)
        .toList();
  },
);
