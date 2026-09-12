import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shophub/data/models/product.dart';
import 'package:shophub/data/models/vendor_order.dart';
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

  test('filteredProductsProvider exclut les produits masqués', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

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

  test('vendorOrdersProvider fait avancer une commande', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final order = container
        .read(vendorOrdersByVendorProvider('v1'))
        .firstWhere((item) => item.status == VendorOrderStatus.pending);

    container.read(vendorOrdersProvider.notifier).advance(order.id);

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
