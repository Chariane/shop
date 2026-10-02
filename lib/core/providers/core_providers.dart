import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repositories/api_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/marketplace_api.dart';
import '../../data/repositories/api_orders_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/auth_use_cases.dart';
import '../../domain/usecases/catalog_use_cases.dart';
import '../../domain/usecases/orders_use_cases.dart';
import '../network/api_client.dart';
import '../storage/api_cache_store.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(FlutterSecureStorage()),
);

final dioProvider = Provider<Dio>(
  (ref) => ApiClient.create(ref.watch(tokenStorageProvider)),
);

final apiCacheStoreProvider =
    Provider<ApiCacheStore>((ref) => HiveApiCacheStore());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ApiAuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final marketplaceApiProvider = Provider<MarketplaceApi>((ref) {
  return MarketplaceApi(
      ref.watch(dioProvider), ref.watch(apiCacheStoreProvider),);
});

final catalogRepositoryProvider = Provider<CatalogRepository>(
    (ref) => ProductRepository(ref.watch(marketplaceApiProvider)),);
final catalogUseCasesProvider = Provider<CatalogUseCases>(
    (ref) => CatalogUseCases(ref.watch(catalogRepositoryProvider)),);
final ordersRepositoryProvider = Provider<OrdersRepository>(
    (ref) => ApiOrdersRepository(ref.watch(dioProvider)),);
final ordersUseCasesProvider = Provider<OrdersUseCases>(
    (ref) => OrdersUseCases(ref.watch(ordersRepositoryProvider)),);
final authUseCasesProvider = Provider<AuthUseCases>(
    (ref) => AuthUseCases(ref.watch(authRepositoryProvider)),);
