import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/marketplace_api.dart';
import '../data/models/product.dart';
import '../data/repositories/product_repository.dart';

/// ==========================================================
/// INJECTION DE DÉPENDANCES
/// ==========================================================
final marketplaceApiProvider = Provider<MarketplaceApi>((ref) {
  return MarketplaceApi();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(marketplaceApiProvider));
});

/// ==========================================================
/// [PROVIDER] Liste complète des produits
/// ==========================================================
final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productRepositoryProvider).getAll();
});

/// ==========================================================
/// [PROVIDER] Détail d'un produit
/// ==========================================================
final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final products = await ref.watch(productsProvider.future);
  return products.firstWhere(
    (p) => p.id == id,
    orElse: () => throw StateError('Produit introuvable : $id'),
  );
});

/// ==========================================================
/// [PROVIDER] Catégories dérivées
/// ==========================================================
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

/// ==========================================================
/// [PROVIDER] Produits d'un vendeur donné (async, paramétré)
/// ==========================================================
final vendorProductsProvider =
    Provider.family<AsyncValue<List<Product>>, String>((ref, vendorId) {
  final products = ref.watch(productsProvider);
  return products.whenData(
    (list) => list.where((p) => p.vendorId == vendorId).toList(),
  );
});