import '../../../../core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import 'package:shophub/domain/entities/product.dart';
import '../../../../providers/cart_providers.dart';

class DetailBottomBar extends ConsumerStatefulWidget {
  final Product product;
  const DetailBottomBar({super.key, required this.product});

  @override
  ConsumerState<DetailBottomBar> createState() => _DetailBottomBarState();
}

class _DetailBottomBarState extends ConsumerState<DetailBottomBar> {
  bool _added = false;

  void _handleAdd() {
    ref.read(cartProvider.notifier).add(widget.product);
    setState(() => _added = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} ajouté'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(milliseconds: 1500),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: context.mediumShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Prix',
                  style: TextStyle(fontSize: 11, color: context.textMuted),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.product.isOnSale)
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 2),
                        child: Text(
                          '${formatCfa(widget.product.originalPrice!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    Text(
                      '${formatCfa(widget.product.price)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.xxl),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _added ? AppColors.success : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _added ? Icons.check_rounded : Icons.shopping_bag_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _added ? 'Ajouté !' : 'Ajouter au panier',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
