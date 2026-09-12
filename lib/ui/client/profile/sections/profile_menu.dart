import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/theme_provider.dart';

class _MenuEntry {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final bool isToggle;
  const _MenuEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.isToggle = false,
  });
}

class ProfileMenu extends ConsumerWidget {
  final VoidCallback onLogout;
  const ProfileMenu({super.key, required this.onLogout});

  static const _entries = [
    _MenuEntry(
      icon: Icons.notifications_rounded,
      title: 'Notifications',
      subtitle: 'Promos, livraisons, messages',
    ),
    _MenuEntry(
      icon: Icons.dark_mode_rounded,
      title: 'Mode sombre',
      subtitle: 'Apparence de l\'application',
      isToggle: true,
    ),
    _MenuEntry(
      icon: Icons.language_rounded,
      title: 'Langue',
      subtitle: 'Français',
    ),
    _MenuEntry(
      icon: Icons.shield_rounded,
      title: 'Confidentialité',
      subtitle: 'Sécurité & données',
    ),
    _MenuEntry(
      icon: Icons.help_outline_rounded,
      title: 'Aide & support',
      subtitle: 'FAQ, contact',
    ),
    _MenuEntry(
      icon: Icons.logout_rounded,
      title: 'Déconnexion',
      isDestructive: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Column(
        children: List.generate(_entries.length, (i) {
          final entry = _entries[i];
          final isLast = i == _entries.length - 1;
          return Column(
            children: [
              _tile(
                context,
                entry,
                isDark: isDark,
                onToggle: entry.isToggle
                    ? () => ref.read(themeModeProvider.notifier).toggle()
                    : null,
                onTap: entry.isDestructive
                    ? onLogout
                    : entry.isToggle
                        ? null
                        : () {},
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: context.textMuted.withValues(alpha: 0.12),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    _MenuEntry entry, {
    required bool isDark,
    VoidCallback? onToggle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              entry.icon,
              size: 20,
              color: entry.isDestructive
                  ? AppColors.danger
                  : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: entry.isDestructive
                          ? AppColors.danger
                          : context.onSurface,
                    ),
                  ),
                  if (entry.subtitle != null)
                    Text(
                      entry.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (entry.isToggle)
              Switch.adaptive(
                value: isDark,
                onChanged: (_) => onToggle?.call(),
                activeColor: AppColors.primary,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
