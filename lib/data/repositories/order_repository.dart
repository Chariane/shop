import 'package:shophub/domain/entities/order.dart';

class OrderRepository {
  final List<Order> _orders = [];

  Future<List<Order>> getByVendor(String vendorId) async {
    return _orders.where((o) => o.vendorId == vendorId).toList();
  }

  Future<List<Order>> getByClient(String clientId) async {
    return _orders.where((o) => o.clientId == clientId).toList();
  }

  Future<void> save(Order order) async {
    _orders.add(order);
  }
}
