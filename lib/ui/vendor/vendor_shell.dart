import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/app_user.dart';
import '../../data/models/product.dart';
import '../../data/models/vendor_order.dart';
import '../../providers/auth_providers.dart';
import '../../providers/product_providers.dart';
import '../../providers/user_providers.dart';
import '../../providers/vendor_order_providers.dart';

class VendorShell extends ConsumerStatefulWidget {
  const VendorShell({super.key});

  @override
  ConsumerState<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends ConsumerState<VendorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(authProvider);

    if (vendor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      _VendorDashboard(
        vendor: vendor,
        onShowOrders: () => setState(() => _index = 2),
      ),
      _VendorProducts(vendor: vendor),
      _VendorOrders(vendor: vendor),
      _VendorProfile(vendor: vendor),
    ];

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: Text(vendor.shopName ?? 'Espace vendeur'),
        actions: [
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Boutique',
          ),
        ],
      ),
    );
  }
}

class _VendorDashboard extends ConsumerWidget {
  final AppUser vendor;
  final VoidCallback onShowOrders;

  const _VendorDashboard({
    required this.vendor,
    required this.onShowOrders,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final orders = ref.watch(vendorOrdersByVendorProvider(vendor.id));

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => const _VendorPage(
        children: [
          _EmptyState(message: 'Impossible de charger les produits.'),
        ],
      ),
      data: (products) {
        final vendorProducts =
            products.where((product) => product.vendorId == vendor.id).toList();
        final visibleProducts =
            vendorProducts.where((product) => product.isActive).length;
        final totalStock = vendorProducts.fold<int>(
          0,
          (total, product) => total + product.stock,
        );
        final revenue = orders.fold<double>(
          0,
          (total, order) => total + order.total,
        );
        final pendingOrders = orders
            .where((order) => order.status != VendorOrderStatus.delivered)
            .length;
        final hiddenProducts =
            vendorProducts.where((product) => !product.isActive).length;
        final lowStockProducts =
            vendorProducts.where((product) => product.stock <= 5).length;
        final deliveredOrders = orders
            .where((order) => order.status == VendorOrderStatus.delivered)
            .length;
        final deliveryRate = orders.isEmpty
            ? '0%'
            : '${((deliveredOrders / orders.length) * 100).round()}%';
        final topProduct = _topOrderedProduct(orders);

        return _VendorPage(
          children: [
            _ShopHero(vendor: vendor),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.25,
              children: [
                _MetricCard(
                  label: 'Produits visibles',
                  value: '$visibleProducts',
                  icon: Icons.visibility_rounded,
                  color: AppColors.primary,
                ),
                _MetricCard(
                  label: 'Stock total',
                  value: '$totalStock',
                  icon: Icons.warehouse_rounded,
                  color: AppColors.success,
                ),
                _MetricCard(
                  label: 'Commandes actives',
                  value: '$pendingOrders',
                  icon: Icons.local_shipping_rounded,
                  color: AppColors.warning,
                ),
                _MetricCard(
                  label: 'Chiffre estimé',
                  value: '${revenue.toStringAsFixed(0)} €',
                  icon: Icons.payments_rounded,
                  color: AppColors.accent,
                ),
              ],
            ),
            _SectionCard(
              title: 'Pilotage',
              child: Column(
                children: [
                  _InfoLine(
                    icon: Icons.trending_up_rounded,
                    label: 'Produit le plus commandé',
                    value: topProduct,
                  ),
                  _InfoLine(
                    icon: Icons.inventory_rounded,
                    label: 'Stocks à surveiller',
                    value: '$lowStockProducts produit(s)',
                  ),
                  _InfoLine(
                    icon: Icons.visibility_off_rounded,
                    label: 'Produits masqués',
                    value: '$hiddenProducts produit(s)',
                  ),
                  _InfoLine(
                    icon: Icons.verified_rounded,
                    label: 'Commandes livrées',
                    value: deliveryRate,
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Vue client',
              actionLabel: 'Modifier',
              onAction: () => _openShopForm(context, ref, vendor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.shopTagline ?? 'Ajoutez une promesse claire.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    vendor.shopDescription ??
                        'Décrivez ce que votre boutique propose aux clients.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _Pill(
                        icon: Icons.star_rounded,
                        label: vendor.shopRating.toStringAsFixed(1),
                      ),
                      _Pill(
                        icon: Icons.sell_rounded,
                        label: '${vendor.shopSales} ventes',
                      ),
                      _Pill(
                        icon: Icons.schedule_rounded,
                        label: vendor.responseTimeLabel,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _SectionCard(
              title: 'Dernières commandes',
              actionLabel: 'Voir tout',
              onAction: onShowOrders,
              child: orders.isEmpty
                  ? const _EmptyState(
                      message: 'Aucune commande pour cette boutique.',
                    )
                  : Column(
                      children: [
                        for (final order in orders.take(3))
                          _OrderMiniTile(order: order),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  String _topOrderedProduct(List<VendorOrder> orders) {
    if (orders.isEmpty) return 'Aucune commande';

    final totals = <String, int>{};
    for (final order in orders) {
      totals.update(
        order.productName,
        (quantity) => quantity + order.quantity,
        ifAbsent: () => order.quantity,
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }
}

class _VendorProducts extends ConsumerWidget {
  final AppUser vendor;

  const _VendorProducts({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => const _VendorPage(
        children: [
          _EmptyState(message: 'Impossible de charger les produits.'),
        ],
      ),
      data: (products) {
        final vendorProducts = products
            .where((product) => product.vendorId == vendor.id)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return _VendorPage(
          floatingAction: FloatingActionButton.extended(
            onPressed: () => _openProductForm(context, ref, vendor),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Produit'),
          ),
          children: [
            _SectionCard(
              title: 'Catalogue boutique',
              child: Text(
                'Ajoutez, masquez ou ajustez les stocks des produits que les clients voient.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (vendorProducts.isEmpty)
              const _EmptyState(message: 'Aucun produit ajouté pour le moment.')
            else
              for (final product in vendorProducts)
                _VendorProductTile(vendor: vendor, product: product),
          ],
        );
      },
    );
  }
}

class _VendorOrders extends ConsumerWidget {
  final AppUser vendor;

  const _VendorOrders({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(vendorOrdersByVendorProvider(vendor.id));

    return _VendorPage(
      children: [
        _SectionCard(
          title: 'Gestion des commandes',
          child: Text(
            'Suivez chaque livraison et faites avancer le statut côté boutique.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (orders.isEmpty)
          const _EmptyState(message: 'Aucune commande pour cette boutique.')
        else
          for (final order in orders) _VendorOrderTile(order: order),
      ],
    );
  }
}

class _VendorProfile extends ConsumerWidget {
  final AppUser vendor;

  const _VendorProfile({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _VendorPage(
      children: [
        _ShopHero(vendor: vendor),
        _SectionCard(
          title: 'Informations publiques',
          actionLabel: 'Modifier',
          onAction: () => _openShopForm(context, ref, vendor),
          child: Column(
            children: [
              _InfoLine(
                icon: Icons.badge_rounded,
                label: 'Nom',
                value: vendor.shopName ?? vendor.name,
              ),
              _InfoLine(
                icon: Icons.short_text_rounded,
                label: 'Accroche',
                value: vendor.shopTagline ?? 'Non renseignée',
              ),
              _InfoLine(
                icon: Icons.location_on_rounded,
                label: 'Adresse',
                value:
                    '${vendor.shopCity ?? 'Cotonou'}, ${vendor.shopCountry ?? 'Bénin'}',
              ),
              _InfoLine(
                icon: Icons.category_rounded,
                label: 'Catégories',
                value: vendor.shopCategories.isEmpty
                    ? 'Non renseignées'
                    : vendor.shopCategories.join(', '),
              ),
            ],
          ),
        ),
        _SectionCard(
          title: 'Présentation',
          child: Text(
            vendor.shopDescription ??
                'Ajoutez une présentation pour rassurer les clients.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _VendorPage extends StatelessWidget {
  final List<Widget> children;
  final Widget? floatingAction;

  const _VendorPage({required this.children, this.floatingAction});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            floatingAction == null ? 96 : 116,
          ),
          itemBuilder: (context, index) => children[index],
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
          itemCount: children.length,
        ),
        if (floatingAction != null)
          Positioned(
            right: AppSpacing.xl,
            bottom: AppSpacing.xl,
            child: floatingAction!,
          ),
      ],
    );
  }
}

class _ShopHero extends StatelessWidget {
  final AppUser vendor;

  const _ShopHero({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: context.mediumShadow,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            vendor.shopBannerUrl ??
                'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1400&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.68),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: vendor.avatarUrl == null
                          ? null
                          : NetworkImage(vendor.avatarUrl!),
                      child: vendor.avatarUrl == null
                          ? const Icon(Icons.storefront_rounded)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.shopName ?? vendor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            vendor.shopTagline ?? 'Votre vitrine ShopHub',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: context.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _VendorProductTile extends ConsumerWidget {
  final AppUser vendor;
  final Product product;

  const _VendorProductTile({required this.vendor, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor =
        product.isActive ? AppColors.success : context.textMuted;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              product.imageUrl,
              width: 86,
              height: 104,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 86,
                height: 104,
                color: AppColors.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.image_not_supported_rounded),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openProductForm(context, ref, vendor, product);
                        } else {
                          ref
                              .read(productsProvider.notifier)
                              .toggleProductVisibility(product.id);
                          _showVendorFeedback(
                            context,
                            product.isActive
                                ? 'Produit masqué côté client'
                                : 'Produit publié côté client',
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifier'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(product.isActive ? 'Masquer' : 'Publier'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  product.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${product.price.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: context.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _StatusChip(
                      label: product.isActive ? 'Visible' : 'Masqué',
                      color: statusColor,
                    ),
                    if (product.isLowStock)
                      const _StatusChip(
                        label: 'Stock bas',
                        color: AppColors.danger,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _SmallIconButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'Retirer du stock',
                      onPressed: product.stock <= 0
                          ? null
                          : () {
                              ref
                                  .read(productsProvider.notifier)
                                  .updateStock(product.id, product.stock - 1);
                              _showVendorFeedback(
                                context,
                                'Stock mis à jour',
                              );
                            },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'Stock ${product.stock}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    _SmallIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Ajouter au stock',
                      onPressed: () {
                        ref
                            .read(productsProvider.notifier)
                            .updateStock(product.id, product.stock + 1);
                        _showVendorFeedback(context, 'Stock mis à jour');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorOrderTile extends ConsumerWidget {
  final VendorOrder order;

  const _VendorOrderTile({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDelivered = order.status == VendorOrderStatus.delivered;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.id,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatusChip(
                label: order.status.label,
                color: _statusColor(order.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoLine(
            icon: Icons.person_rounded,
            label: 'Client',
            value: order.clientName,
          ),
          _InfoLine(
            icon: Icons.shopping_bag_rounded,
            label: 'Article',
            value: '${order.productName} x${order.quantity}',
          ),
          _InfoLine(
            icon: Icons.location_on_rounded,
            label: 'Livraison',
            value: order.deliveryCity,
          ),
          _InfoLine(
            icon: Icons.payments_rounded,
            label: 'Total',
            value: '${order.total.toStringAsFixed(2)} €',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showStatusMenu(context, ref, order),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Statut'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDelivered
                      ? null
                      : () {
                          ref
                              .read(vendorOrdersProvider.notifier)
                              .advance(order.id);
                          _showVendorFeedback(
                            context,
                            'Statut de commande mis à jour',
                          );
                        },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Avancer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(VendorOrderStatus status) {
    return switch (status) {
      VendorOrderStatus.pending => AppColors.warning,
      VendorOrderStatus.confirmed => AppColors.primary,
      VendorOrderStatus.shipped => AppColors.accent,
      VendorOrderStatus.delivered => AppColors.success,
    };
  }

  void _showStatusMenu(
    BuildContext context,
    WidgetRef ref,
    VendorOrder order,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final status in VendorOrderStatus.values)
                ListTile(
                  leading: Icon(
                    status == order.status
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: Text(status.label),
                  onTap: () {
                    ref
                        .read(vendorOrdersProvider.notifier)
                        .updateStatus(order.id, status);
                    Navigator.pop(sheetContext);
                    _showVendorFeedback(context, 'Statut modifié');
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderMiniTile extends StatelessWidget {
  final VendorOrder order;

  const _OrderMiniTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${order.clientName} · ${order.deliveryCity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${order.total.toStringAsFixed(0)} €',
            style: TextStyle(
              color: context.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: TextStyle(
                    color: context.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: context.textMuted, size: 34),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

Future<void> _openProductForm(
  BuildContext context,
  WidgetRef ref,
  AppUser vendor, [
  Product? product,
]) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProductFormSheet(
      vendor: vendor,
      product: product,
      onSave: (savedProduct) {
        final notifier = ref.read(productsProvider.notifier);
        if (product == null) {
          notifier.addProduct(savedProduct);
          _showVendorFeedback(context, 'Produit ajouté au catalogue');
        } else {
          notifier.updateProduct(savedProduct);
          _showVendorFeedback(context, 'Produit mis à jour');
        }
      },
    ),
  );
}

Future<void> _openShopForm(
  BuildContext context,
  WidgetRef ref,
  AppUser vendor,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ShopFormSheet(
      vendor: vendor,
      onSave: (updatedVendor) {
        ref.read(authProvider.notifier).updateShopProfile(
              shopName: updatedVendor.shopName ?? updatedVendor.name,
              shopTagline: updatedVendor.shopTagline ?? '',
              shopDescription: updatedVendor.shopDescription ?? '',
              shopBannerUrl: updatedVendor.shopBannerUrl ?? '',
              shopCity: updatedVendor.shopCity ?? '',
              shopCountry: updatedVendor.shopCountry ?? '',
              shopCategories: updatedVendor.shopCategories,
            );
        ref.read(vendorsProvider.notifier).upsertVendor(updatedVendor);
        ref.read(productsProvider.notifier).renameVendorProducts(
              vendorId: vendor.id,
              vendorName: updatedVendor.shopName ?? updatedVendor.name,
            );
        _showVendorFeedback(context, 'Profil boutique mis à jour');
      },
    ),
  );
}

void _showVendorFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1300),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      margin: const EdgeInsets.all(AppSpacing.lg),
    ),
  );
}

class _ProductFormSheet extends StatefulWidget {
  final AppUser vendor;
  final Product? product;
  final ValueChanged<Product> onSave;

  const _ProductFormSheet({
    required this.vendor,
    required this.product,
    required this.onSave,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _longDescriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageController;
  late final TextEditingController _stockController;
  late String _category;
  late bool _freeShipping;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    final categories = widget.vendor.shopCategories;
    _nameController = TextEditingController(text: product?.name ?? '');
    _shortDescriptionController = TextEditingController(
      text: product?.shortDescription ?? '',
    );
    _longDescriptionController = TextEditingController(
      text: product?.longDescription ?? '',
    );
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _imageController = TextEditingController(
      text: product?.imageUrl ??
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=900&q=80',
    );
    _stockController = TextEditingController(
      text: product == null ? '10' : product.stock.toString(),
    );
    _category = product?.category ??
        (categories.isEmpty ? 'Boutique' : categories.first);
    _freeShipping = product?.freeShipping ?? true;
    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescriptionController.dispose();
    _longDescriptionController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = {
      ...widget.vendor.shopCategories,
      _category,
      'Boutique',
      'Tech',
      'Mode',
      'Maison',
    }.toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product == null
                      ? 'Nouveau produit'
                      : 'Modifier le produit',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                _FormField(
                  controller: _nameController,
                  label: 'Nom du produit',
                  validator: _required,
                ),
                _FormField(
                  controller: _shortDescriptionController,
                  label: 'Description courte',
                  validator: _required,
                ),
                _FormField(
                  controller: _longDescriptionController,
                  label: 'Description détaillée',
                  maxLines: 4,
                  validator: _required,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: _priceController,
                        label: 'Prix',
                        keyboardType: TextInputType.number,
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _FormField(
                        controller: _stockController,
                        label: 'Stock',
                        keyboardType: TextInputType.number,
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                ),
                _FormField(
                  controller: _imageController,
                  label: 'Image du produit',
                  validator: _required,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Visible dans la boutique'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _freeShipping,
                  onChanged: (value) => setState(() => _freeShipping = value),
                  title: const Text('Livraison offerte'),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final product = widget.product;

    final savedProduct = product == null
        ? Product(
            id: 'p-${DateTime.now().millisecondsSinceEpoch}',
            vendorId: widget.vendor.id,
            vendorName: widget.vendor.shopName ?? widget.vendor.name,
            name: _nameController.text.trim(),
            shortDescription: _shortDescriptionController.text.trim(),
            longDescription: _longDescriptionController.text.trim(),
            price: price,
            imageUrl: _imageController.text.trim(),
            category: _category,
            stock: stock,
            isActive: _isActive,
            freeShipping: _freeShipping,
            tags: const ['Boutique'],
            createdAt: DateTime.now(),
          )
        : product.copyWith(
            vendorName: widget.vendor.shopName ?? widget.vendor.name,
            name: _nameController.text.trim(),
            shortDescription: _shortDescriptionController.text.trim(),
            longDescription: _longDescriptionController.text.trim(),
            price: price,
            imageUrl: _imageController.text.trim(),
            category: _category,
            stock: stock,
            isActive: _isActive,
            freeShipping: _freeShipping,
          );

    widget.onSave(savedProduct);
    Navigator.pop(context);
  }
}

class _ShopFormSheet extends StatefulWidget {
  final AppUser vendor;
  final ValueChanged<AppUser> onSave;

  const _ShopFormSheet({required this.vendor, required this.onSave});

  @override
  State<_ShopFormSheet> createState() => _ShopFormSheetState();
}

class _ShopFormSheetState extends State<_ShopFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _bannerController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _categoriesController;

  @override
  void initState() {
    super.initState();
    final vendor = widget.vendor;
    _nameController =
        TextEditingController(text: vendor.shopName ?? vendor.name);
    _taglineController = TextEditingController(text: vendor.shopTagline ?? '');
    _descriptionController =
        TextEditingController(text: vendor.shopDescription ?? '');
    _bannerController = TextEditingController(
      text: vendor.shopBannerUrl ??
          'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=1400&q=80',
    );
    _cityController = TextEditingController(text: vendor.shopCity ?? 'Cotonou');
    _countryController = TextEditingController(
      text: vendor.shopCountry ?? 'Bénin',
    );
    _categoriesController = TextEditingController(
      text: vendor.shopCategories.join(', '),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _bannerController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil boutique',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                _FormField(
                  controller: _nameController,
                  label: 'Nom de la boutique',
                  validator: _required,
                ),
                _FormField(
                  controller: _taglineController,
                  label: 'Phrase d’accroche',
                  validator: _required,
                ),
                _FormField(
                  controller: _descriptionController,
                  label: 'Présentation',
                  maxLines: 5,
                  validator: _required,
                ),
                _FormField(
                  controller: _bannerController,
                  label: 'Image de couverture',
                  validator: _required,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _FormField(
                        controller: _cityController,
                        label: 'Ville',
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _FormField(
                        controller: _countryController,
                        label: 'Pays',
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                _FormField(
                  controller: _categoriesController,
                  label: 'Catégories',
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final categories = _categoriesController.text
        .split(',')
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty)
        .toList();

    widget.onSave(
      widget.vendor.copyWith(
        shopName: _nameController.text.trim(),
        shopTagline: _taglineController.text.trim(),
        shopDescription: _descriptionController.text.trim(),
        shopBannerUrl: _bannerController.text.trim(),
        shopCity: _cityController.text.trim(),
        shopCountry: _countryController.text.trim(),
        shopCategories: categories,
      ),
    );
    Navigator.pop(context);
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
