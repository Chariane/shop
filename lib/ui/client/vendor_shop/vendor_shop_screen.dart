import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations.dart';
import '../../../core/theme.dart';
import '../../../providers/product_providers.dart';
import '../../../providers/user_providers.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer.dart';
import '../product_detail/product_detail_screen.dart';
import 'sections/shop_about.dart';
import 'sections/shop_app_bar.dart';
import 'sections/shop_info_card.dart';
import 'sections/shop_stats.dart';

class VendorShopScreen extends ConsumerWidget {
  final String vendorId;
  const VendorShopScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVendor = ref.watch(vendorByIdProvider(vendorId));
    final asyncProducts = ref.watch(vendorProductsProvider(vendorId));

    return Scaffold(
      body: asyncVendor.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (vendor) => CustomScrollView(
          slivers: [
            ShopAppBar(vendor: vendor),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: ShopInfoCard(vendor: vendor),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: ShopStats(vendor: vendor),
              ),
            ),
            if (vendor.shopDescription != null)
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: ShopAbout(
                    description: vendor.shopDescription!,
                    categories: vendor.shopCategories,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Produits',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '(${vendor.shopProductCount})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            asyncProducts.when(
              loading: () => _grid(const [
                ShimmerProductCard(),
                ShimmerProductCard(),
                ShimmerProductCard(),
                ShimmerProductCard(),
              ]),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Erreur : $e')),
              ),
              data: (products) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  100,
                ),
                sliver: SliverGrid(
                  gridDelegate: _delegate,
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => FadeSlideIn(
                      delay: Duration(milliseconds: 60 * i),
                      child: ProductCard(
                        product: products[i],
                        onTap: () => Navigator.push(
                          context,
                          SlidePageRoute(
                            child: ProductDetailScreen(
                              productId: products[i].id,
                            ),
                          ),
                        ),
                      ),
                    ),
                    childCount: products.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _delegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: AppSpacing.md,
    crossAxisSpacing: AppSpacing.md,
    childAspectRatio: 0.72,
  );

  Widget _grid(List<Widget> children) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        100,
      ),
      sliver: SliverGrid(
        gridDelegate: _delegate,
        delegate: SliverChildListDelegate(children),
      ),
    );
  }
}
