import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shophub/domain/entities/product.dart';
import 'package:shophub/domain/entities/order.dart';
import 'package:shophub/domain/entities/checkout_payment.dart';
import 'package:shophub/domain/entities/app_user.dart';
import 'package:shophub/domain/entities/cart_item.dart';
import 'package:shophub/domain/entities/delivery_option.dart';
import 'package:shophub/domain/repositories/catalog_repository.dart';
import 'package:shophub/domain/repositories/orders_repository.dart';
import 'package:shophub/domain/usecases/catalog_use_cases.dart';
import 'package:shophub/domain/usecases/orders_use_cases.dart';
import 'package:shophub/core/providers/core_providers.dart';
import 'package:shophub/domain/entities/vendor_order.dart';
import 'package:shophub/providers/cart_providers.dart';
import 'package:shophub/providers/favorites_providers.dart';
import 'package:shophub/providers/filter_providers.dart';
import 'package:shophub/providers/product_providers.dart';
import 'package:shophub/providers/vendor_order_providers.dart';

void main() {
  Product product({
    String id = 'p-test',
    String name = 'Produit test',
    double price = 25,
    String category = 'Tech',
    bool isActive = true,
  }) {
    return Product(
      id: id,
      vendorId: 'v-test',
      vendorName: 'Boutique test',
      name: name,
      shortDescription: 'Description courte',
      longDescription: 'Description longue',
      price: price,
      imageUrl: 'https://example.com/product.jpg',
      category: category,
      isActive: isActive,
      createdAt: DateTime(2026),
    );
  }

  test('cartProvider regroupe les quantités et calcule le total', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final item = product(price: 19.99);

    container.read(cartProvider.notifier).add(item);
    container.read(cartProvider.notifier).add(item);

    expect(container.read(cartCountProvider), 2);
    expect(container.read(cartTotalProvider), 39.98);
  });

  test('favoritesProvider charge et persiste les favoris locaux', () async {
    SharedPreferences.setMockInitialValues({
      'favorites_ids': ['p1'],
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _waitForFavorites(container);

    expect(container.read(isFavoriteProvider('p1')), isTrue);

    final added = await container.read(favoritesProvider.notifier).toggle('p2');

    expect(added, isTrue);
    expect(container.read(favoritesCountProvider), 2);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('favorites_ids'), ['p1', 'p2']);
  });

  test('filteredProductsProvider exclut les produits masqués', () async {
    final container = ProviderContainer(overrides: [
      catalogUseCasesProvider.overrideWithValue(
        CatalogUseCases(_EmptyCatalogRepository()),
      ),
    ]);
    addTearDown(container.dispose);
    await _waitForProducts(container);

    final notifier = container.read(productsProvider.notifier);
    final visible = product(id: 'visible', name: 'Casque visible');
    final hidden = product(
      id: 'hidden',
      name: 'Casque masqué',
      isActive: false,
    );

    notifier.addProduct(visible);
    notifier.addProduct(hidden);
    container.read(filterProvider.notifier).setQuery('Casque');

    final results = container.read(filteredProductsProvider).valueOrNull;

    expect(results?.map((item) => item.id), contains('visible'));
    expect(results?.map((item) => item.id), isNot(contains('hidden')));
  });

  test('vendorOrdersProvider fait avancer une commande', () async {
    final container = ProviderContainer(overrides: [
      ordersUseCasesProvider.overrideWithValue(
        OrdersUseCases(_TestOrdersRepository()),
      ),
    ]);
    addTearDown(container.dispose);
    await _waitForOrders(container);

    final order = container
        .read(vendorOrdersByVendorProvider('v1'))
        .firstWhere((item) => item.status == VendorOrderStatus.pending);

    await container.read(vendorOrdersProvider.notifier).advance(order.id);

    final updated = container
        .read(vendorOrdersProvider)
        .firstWhere((item) => item.id == order.id);

    expect(updated.status, VendorOrderStatus.confirmed);
  });
}

Future<void> _waitForFavorites(ProviderContainer container) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    if (container.read(favoritesProvider).hasValue) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> _waitForProducts(ProviderContainer container) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    if (container.read(productsProvider).hasValue) return;
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitForOrders(ProviderContainer container) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    if (container.read(vendorOrdersProvider).isNotEmpty) return;
    await Future<void>.delayed(Duration.zero);
  }
}

class _EmptyCatalogRepository implements CatalogRepository {
  @override
  Future<List<Product>> getAll() async => [];

  @override
  Future<List<AppUser>> getVendors() async => [];

  @override
  Future<Product> saveProduct(Product product, {required bool isNew}) async =>
      product;
}

class _TestOrdersRepository implements OrdersRepository {
  var _order = Order(
    id: 'order-test',
    clientId: 'client-test',
    clientName: 'Client test',
    vendorId: 'v1',
    items: [
      CartItem(
        product: Product(
          id: 'p-order',
          vendorId: 'v1',
          vendorName: 'Boutique test',
          name: 'Produit test',
          shortDescription: '',
          longDescription: '',
          price: 10,
          imageUrl: 'https://example.com/product.jpg',
          category: 'Tech',
          createdAt: DateTime(2026),
        ),
      ),
    ],
    total: 10,
    createdAt: DateTime(2026),
  );

  @override
  Future<List<Order>> getMyOrders() async => [_order];

  @override
  Future<Order> updateVendorOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    _order = _order.copyWith(status: status);
    return _order;
  }

  @override
  Future<void> submitShopReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {}

  @override
  Future<CheckoutPayment> startCheckout(
          {required List<CartItem> items,
          required DeliveryAddress address,
          required DeliveryOption delivery,
          required String customerEmail}) async =>
      throw UnimplementedError();

  @override
  Future<CheckoutPaymentStatus> refreshPayment(String paymentId) async =>
      const CheckoutPaymentStatus(status: 'pending', amountXof: 0);

  @override
  Future<List<Order>> createOrder({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
  }) async =>
      [];
}
