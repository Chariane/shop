import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/filter_providers.dart';
import '../../providers/product_providers.dart';
import '../widgets/product_card.dart';
import 'product_detail/product_detail_screen.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(filteredProductsProvider);
    final filter = ref.watch(filterProvider);
    final categories = ref.watch(categoriesProvider);

    // Le Scaffold est indispensable quand on arrive via Navigator.push.
    // On l'ajoute toujours : en tant qu'onglet dans ClientShell, il
    // devient transparent et laisse voir le fond du shell.
    return Scaffold(
      backgroundColor: context.background,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              title: const Text('Boutique'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        top: !Navigator.of(context).canPop(),
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ---------- TITRE (masqué si AppBar est affichée) ----------
            if (!Navigator.of(context).canPop())
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'Boutique',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),

            // ---------- RECHERCHE ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: TextField(
                  onChanged: (v) =>
                      ref.read(filterProvider.notifier).setQuery(v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un produit, une boutique...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.textMuted,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ---------- CHIPS CATÉGORIES ----------
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final selected = cat == filter.category;
                    return GestureDetector(
                      onTap: () => ref
                          .read(filterProvider.notifier)
                          .setCategory(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected ? AppColors.gradient : null,
                          color: selected ? null : context.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          boxShadow: selected
                              ? context.coloredShadow(AppColors.primary)
                              : context.softShadow,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : context.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ---------- COMPTEUR + TRI ----------
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      asyncProducts.maybeWhen(
                        data: (l) => '${l.length} produit(s)',
                        orElse: () => 'Chargement...',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    _SortButton(current: filter.sort),
                  ],
                ),
              ),
            ),

            // ---------- GRILLE ----------
            asyncProducts.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Erreur : $e')),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: context.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Aucun produit trouvé',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    100,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => ProductCard(
                        product: products[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productId: products[i].id,
                            ),
                          ),
                        ),
                      ),
                      childCount: products.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends ConsumerWidget {
  final SortOption current;
  const _SortButton({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<SortOption>(
      initialValue: current,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (s) => ref.read(filterProvider.notifier).setSort(s),
      itemBuilder: (_) => SortOption.values
          .map(
            (opt) => PopupMenuItem(
              value: opt,
              child: Text(opt.label),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: context.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: context.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              'Trier',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}