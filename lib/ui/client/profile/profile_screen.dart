import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/animations.dart';
import '../../../core/theme.dart';
import 'sections/profile_header.dart';
import 'sections/profile_menu.dart';
import 'sections/profile_quick_actions.dart';
import 'sections/profile_recent_orders.dart';
import 'sections/profile_stats.dart';
import 'sections/profile_wallet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideIn(
                child: ProfileHeader(
                  name: 'Alex Martin',
                  email: 'alex.martin@example.com',
                  avatarUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=300&q=80',
                  memberSince: 'mars 2023',
                  onEdit: () {},
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: ProfileStats(ordersCount: 12),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 160),
                child: ProfileWallet(
                  points: 2450,
                  tier: 'Gold',
                  progressToNext: 0.65,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _sectionTitle(context, 'Actions rapides'),
              ),
              const SizedBox(height: AppSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 260),
                child: ProfileQuickActions(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                child: _sectionTitle(context, 'Commandes récentes'),
              ),
              const SizedBox(height: AppSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 360),
                child: ProfileRecentOrders(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 420),
                child: _sectionTitle(context, 'Préférences'),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 460),
                child: ProfileMenu(
                  onLogout: () => _handleLogout(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Center(
                child: Text(
                  'ShopHub v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(text, style: Theme.of(context).textTheme.titleLarge);
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Déconnecté'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  margin: const EdgeInsets.all(AppSpacing.lg),
                ),
              );
            },
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
