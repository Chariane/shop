import 'package:flutter/material.dart';
import '../../../../core/animations.dart';
import '../../../../core/theme.dart';

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  const _Action(this.icon, this.label, this.color);
}

class ProfileQuickActions extends StatelessWidget {
  const ProfileQuickActions({super.key});

  static const _actions = [
    _Action(Icons.receipt_long_rounded, 'Commandes', AppColors.primary),
    _Action(Icons.location_on_rounded, 'Adresses', AppColors.success),
    _Action(Icons.credit_card_rounded, 'Paiement', AppColors.warning),
    _Action(Icons.favorite_rounded, 'Favoris', AppColors.accent),
    _Action(Icons.local_shipping_rounded, 'Livraisons', AppColors.primary),
    _Action(Icons.support_agent_rounded, 'Support', AppColors.success),
    _Action(Icons.card_giftcard_rounded, 'Promos', AppColors.accent),
    _Action(Icons.settings_rounded, 'Paramètres', AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: List.generate(_actions.length, (i) {
        return FadeSlideIn(
          delay: Duration(milliseconds: 40 * i),
          child: _ActionTile(action: _actions[i]),
        );
      }),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final _Action action;
  const _ActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {},
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
