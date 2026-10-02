import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'package:shophub/domain/entities/app_user.dart';

class ShopAppBar extends StatelessWidget {
  final AppUser vendor;
  const ShopAppBar({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: context.surface,
      leading: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Material(
          color: context.surface.withValues(alpha: 0.9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (vendor.shopBannerUrl != null)
              Image.network(
                vendor.shopBannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppColors.primary),
              )
            else
              Container(color: AppColors.primary),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
