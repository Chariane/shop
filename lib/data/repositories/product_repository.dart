import '../datasources/marketplace_api.dart';
import '../models/product.dart';

/// Point d'entrée unique pour toutes les données produit.
/// Le reste de l'app ne connaît QUE cette classe.
class ProductRepository {
  final MarketplaceApi _api;

  const ProductRepository(this._api);

  Future<List<Product>> getAll() => _api.fetchProducts();
}