import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';
import '../../../../core/theme_provider.dart';
import '../../../../data/models/delivery_option.dart';
import '../../../../providers/checkout_providers.dart';
import '../profile_product_collection_screen.dart';

enum _ActionType {
  orders,
  addresses,
  payment,
  favorites,
  deliveries,
  support,
  promos,
  settings,
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final _ActionType type;

  const _Action(this.icon, this.label, this.color, this.type);
}

class ProfileQuickActions extends ConsumerWidget {
  const ProfileQuickActions({super.key});

  static const _actions = [
    _Action(
      Icons.receipt_long_rounded,
      'Commandes',
      AppColors.primary,
      _ActionType.orders,
    ),
    _Action(
      Icons.location_on_rounded,
      'Adresses',
      AppColors.success,
      _ActionType.addresses,
    ),
    _Action(
      Icons.credit_card_rounded,
      'Paiement',
      AppColors.warning,
      _ActionType.payment,
    ),
    _Action(
      Icons.favorite_rounded,
      'Favoris',
      AppColors.accent,
      _ActionType.favorites,
    ),
    _Action(
      Icons.local_shipping_rounded,
      'Livraisons',
      AppColors.primary,
      _ActionType.deliveries,
    ),
    _Action(
      Icons.support_agent_rounded,
      'Support',
      AppColors.success,
      _ActionType.support,
    ),
    _Action(
      Icons.card_giftcard_rounded,
      'Promos',
      AppColors.accent,
      _ActionType.promos,
    ),
    _Action(
      Icons.settings_rounded,
      'Paramètres',
      AppColors.warning,
      _ActionType.settings,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: List.generate(_actions.length, (i) {
        return FadeSlideIn(
          delay: Duration(milliseconds: 40 * i),
          child: _ActionTile(
            action: _actions[i],
            onTap: () => _handleAction(context, ref, _actions[i].type),
          ),
        );
      }),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    _ActionType type,
  ) {
    switch (type) {
      case _ActionType.orders:
        _showOrdersSheet(context);
      case _ActionType.addresses:
        _showAddressSheet(context, ref.read(deliveryAddressProvider));
      case _ActionType.payment:
        _showPaymentSheet(context);
      case _ActionType.favorites:
        Navigator.push(
          context,
          SlidePageRoute(
            child: const ProfileProductCollectionScreen(
              collection: ProfileProductCollection.favorites,
            ),
          ),
        );
      case _ActionType.deliveries:
        _showDeliveriesSheet(context, ref.read(deliveryOptionsProvider));
      case _ActionType.support:
        _showSupportSheet(context);
      case _ActionType.promos:
        Navigator.push(
          context,
          SlidePageRoute(
            child: const ProfileProductCollectionScreen(
              collection: ProfileProductCollection.promotions,
            ),
          ),
        );
      case _ActionType.settings:
        _showSettingsSheet(context);
    }
  }
}

class _ActionTile extends StatelessWidget {
  final _Action action;
  final VoidCallback onTap;

