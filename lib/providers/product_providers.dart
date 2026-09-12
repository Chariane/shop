import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/marketplace_api.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

final marketplaceApiProvider = Provider<MarketplaceApi>((ref) {
  return MarketplaceApi();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(marketplaceApiProvider));
});

class ProductCatalogNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductRepository _repository;

  ProductCatalogNotifier(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _repository.getAll());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  List<Product> get _items => state.valueOrNull ?? const [];

  void addProduct(Product product) {
    state = AsyncData([product, ..._items]);
  }

  void updateProduct(Product product) {
    state = AsyncData([
      for (final item in _items)
        if (item.id == product.id) product else item,
    ]);
  }

  void updateStock(String productId, int stock) {
    state = AsyncData([
      for (final item in _items)
        if (item.id == productId) item.copyWith(stock: stock) else item,
    ]);
  }

  void toggleProductVisibility(String productId) {
    state = AsyncData([
      for (final item in _items)
        if (item.id == productId)
          item.copyWith(isActive: !item.isActive)
        else
          item,
    ]);
  }

  void renameVendorProducts({
    required String vendorId,
    required String vendorName,
  }) {
    state = AsyncData([
      for (final item in _items)
        if (item.vendorId == vendorId)
          item.copyWith(vendorName: vendorName)
        else
          item,
    ]);
  }
}

final productsProvider =
    StateNotifierProvider<ProductCatalogNotifier, AsyncValue<List<Product>>>(
  (ref) {
    return ProductCatalogNotifier(ref.watch(productRepositoryProvider));
  },
);

final productDetailProvider =
    Provider.family<AsyncValue<Product>, String>((ref, id) {
  final products = ref.watch(productsProvider);
  return products.whenData(
    (list) => list.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Produit introuvable : $id'),
    ),
  );
});

final categoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsProvider);
  return products.maybeWhen(
    data: (list) {
      final categories = {for (final p in list) p.category};
      return ['Tous', ...categories];
    },
    orElse: () => const ['Tous'],
  );
});

final vendorProductsProvider =
    Provider.family<AsyncValue<List<Product>>, String>((ref, vendorId) {
  final products = ref.watch(productsProvider);
  return products.whenData(
    (list) => list.where((p) => p.vendorId == vendorId && p.isActive).toList(),
  );
});
