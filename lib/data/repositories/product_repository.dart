import '../datasources/marketplace_api.dart';
import '../models/product.dart';

class ProductRepository {
  final MarketplaceApi _api;

  const ProductRepository(this._api);

  Future<List<Product>> getAll() => _api.fetchProducts();
}
