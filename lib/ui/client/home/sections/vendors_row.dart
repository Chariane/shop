import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/app_user.dart';
import '../../../../providers/user_providers.dart';
import '../../../widgets/shimmer.dart';
import '../widgets/vendor_shop_card.dart';

class VendorsRow extends ConsumerWidget {
  const VendorsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(vendorsProvider);

    return SizedBox(
      height: 200,
      child: vendors.when(
        loading: () => _skeletons(),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (list) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, i) => SizedBox(
            width: 260,
            child: VendorShopCard(vendor: list[i]),
          ),
        ),
      ),
    );
  }

  Widget _skeletons() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (_, __) => const SizedBox(
        width: 260,
        child: ShimmerProductCard(),
      ),
    );
  }
}

// Ré-export pour éviter d'importer AppUser partout
typedef VendorsList = List<AppUser>;