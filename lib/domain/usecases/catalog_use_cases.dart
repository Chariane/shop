import '../entities/app_user.dart';
import '../entities/product.dart';
import '../repositories/catalog_repository.dart';

class CatalogUseCases {
  final CatalogRepository _repository;

  const CatalogUseCases(this._repository);

  Future<List<Product>> getProducts() => _repository.getAll();

  Future<List<AppUser>> getVendors() => _repository.getVendors();

  Future<Product> saveProduct(Product product, {required bool isNew}) {
    if (product.name.trim().isEmpty ||
        product.price <= 0 ||
        product.imageUrl.trim().isEmpty) {
      throw ArgumentError('Nom, prix et image valides requis.');
    }
    return _repository.saveProduct(product, isNew: isNew);
  }
}
