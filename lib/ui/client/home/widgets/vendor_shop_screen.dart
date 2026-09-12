import 'package:flutter/material.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/app_user.dart';
import '../../vendor_shop/vendor_shop_screen.dart';

class VendorShopCard extends StatelessWidget {
  final AppUser vendor;
  const VendorShopCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(child: VendorShopScreen(vendorId: vendor.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: context.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _Banner(vendor: vendor)),
            Expanded(flex: 4, child: _Info(vendor: vendor)),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final AppUser vendor;
  const _Banner({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            child: Image.network(
              vendor.shopBannerUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.md,
          bottom: -20,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.surface, width: 3),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: vendor.avatarUrl != null
                  ? NetworkImage(vendor.avatarUrl!)
                  : null,
              child: vendor.avatarUrl == null
                  ? const Icon(Icons.storefront_rounded)
                  : null,
            ),
          ),
        ),
        if (vendor.isVerified)
          Positioned(
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: context.softShadow,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  final AppUser vendor;
  const _Info({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vendor.shopName ?? vendor.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            vendor.shopTagline ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.textMuted),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFB800),
                size: 14,
              ),
              const SizedBox(width: 2),
              Text(
                vendor.shopRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(
                Icons.shopping_bag_rounded,
                size: 12,
                color: context.textMuted,
              ),
              const SizedBox(width: 2),
              Text(
                '${vendor.shopSales} ventes',
                style: TextStyle(fontSize: 11, color: context.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
