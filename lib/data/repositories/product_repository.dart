import '../../domain/repositories/catalog_repository.dart';
import '../datasources/marketplace_api.dart';
import 'package:shophub/domain/entities/app_user.dart';
import 'package:shophub/domain/entities/product.dart';

class ProductRepository implements CatalogRepository {
  final MarketplaceApi _api;

  const ProductRepository(this._api);

  @override
  Future<List<Product>> getAll() => _api.fetchProducts();

  @override
  Future<List<AppUser>> getVendors() => _api.fetchVendors();

  @override
  Future<Product> saveProduct(Product product, {required bool isNew}) =>
      _api.saveProduct(product, isNew: isNew);
}
