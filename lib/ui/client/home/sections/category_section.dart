import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../providers/filter_providers.dart';

class CategorySection extends ConsumerWidget {
  const CategorySection({super.key});

  static const _items = [
    _CategoryItem(
      label: 'Tech',
      image:
          'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80',
    ),
    _CategoryItem(
      label: 'Mode',
      image:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80',
    ),
    _CategoryItem(
      label: 'Maison',
      image:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80',
    ),
    _CategoryItem(
      label: 'Sport',
      image:
          'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=600&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Explorer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final cat = _items[i];
              return PressableScale(
                onTap: () => ref
                    .read(filterProvider.notifier)
                    .setCategory(cat.label),
                child: _CategoryCard(item: cat),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  final String label, image;
  const _CategoryItem({required this.label, required this.image});
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;
  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.image,
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
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}