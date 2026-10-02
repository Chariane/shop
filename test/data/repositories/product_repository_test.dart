import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shophub/core/storage/api_cache_store.dart';
import 'package:shophub/data/datasources/marketplace_api.dart';
import 'package:shophub/domain/entities/product.dart';
import 'package:shophub/data/repositories/product_repository.dart';

class _FakeCache implements ApiCacheStore {
  @override
  Future<List<Map<String, dynamic>>?> readList(String key) async => null;

  @override
  Future<void> writeList(String key, List<Map<String, dynamic>> value) async {}

  @override
  Future<Map<String, dynamic>?> readObject(String key) async => null;

  @override
  Future<void> writeObject(String key, Map<String, dynamic> value) async {}
}

class _FakeMarketplaceApi extends MarketplaceApi {
  final Future<List<Product>> Function() response;

  _FakeMarketplaceApi(this.response) : super(Dio(), _FakeCache());

  @override
  Future<List<Product>> fetchProducts() => response();
}

Product _product(String id) => Product(
      id: id,
      vendorId: 'vendor-1',
      vendorName: 'Boutique test',
      name: 'Article test',
      shortDescription: 'Description',
      longDescription: 'Description complète',
      price: 10,
      imageUrl: 'https://example.com/item.png',
      category: 'Maison',
      createdAt: DateTime(2026),
    );

void main() {
  test('getAll transmet les produits renvoyés par la source API', () async {
    final expected = [_product('p1'), _product('p2')];
    final repository =
        ProductRepository(_FakeMarketplaceApi(() async => expected));

    expect(await repository.getAll(), expected);
  });

  test('getAll retourne une liste vide quand le catalogue est vide', () async {
    final repository = ProductRepository(_FakeMarketplaceApi(() async => []));

    expect(await repository.getAll(), isEmpty);
  });

  test('getAll transmet les erreurs réseau au consommateur', () async {
    final failure = StateError('API indisponible');
    final repository = ProductRepository(
      _FakeMarketplaceApi(() async => throw failure),
    );

    await expectLater(repository.getAll(), throwsA(same(failure)));
  });
}
