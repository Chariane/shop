import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../providers/cart_providers.dart';
import '../../../../providers/favorites_providers.dart';
import '../widgets/profile_stat_card.dart';

class ProfileStats extends ConsumerWidget {
  final int ordersCount;
  const ProfileStats({super.key, required this.ordersCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favCount = ref.watch(favoritesCountProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Row(
      children: [
        Expanded(
          child: ProfileStatCard(
            icon: Icons.receipt_long_rounded,
            value: '$ordersCount',
            label: 'Commandes',
            accent: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ProfileStatCard(
            icon: Icons.favorite_rounded,
            value: '$favCount',
            label: 'Favoris',
            accent: AppColors.accent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ProfileStatCard(
            icon: Icons.shopping_bag_rounded,
            value: '$cartCount',
            label: 'Panier',
            accent: AppColors.success,
          ),
        ),
      ],
    );
  }
}
