import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/delivery_option.dart';
import '../../../providers/cart_providers.dart';
import '../../../providers/checkout_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isSubmitting = false;
  bool _isConfirmed = false;
  double _confirmedTotal = 0;
  String _confirmedDeliveryLabel = '';
  late final String _orderNumber;

  @override
  void initState() {
    super.initState();
    _orderNumber = 'SH-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _confirmOrder() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final delivery = ref.read(selectedDeliveryOptionProvider);
    _confirmedTotal = ref.read(checkoutTotalProvider);
    _confirmedDeliveryLabel = delivery.estimatedLabel;
    ref.read(cartProvider.notifier).clear();

    setState(() {
      _isSubmitting = false;
      _isConfirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfirmed) {
      return _ConfirmationView(
        orderNumber: _orderNumber,
        total: _confirmedTotal,
        deliveryLabel: _confirmedDeliveryLabel,
      );
    }

    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final total = ref.watch(checkoutTotalProvider);
    final address = ref.watch(deliveryAddressProvider);
    final deliveryOptions = ref.watch(deliveryOptionsProvider);
    final selectedDelivery = ref.watch(selectedDeliveryOptionProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(title: const Text('Commande')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            140,
          ),
          children: [
            _Section(
              title: 'Adresse de livraison',
              child: _AddressBlock(address: address),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Mode de livraison',
              child: Column(
                children: deliveryOptions
                    .map(
                      (option) => _DeliveryOptionTile(
                        option: option,
                        selectedId: selectedDelivery.id,
                        onSelected: () => ref
                            .read(selectedDeliveryOptionIdProvider.notifier)
                            .state = option.id,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Articles',
              child: Column(
                children:
                    items.map((item) => _OrderItemRow(item: item)).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Paiement',
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paiement à la livraison',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Aucune transaction en ligne nécessaire',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _CheckoutBottomBar(
        subtotal: subtotal,
        deliveryFee: selectedDelivery.fee,
        total: total,
        isSubmitting: _isSubmitting,
        onConfirm: items.isEmpty || _isSubmitting ? null : _confirmOrder,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  final DeliveryAddress address;

  const _AddressBlock({required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.fullName,
                style: TextStyle(
                  color: context.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(address.phone, style: Theme.of(context).textTheme.bodySmall),
              Text(
                address.street,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                address.location,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  final DeliveryOption option;
  final String selectedId;
  final VoidCallback onSelected;

  const _DeliveryOptionTile({
    required this.option,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = option.id == selectedId;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : context.textMuted.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: TextStyle(
                      color: context.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.estimatedLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${option.fee.toStringAsFixed(2)} €',
              style: TextStyle(
                color: context.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.network(
              item.product.imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: context.background,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: context.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Quantité : ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${item.subtotal.toStringAsFixed(2)} €',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final bool isSubmitting;
  final VoidCallback? onConfirm;

  const _CheckoutBottomBar({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: context.mediumShadow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PriceRow(label: 'Sous-total', value: subtotal),
            const SizedBox(height: AppSpacing.xs),
            _PriceRow(label: 'Livraison', value: deliveryFee),
            const Divider(height: AppSpacing.xxl),
            _PriceRow(label: 'Total', value: total, isTotal: true),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmer la commande'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? context.onSurface : context.textMuted,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '${value.toStringAsFixed(2)} €',
          style: TextStyle(
            color: isTotal ? AppColors.primary : context.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: isTotal ? 20 : 13,
          ),
        ),
      ],
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  final String orderNumber;
  final double total;
  final String deliveryLabel;

  const _ConfirmationView({
    required this.orderNumber,
    required this.total,
    required this.deliveryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Commande confirmée',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Votre commande a bien été enregistrée.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: context.softShadow,
                ),
                child: Column(
                  children: [
                    _InfoLine(label: 'Référence', value: orderNumber),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoLine(label: 'Livraison estimée', value: deliveryLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoLine(
                      label: 'Total',
                      value: '${total.toStringAsFixed(2)} €',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour au panier'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: context.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
