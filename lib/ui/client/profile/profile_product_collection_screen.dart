import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/animations.dart';
import '../../../core/theme.dart';
import '../../../providers/favorites_providers.dart';
import '../../../providers/product_providers.dart';
import '../../widgets/product_card.dart';
import '../product_detail/product_detail_screen.dart';

enum ProfileProductCollection {
  favorites,
  promotions;

  String get title => switch (this) {
        ProfileProductCollection.favorites => 'Mes favoris',
        ProfileProductCollection.promotions => 'Promotions',
      };

  String get emptyLabel => switch (this) {
        ProfileProductCollection.favorites => 'Aucun favori pour le moment',
        ProfileProductCollection.promotions => 'Aucune promotion disponible',
      };

  IconData get emptyIcon => switch (this) {
        ProfileProductCollection.favorites => Icons.favorite_border_rounded,
        ProfileProductCollection.promotions => Icons.local_offer_outlined,
      };
}

class ProfileProductCollectionScreen extends ConsumerWidget {
  final ProfileProductCollection collection;

  const ProfileProductCollectionScreen({
    super.key,
    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider);
    final favoriteIds = ref.watch(favoritesProvider).valueOrNull ?? const {};

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(title: Text(collection.title)),
      body: asyncProducts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (products) {
          final visibleProducts = switch (collection) {
            ProfileProductCollection.favorites => products
                .where((p) => p.isActive && favoriteIds.contains(p.id))
                .toList(),
            ProfileProductCollection.promotions =>
              products.where((p) => p.isActive && p.isOnSale).toList(),
          };

          if (visibleProducts.isEmpty) {
            return _EmptyCollection(collection: collection);
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              120,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.68,
            ),
            itemCount: visibleProducts.length,
            itemBuilder: (context, index) {
              final product = visibleProducts[index];

              return ProductCard(
                product: product,
                onTap: () => Navigator.push(
                  context,
                  SlidePageRoute(
                    child: ProductDetailScreen(productId: product.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  final ProfileProductCollection collection;

  const _EmptyCollection({required this.collection});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              collection.emptyIcon,
              size: 74,
              color: context.textMuted.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              collection.emptyLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Les produits apparaîtront ici automatiquement.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
