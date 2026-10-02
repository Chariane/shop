import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'package:shophub/domain/entities/app_user.dart';

class ShopStats extends StatelessWidget {
  final AppUser vendor;
  const ShopStats({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          _stat(
            context,
            icon: Icons.star_rounded,
            value: vendor.shopRating.toStringAsFixed(1),
            label: 'Note',
            color: const Color(0xFFFFB800),
          ),
          const SizedBox(width: AppSpacing.md),
          _stat(
            context,
            icon: Icons.shopping_bag_rounded,
            value: '${vendor.shopSales}',
            label: 'Ventes',
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.md),
          _stat(
            context,
            icon: Icons.access_time_rounded,
            value: vendor.responseTimeLabel,
            label: 'Réponse',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: context.softShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: context.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
