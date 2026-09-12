import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../core/theme_provider.dart';
import '../widgets/glass_search_bar.dart';
import '../widgets/theme_toggle.dart';

class HeroHeader extends ConsumerWidget {
  const HeroHeader({super.key});

  static const _bgImage =
      'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1600&q=80';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = ref.watch(isDarkProvider);

    return SizedBox(
      height: 400 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _bgImage,
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
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _BrandMark(),
                      const Spacer(),
                      ThemeToggle(isDark: isDark),
                    ],
                  ),
                  const Spacer(),
                  const FadeSlideIn(
                    child: Text(
                      'ShopHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      'Achetez. Vendez. Rayonnez.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const FadeSlideIn(
                    delay: Duration(milliseconds: 220),
                    child: GlassSearchBar(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text(
          'SH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}