import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'package:shophub/domain/entities/app_user.dart';

class ShopInfoCard extends StatelessWidget {
  final AppUser vendor;
  const ShopInfoCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: context.mediumShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: context.background,
                backgroundImage: vendor.avatarUrl != null
                    ? NetworkImage(vendor.avatarUrl!)
                    : null,
                child: vendor.avatarUrl == null
                    ? const Icon(Icons.storefront_rounded)
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vendor.shopName ?? vendor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (vendor.isVerified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vendor.shopTagline ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (vendor.shopCity != null)
                        _MetaItem(
                          icon: Icons.location_on_rounded,
                          label:
                              '${vendor.shopCity}, ${vendor.shopCountry ?? ''}',
                        ),
                      if (vendor.shopFoundedYear != null)
                        _MetaItem(
                          icon: Icons.calendar_today_rounded,
                          label: 'Depuis ${vendor.shopFoundedYear}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.textMuted),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textMuted),
        ),
      ],
    );
  }
}
