import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations.dart';
import '../../../core/theme.dart';
import '../../../providers/filter_providers.dart';
import '../../../providers/product_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer.dart';
import '../catalog_screen.dart';
import '../product_detail/product_detail_screen.dart';
import 'sections/category_section.dart';
import 'sections/featured_carousel.dart';
import 'sections/hero_header.dart';
import 'sections/product_row.dart';
import 'sections/vendors_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: HeroHeader()),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: FeaturedCarousel(),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxxl),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 180),
                child: CategorySection(),
              ),
            ),
          ),
          _section(
            title: 'Boutiques en vedette',
            delayMs: 260,
            child: const VendorsRow(),
          ),
          _section(
            title: 'Nouveautés',
            delayMs: 340,
            onSeeAll: () => _goToCatalog(context, ref, SortOption.newest),
            child: const ProductRow(),
          ),
          _section(
            title: 'Promotions',
            delayMs: 420,
            onSeeAll: () => _goToCatalog(context, ref, SortOption.priceAsc),
            child: const ProductRow(filterOnSale: true, sortByNewest: false),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                child: SectionHeader(
                  title: 'Les plus aimés',
                  onSeeAll: () =>
                      _goToCatalog(context, ref, SortOption.ratingDesc),
                ),
              ),
            ),
          ),
          const _PopularGrid(),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required int delayMs,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: FadeSlideIn(
        delay: Duration(milliseconds: delayMs),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxxl),
              child: SectionHeader(title: title, onSeeAll: onSeeAll),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }

  void _goToCatalog(BuildContext context, WidgetRef ref, SortOption sort) {
    ref.read(filterProvider.notifier).setSort(sort);
    Navigator.push(context, SlidePageRoute(child: const CatalogScreen()));
  }
}

class _PopularGrid extends ConsumerWidget {
  const _PopularGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(productsProvider);

    return asyncProducts.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          120,
        ),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ShimmerProductCard(),
            childCount: 4,
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(child: Text('Erreur : $e')),
      ),
      data: (list) {
        final popular = list.where((p) => p.isActive).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            120,
          ),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, i) => FadeSlideIn(
                delay: Duration(milliseconds: 50 * (i % 6)),
                child: ProductCard(
                  product: popular[i],
                  onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      child: ProductDetailScreen(productId: popular[i].id),
                    ),
                  ),
                ),
              ),
              childCount: popular.length,
            ),
          ),
        );
      },
    );
  }

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: AppSpacing.md,
    childAspectRatio: 0.72,
  );
}
