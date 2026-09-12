import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../core/theme_provider.dart';
import '../../../../providers/notification_providers.dart';
import '../notifications_screen.dart';

enum _MenuEntryType {
  notifications,
  theme,
  language,
  privacy,
  support,
  logout,
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final bool isToggle;
  final _MenuEntryType type;

  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.type,
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
      type: _MenuEntryType.notifications,
    ),
    _MenuEntry(
      icon: Icons.dark_mode_rounded,
      title: 'Mode sombre',
      subtitle: 'Apparence de l\'application',
      type: _MenuEntryType.theme,
      isToggle: true,
    ),
    _MenuEntry(
      icon: Icons.language_rounded,
      title: 'Langue',
      subtitle: 'Français',
      type: _MenuEntryType.language,
    ),
    _MenuEntry(
      icon: Icons.shield_rounded,
      title: 'Confidentialité',
      subtitle: 'Sécurité & données',
      type: _MenuEntryType.privacy,
    ),
    _MenuEntry(
      icon: Icons.help_outline_rounded,
      title: 'Aide & support',
      subtitle: 'FAQ, contact',
      type: _MenuEntryType.support,
    ),
    _MenuEntry(
      icon: Icons.logout_rounded,
      title: 'Déconnexion',
      type: _MenuEntryType.logout,
      isDestructive: true,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

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
                unreadNotifications: unreadNotifications,
                onToggle: entry.isToggle
                    ? () => ref.read(themeModeProvider.notifier).toggle()
                    : null,
                onTap: entry.isDestructive
                    ? onLogout
                    : entry.isToggle
                        ? null
                        : () => _handleEntryTap(context, entry.type),
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

  void _handleEntryTap(BuildContext context, _MenuEntryType type) {
    switch (type) {
      case _MenuEntryType.notifications:
        Navigator.push(
          context,
          SlidePageRoute(child: const NotificationsScreen()),
        );
      case _MenuEntryType.language:
        _showInfoSnackBar(context, 'La langue active est le français.');
      case _MenuEntryType.privacy:
        _showInfoSnackBar(
          context,
          'Vos préférences de confidentialité sont à jour.',
        );
      case _MenuEntryType.support:
        _showInfoSnackBar(context, 'Support : support@shophub.app');
      case _MenuEntryType.theme:
      case _MenuEntryType.logout:
        break;
    }
  }

  void _showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    _MenuEntry entry, {
    required bool isDark,
    required int unreadNotifications,
    VoidCallback? onToggle,
    VoidCallback? onTap,
  }) {
    final subtitle =
        entry.type == _MenuEntryType.notifications && unreadNotifications > 0
            ? '$unreadNotifications nouvelle(s) notification(s)'
            : entry.subtitle;

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
              color: entry.isDestructive ? AppColors.danger : AppColors.primary,
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
                  if (subtitle != null)
                    Text(
                      subtitle,
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
                activeThumbColor: AppColors.primary,
              )
            else if (entry.type == _MenuEntryType.notifications &&
                unreadNotifications > 0)
              Badge(
                label: Text('$unreadNotifications'),
                backgroundColor: AppColors.accent,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: context.textMuted,
                  size: 20,
                ),
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
