import 'package:shophub/domain/entities/app_user.dart';
import 'package:shophub/domain/entities/product.dart';

abstract class CatalogRepository {
  Future<List<Product>> getAll();
  Future<List<AppUser>> getVendors();
  Future<Product> saveProduct(Product product, {required bool isNew});
}
