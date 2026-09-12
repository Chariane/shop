import '../models/app_user.dart';
import '../models/product.dart';
import 'mocks/products_mock.dart';
import 'mocks/vendors_mock.dart';

/// Fake API — simule un backend. À remplacer par Firebase/Supabase en prod.
class MarketplaceApi {
  Future<List<AppUser>> fetchVendors() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return VendorsMock.all;
  }

  Future<List<Product>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return ProductsMock.generate();
  }
}