import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class _OrderPreview {
  final String id;
  final String label;
  final String date;
  final String amount;
  final String status;
  final Color statusColor;
  final IconData icon;

  const _OrderPreview({
    required this.id,
    required this.label,
    required this.date,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.icon,
  });
}

class ProfileRecentOrders extends StatelessWidget {
  const ProfileRecentOrders({super.key});

  static const _orders = [
    _OrderPreview(
      id: '#SH-1284',
      label: 'Casque Audio Pro X2',
      date: '12 sept. 2025',
      amount: '179,99 €',
      status: 'Livrée',
      statusColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    ),
    _OrderPreview(
      id: '#SH-1271',
      label: 'Sneakers Urban White',
      date: '8 sept. 2025',
      amount: '119,00 €',
      status: 'En transit',
      statusColor: AppColors.warning,
      icon: Icons.local_shipping_rounded,
    ),
    _OrderPreview(
      id: '#SH-1268',
      label: 'Lampe Nordique',
      date: '5 sept. 2025',
      amount: '79,90 €',
      status: 'En attente',
      statusColor: AppColors.primary,
      icon: Icons.access_time_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _orders.map((o) => _OrderTile(order: o)).toList(),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final _OrderPreview order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: order.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(order.icon, color: order.statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      order.amount,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      order.id,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' · ${order.date}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: order.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: order.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
