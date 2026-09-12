import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/product.dart';
import '../../../../providers/product_providers.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/shimmer.dart';
import '../../product_detail/product_detail_screen.dart';

class ProductRow extends ConsumerWidget {
  final bool filterOnSale;
  final bool sortByNewest;

  const ProductRow({
    super.key,
    this.filterOnSale = false,
    this.sortByNewest = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider);

    return SizedBox(
      height: 220,
      child: asyncProducts.when(
        loading: () => _skeletons(context),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) {
          var sorted = [...list];
          if (filterOnSale) {
            sorted = sorted.where((p) => p.isOnSale).toList();
          } else if (sortByNewest) {
            sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }

          if (sorted.isEmpty) {
            return Center(
              child: Text(
                'Aucun produit',
                style: TextStyle(color: context.textMuted),
              ),
            );
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: sorted.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => SizedBox(
              width: 150,
              child: ProductCard(
                product: sorted[i],
                onTap: () => _open(context, sorted[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _skeletons(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, __) =>
          const SizedBox(width: 150, child: ShimmerProductCard()),
    );
  }

  void _open(BuildContext context, Product p) {
    Navigator.push(
      context,
      SlidePageRoute(child: ProductDetailScreen(productId: p.id)),
    );
  }
}