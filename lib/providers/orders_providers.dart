import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import '../domain/entities/order.dart';

final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) {
  return ref.watch(ordersUseCasesProvider).getMyOrders();
});
