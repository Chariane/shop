import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations.dart';
import '../../../core/theme.dart';
import '../../../providers/favorites_providers.dart';
import '../../../providers/product_providers.dart';
import 'sections/product_gallery.dart';
import 'sections/product_info.dart';
import 'sections/product_specs.dart';
import 'sections/product_vendor_card.dart';
import 'widgets/detail_bottom_bar.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(productDetailProvider(productId));

    return Scaffold(
      body: asyncDetail.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (product) => _DetailView(product: product),
      ),
      bottomNavigationBar: asyncDetail.maybeWhen(
        data: (product) => DetailBottomBar(product: product),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _DetailView extends ConsumerWidget {
  final dynamic product;
  const _DetailView({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(product.id));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          backgroundColor: context.surface,
          leading: _circleButton(
            context,
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          actions: [
            _circleButton(
              context,
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color:
                  isFavorite ? AppColors.accent : context.onSurface,
              onTap: () => ref
                  .read(favoritesProvider.notifier)
                  .toggle(product.id),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: ProductGallery(images: product.allImages),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            transform: Matrix4.translationValues(0, -28, 0),
            decoration: BoxDecoration(
              color: context.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(child: ProductInfo(product: product)),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: ProductVendorCard(product: product),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          product.longDescription,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child:
                        ProductSpecs(specs: product.specifications),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        color: context.surface,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color ?? context.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}