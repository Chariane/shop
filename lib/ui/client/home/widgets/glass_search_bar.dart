import 'package:flutter/material.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../catalog_screen.dart';

class GlassSearchBar extends StatelessWidget {
  const GlassSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlidePageRoute(child: const CatalogScreen()),
      ),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Rechercher un produit, une boutique...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}