import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item.dart';
import '../data/models/product.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void add(Product product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product)];
    } else {
      final updated = [...state];
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = updated;
    }
  }

  void increment(String productId) {
    state = state
        .map((i) => i.product.id == productId
            ? i.copyWith(quantity: i.quantity + 1)
            : i)
        .toList();
  }

  void decrement(String productId) {
    state = state
        .map((i) => i.product.id == productId
            ? i.copyWith(quantity: i.quantity - 1)
            : i)
        .where((i) => i.quantity > 0)
        .toList();
  }

  void remove(String productId) {
    state = state.where((i) => i.product.id != productId).toList();
  }

  void clear() => state = const [];
}

/// [PROVIDER] Panier brut
final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

/// [PROVIDER] Nombre total d'articles (badge)
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity);
});

/// [PROVIDER] Total général
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, i) => sum + i.subtotal);
});

/// [PROVIDER] Panier groupé par vendeur (marketplace)
final cartByVendorProvider = Provider<Map<String, List<CartItem>>>((ref) {
  final items = ref.watch(cartProvider);
  final grouped = <String, List<CartItem>>{};
  for (final item in items) {
    grouped.putIfAbsent(item.product.vendorId, () => []).add(item);
  }
  return grouped;
});