  const _ActionTile({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: context.softShadow,
            ),
            child: Icon(action.icon, color: action.color, size: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: context.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

void _showOrdersSheet(BuildContext context) {
  _showActionSheet(
    context,
    title: 'Mes commandes',
    icon: Icons.receipt_long_rounded,
    accent: AppColors.primary,
    child: const Column(
      children: [
        _InfoTile(
          icon: Icons.check_circle_rounded,
          title: '#SH-1284',
          subtitle: 'Casque Audio Pro X2 · Livrée · 179,99 €',
          color: AppColors.success,
        ),
        _InfoTile(
          icon: Icons.local_shipping_rounded,
          title: '#SH-1271',
          subtitle: 'Sneakers Urban White · En transit · 119,00 €',
          color: AppColors.warning,
        ),
        _InfoTile(
          icon: Icons.access_time_rounded,
          title: '#SH-1268',
          subtitle: 'Lampe Nordique · En attente · 79,90 €',
          color: AppColors.primary,
        ),
      ],
    ),
  );
}

void _showAddressSheet(BuildContext context, DeliveryAddress address) {
  _showActionSheet(
    context,
    title: 'Adresse',
    icon: Icons.location_on_rounded,
    accent: AppColors.success,
    child: Column(
      children: [
        _InfoTile(
          icon: Icons.person_rounded,
          title: address.fullName,
          subtitle: address.phone,
          color: AppColors.primary,
        ),
        _InfoTile(
          icon: Icons.home_rounded,
          title: address.street,
          subtitle: address.location,
          color: AppColors.success,
        ),
        const _NoticeBox(
          text: 'Adresse utilisée pour vos prochaines livraisons.',
        ),
      ],
    ),
  );
}

void _showPaymentSheet(BuildContext context) {
  _showActionSheet(
    context,
    title: 'Paiement',
    icon: Icons.credit_card_rounded,
    accent: AppColors.warning,
    child: const Column(
      children: [
        _InfoTile(
          icon: Icons.payments_rounded,
          title: 'Paiement à la livraison',
          subtitle: 'Mode actif pour vos commandes',
          color: AppColors.success,
        ),
        _InfoTile(
          icon: Icons.credit_card_off_rounded,
          title: 'Carte bancaire',
          subtitle: 'Indisponible pour le moment',
          color: AppColors.warning,
        ),
      ],
    ),
  );
}

void _showDeliveriesSheet(
  BuildContext context,
  List<DeliveryOption> options,
) {
  _showActionSheet(
    context,
    title: 'Livraisons',
    icon: Icons.local_shipping_rounded,
    accent: AppColors.primary,
    child: Column(
      children: [
        ...options.map(
          (option) => _InfoTile(
            icon: Icons.local_shipping_rounded,
            title: option.name,
            subtitle:
                '${option.estimatedLabel} · ${option.fee.toStringAsFixed(2)} €',
            color: AppColors.primary,
          ),
        ),
        const _NoticeBox(
          text: 'Ces modes seront proposés au moment de la commande.',
        ),
      ],
    ),
  );
}

void _showSupportSheet(BuildContext context) {
  _showActionSheet(
    context,
    title: 'Support',
    icon: Icons.support_agent_rounded,
    accent: AppColors.success,
    child: const Column(
      children: [
        _InfoTile(
          icon: Icons.chat_rounded,
          title: 'Chat client',
          subtitle: 'Réponse sous 5 minutes',
          color: AppColors.success,
        ),
        _InfoTile(
          icon: Icons.mail_rounded,
          title: 'support@shophub.app',
          subtitle: 'Canal de contact principal',
          color: AppColors.primary,
        ),
        _InfoTile(
          icon: Icons.help_rounded,
          title: 'FAQ',
          subtitle: 'Commandes, retours, livraison et favoris',
          color: AppColors.warning,
        ),
      ],
    ),
  );
}

void _showSettingsSheet(BuildContext context) {
  _showActionSheet(
    context,
    title: 'Paramètres',
    icon: Icons.settings_rounded,
    accent: AppColors.warning,
    child: const _SettingsContent(),
  );
}

void _showActionSheet(
  BuildContext context, {
  required String title,
  required IconData icon,
  required Color accent,
  required Widget child,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: sheetContext.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: accent),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String text;

  const _NoticeBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final isDark = widgetRef.watch(isDarkProvider);

    return Column(
      children: [
        _SwitchTile(
          icon: Icons.dark_mode_rounded,
          title: 'Mode sombre',
          subtitle: 'Changer immédiatement le thème',
          value: isDark,
          onChanged: (_) => widgetRef.read(themeModeProvider.notifier).toggle(),
        ),
        const _InfoTile(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          subtitle: 'Promos et suivi de livraison activés',
          color: AppColors.primary,
        ),
        const _InfoTile(
          icon: Icons.language_rounded,
          title: 'Langue',
          subtitle: 'Français',
          color: AppColors.warning,
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
