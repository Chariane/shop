import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/core_providers.dart';
import 'package:shophub/domain/entities/product.dart';
import '../domain/usecases/catalog_use_cases.dart';

class ProductCatalogNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final CatalogUseCases _useCases;

  ProductCatalogNotifier(this._useCases) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _useCases.getProducts());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  List<Product> get _items => state.valueOrNull ?? const [];

  Future<Product> saveProduct(Product product, {required bool isNew}) async {
    final saved = await _useCases.saveProduct(product, isNew: isNew);
    state = AsyncData([
      saved,
      ..._items.where((item) => item.id != saved.id),
    ]);
    return saved;
  }

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
    return ProductCatalogNotifier(ref.watch(catalogUseCasesProvider));
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
