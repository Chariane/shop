import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/app_user.dart';

class ShopInfoCard extends StatelessWidget {
  final AppUser vendor;
  const ShopInfoCard({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 32,
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
                    Row(
                      children: [
                        if (vendor.shopCity != null) ...[
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: context.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${vendor.shopCity}, ${vendor.shopCountry ?? ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                        if (vendor.shopFoundedYear != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: context.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Depuis ${vendor.shopFoundedYear}',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}