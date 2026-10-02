import 'package:flutter/material.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import 'package:shophub/domain/entities/app_user.dart';
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
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: context.softShadow),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                vendor.shopBannerUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.primary),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.22),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              _VerifiedBadge(isVisible: vendor.isVerified),
              _ShopInfo(vendor: vendor),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isVisible;

  const _VerifiedBadge({required this.isVisible});

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      right: AppSpacing.sm,
      top: AppSpacing.sm,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: context.softShadow,
        ),
        child: const Icon(
          Icons.verified_rounded,
          color: AppColors.primary,
          size: 15,
        ),
      ),
    );
  }
}

class _ShopInfo extends StatelessWidget {
  final AppUser vendor;
  const _ShopInfo({required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vendor.shopName ?? vendor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vendor.shopTagline ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _MetricPill(
                  icon: Icons.star_rounded,
                  label: vendor.shopRating.toStringAsFixed(1),
                  iconColor: const Color(0xFFFFC145),
                ),
                _MetricPill(
                  icon: Icons.shopping_bag_rounded,
                  label: '${vendor.shopSales} ventes',
                  iconColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MetricPill({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
