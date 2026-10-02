import '../../../../core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shophub/domain/entities/order.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme.dart';
import '../../../../providers/orders_providers.dart';
import '../../../../providers/user_providers.dart';

class ProfileRecentOrders extends ConsumerWidget {
  final List<Order> orders;
  final bool isLoading;
  final bool hasError;

  const ProfileRecentOrders(
      {super.key,
      required this.orders,
      this.isLoading = false,
      this.hasError = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (hasError)
      return Text('Impossible de charger les commandes.',
          style: TextStyle(color: context.textMuted));
    if (orders.isEmpty)
      return Text('Aucune commande pour le moment.',
          style: TextStyle(color: context.textMuted));
    return Column(children: [
      for (final order in orders.take(3))
        _OrderTile(
          order: order,
          onTrack: order.paymentStatus == 'paid' ||
                  order.paymentStatus == 'not_required'
              ? () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => _OrderTrackingSheet(order: order))
              : null,
          onRefreshPayment:
              order.paymentId != null && order.paymentStatus == 'pending'
                  ? () async {
                      try {
                        await ref
                            .read(ordersUseCasesProvider)
                            .refreshPayment(order.paymentId!);
                        ref.invalidate(myOrdersProvider);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())));
                        }
                      }
                    }
                  : null,
          onReview: order.paymentStatus == 'paid' &&
                  order.status == OrderStatus.delivered &&
                  order.shopReviewRating == null
              ? () => showDialog<void>(
                  context: context,
                  builder: (_) => _RateShopDialog(order: order))
              : null,
        ),
    ]);
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onTrack;
  final VoidCallback? onRefreshPayment;
  final VoidCallback? onReview;
  const _OrderTile(
      {required this.order,
      required this.onTrack,
      this.onRefreshPayment,
      this.onReview});

  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.shipped => AppColors.warning,
      OrderStatus.confirmed => AppColors.primary,
      OrderStatus.pending => AppColors.warning,
    };
    final productNames = order.items
        .map((item) => item.product.name)
        .where((name) => name.isNotEmpty)
        .toList();
    final title = productNames.isEmpty ? 'Commande' : productNames.first;
    final date = order.createdAt.day.toString().padLeft(2, '0') +
        '/' +
        order.createdAt.month.toString().padLeft(2, '0') +
        '/' +
        order.createdAt.year.toString();
    final vendor = order.vendorName.isEmpty ? 'Boutique' : order.vendorName;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: context.softShadow),
      child: Row(children: [
        Icon(Icons.receipt_long_rounded, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface)),
          const SizedBox(height: 3),
          Text('$vendor · $date · ${order.status.label}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.textMuted)),
          if (order.paymentStatus == 'pending')
            Text('Paiement à confirmer',
                style: TextStyle(fontSize: 11, color: context.textMuted)),
          if (order.paymentStatus == 'failed' ||
              order.paymentStatus == 'refunded')
            Text(
                order.paymentStatus == 'failed'
                    ? 'Paiement échoué'
                    : 'Paiement remboursé',
                style: const TextStyle(fontSize: 11, color: AppColors.danger)),
          Wrap(spacing: AppSpacing.sm, children: [
            if (onRefreshPayment != null)
              TextButton.icon(
                  onPressed: onRefreshPayment,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Vérifier le paiement')),
            if (onTrack != null)
              TextButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text('Suivre')),
            if (onReview != null)
              TextButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text('Noter la boutique')),
            if (order.shopReviewRating != null)
              Text('Votre note : ${order.shopReviewRating} ★',
                  style: TextStyle(color: context.textMuted, fontSize: 12)),
          ]),
        ])),
        const SizedBox(width: AppSpacing.sm),
        Text(formatCfa(order.total),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ]),
    );
  }
}

class _OrderTrackingSheet extends ConsumerWidget {
  final Order order;
  const _OrderTrackingSheet({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref
            .watch(myOrdersProvider)
            .valueOrNull
            ?.where((item) => item.id == order.id)
            .firstOrNull ??
        order;
    const steps = [
      ('Commande reçue', 'La boutique a reçu votre commande.'),
      ('Confirmée', 'La boutique prépare les articles.'),
      ('Expédiée', 'La commande est confiée à la livraison.'),
      ('Livrée', 'La livraison est terminée.'),
    ];
    return SafeArea(
        child: Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('Suivi de commande',
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                  tooltip: 'Actualiser le statut',
                  onPressed: () => ref.invalidate(myOrdersProvider),
                  icon: const Icon(Icons.refresh_rounded)),
            ]),
            Text(latest.vendorName + ' · ' + latest.id,
                style: TextStyle(color: context.textMuted, fontSize: 12)),
            const SizedBox(height: AppSpacing.lg),
            for (var index = 0; index < steps.length; index++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: index <= latest.status.index
                      ? AppColors.success.withValues(alpha: 0.14)
                      : context.textMuted.withValues(alpha: 0.12),
                  child: Icon(
                      index <= latest.status.index
                          ? Icons.check_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: index <= latest.status.index
                          ? AppColors.success
                          : context.textMuted),
                ),
                title: Text(steps[index].$1),
                subtitle: Text(steps[index].$2),
                dense: true,
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
                'Le suivi reflète le dernier statut communiqué par la boutique. La localisation du livreur n’est pas encore disponible.',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          ]),
    ));
  }
}

class _RateShopDialog extends ConsumerStatefulWidget {
  final Order order;
  const _RateShopDialog({required this.order});
  @override
  ConsumerState<_RateShopDialog> createState() => _RateShopDialogState();
}

class _RateShopDialogState extends ConsumerState<_RateShopDialog> {
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(ordersUseCasesProvider).submitShopReview(
          orderId: widget.order.id,
          rating: _rating,
          comment: _commentController.text);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(vendorsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.order.vendorName.isEmpty
        ? 'cette boutique'
        : widget.order.vendorName;
    return AlertDialog(
      title: Text('Évaluer $shop'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var value = 1; value <= 5; value++)
            IconButton(
              tooltip: '$value étoile' + (value > 1 ? 's' : ''),
              onPressed: _saving ? null : () => setState(() => _rating = value),
              icon: Icon(
                  value <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB800),
                  size: 30),
            ),
        ]),
        TextField(
            controller: _commentController,
            maxLength: 500,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Commentaire (facultatif)',
                alignLabelWithHint: true)),
      ]),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler')),
        FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Envoyer')),
      ],
    );
  }
}
