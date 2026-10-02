import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shophub/domain/entities/order.dart';
import 'package:shophub/domain/entities/vendor_order.dart';
import '../core/providers/core_providers.dart';
import '../domain/usecases/orders_use_cases.dart';

class VendorOrdersNotifier extends StateNotifier<List<VendorOrder>> {
  final OrdersUseCases _ordersUseCases;

  VendorOrdersNotifier(this._ordersUseCases) : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await _ordersUseCases.getMyOrders();
      state = orders.map(_toVendorOrder).toList();
    } catch (_) {
      state = const [];
    }
  }

  Future<void> updateStatus(String orderId, VendorOrderStatus status) async {
    final order = await _ordersUseCases.updateVendorOrderStatus(
      orderId: orderId,
      status: OrderStatus.values.byName(status.name),
    );
    state = [
      for (final item in state)
        if (item.id == orderId) _toVendorOrder(order) else item,
    ];
  }

  Future<void> advance(String orderId) async {
    final order = state.firstWhere((item) => item.id == orderId);
    final next = switch (order.status) {
      VendorOrderStatus.pending => VendorOrderStatus.confirmed,
      VendorOrderStatus.confirmed => VendorOrderStatus.shipped,
      VendorOrderStatus.shipped => VendorOrderStatus.delivered,
      VendorOrderStatus.delivered => VendorOrderStatus.delivered,
    };
    await updateStatus(orderId, next);
  }

  VendorOrder _toVendorOrder(Order order) {
    final names = order.items
        .map((item) => item.product.name)
        .where((name) => name.isNotEmpty);
    final quantity =
        order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    return VendorOrder(
      id: order.id,
      vendorId: order.vendorId,
      clientName: order.clientName,
      productName: names.isEmpty ? 'Commande' : names.first,
      quantity: quantity,
      total: order.total,
      deliveryCity: order.deliveryCity,
      createdAt: order.createdAt,
      status: VendorOrderStatus.values.byName(order.status.name),
    );
  }
}

final vendorOrdersProvider =
    StateNotifierProvider<VendorOrdersNotifier, List<VendorOrder>>((ref) {
  return VendorOrdersNotifier(ref.watch(ordersUseCasesProvider));
});

final vendorOrdersByVendorProvider =
    Provider.family<List<VendorOrder>, String>((ref, vendorId) {
  return ref
      .watch(vendorOrdersProvider)
      .where((order) => order.vendorId == vendorId)
      .toList();
});
