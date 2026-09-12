import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/product.dart';

class ProductInfo extends StatelessWidget {
  final Product product;
  const ProductInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Catégorie + promo + note
        Row(
          children: [
            _pill(
              context,
              text: product.category,
              bg: AppColors.primary.withValues(alpha: 0.1),
              fg: AppColors.primary,
            ),
            if (product.isOnSale) ...[
              const SizedBox(width: AppSpacing.sm),
              _pill(
                context,
                text: '-${product.discountPercent}%',
                bg: AppColors.accent,
                fg: Colors.white,
              ),
            ],
            const Spacer(),
            const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFB800),
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              product.rating.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: context.onSurface,
              ),
            ),
            Text(
              ' (${product.reviewCount})',
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Nom
        Text(
          product.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Courte description
        Text(
          product.shortDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Tags
        if (product.tags.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: product.tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}