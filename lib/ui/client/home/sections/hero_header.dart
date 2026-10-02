import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../core/theme_provider.dart';
import '../widgets/glass_search_bar.dart';
import '../widgets/theme_toggle.dart';
import '../../../../providers/platform_config_provider.dart';

class HeroHeader extends ConsumerWidget {
  const HeroHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = ref.watch(isDarkProvider);
    final config = ref.watch(platformConfigProvider);
    final heroImage = config.featuredSlides.firstOrNull?.imageUrl ??
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1600&q=80';

    return SizedBox(
      height: 400 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            heroImage,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
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
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xxl,
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
                    child: _RotatingTagline(
                      phrases: config.featuredSlides
                          .map((slide) => slide.subtitle)
                          .toList(),
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

class _RotatingTagline extends StatefulWidget {
  final List<String> phrases;
  const _RotatingTagline({required this.phrases});

  @override
  State<_RotatingTagline> createState() => _RotatingTaglineState();
}

class _RotatingTaglineState extends State<_RotatingTagline> {
  late final Timer _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      final phrases = widget.phrases;
      if (phrases.isEmpty) return;
      setState(() => _index = (_index + 1) % phrases.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrases = widget.phrases;
    if (phrases.isEmpty) return const SizedBox(height: 46);
    final index = _index % phrases.length;
    return SizedBox(
      height: 46,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.75),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: Align(
          key: ValueKey(phrases[index]),
          alignment: Alignment.centerLeft,
          child: Text(
            phrases[index],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.2,
              height: 1.35,
            ),
          ),
        ),
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
