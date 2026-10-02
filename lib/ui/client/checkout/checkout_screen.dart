import '../../../core/currency.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shophub/domain/entities/checkout_payment.dart';

import '../../../core/theme.dart';
import '../../../core/providers/core_providers.dart';
import 'package:shophub/domain/entities/cart_item.dart';
import 'package:shophub/domain/entities/delivery_option.dart';
import '../../../providers/cart_providers.dart';
import '../../../providers/checkout_providers.dart';
import '../../../providers/orders_providers.dart';
import '../../../providers/auth_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
  bool _isSubmitting = false;
  bool _isConfirmed = false;
  bool _checkingPayment = false;
  bool _paymentFailed = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController(text: 'Cotonou');
  final _countryController = TextEditingController(text: 'Bénin');
  CheckoutPayment? _pendingPayment;
  CheckoutPaymentStatus? _paymentStatus;
  Timer? _paymentTimer;
  double _confirmedTotal = 0;
  String _confirmedDeliveryLabel = '';
  late String _orderNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _orderNumber = 'SH-${DateTime.now().millisecondsSinceEpoch}';
    final user = ref.read(authProvider);
    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _paymentTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _pendingPayment != null &&
        !_isConfirmed &&
        !_paymentFailed) {
      unawaited(_refreshPayment());
    }
  }

  Future<void> _confirmOrder() async {
    final values = [
      _nameController,
      _emailController,
      _phoneController,
      _streetController,
      _cityController,
      _countryController
    ].map((controller) => controller.text.trim()).toList();
    if (values.any((value) => value.isEmpty) ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(values[1])) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complète une adresse et un email valides.')));
      return;
    }
    if (ref.read(isDemoModeProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le paiement FedaPay est indisponible en mode démo.')));
      return;
    }
    setState(() => _isSubmitting = true);
    final delivery = ref.read(selectedDeliveryOptionProvider);
    final address = DeliveryAddress(
        fullName: values[0],
        phone: values[2],
        street: values[3],
        city: values[4],
        country: values[5]);
    try {
      final payment = await ref.read(ordersUseCasesProvider).startCheckout(
          items: ref.read(cartProvider),
          address: address,
          delivery: delivery,
          customerEmail: values[1]);
      if (!mounted) return;
      ref.invalidate(myOrdersProvider);
      _confirmedTotal = payment.amountXof.toDouble();
      _confirmedDeliveryLabel = delivery.estimatedLabel;
      if (payment.orders.isNotEmpty) _orderNumber = payment.orders.first.id;
      setState(() {
        _pendingPayment = payment;
        _isSubmitting = false;
      });
      await _openPaymentPage();
      _paymentTimer?.cancel();
      _paymentTimer =
          Timer.periodic(const Duration(seconds: 6), (_) => _refreshPayment());
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _openPaymentPage() async {
    final payment = _pendingPayment;
    if (payment == null) return;
    final opened = await launchUrl(Uri.parse(payment.checkoutUrl),
        mode: LaunchMode.externalApplication);
    if (!opened && mounted)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d’ouvrir la page FedaPay.')));
  }

  Future<void> _refreshPayment() async {
    final payment = _pendingPayment;
    if (payment == null || _checkingPayment || _paymentFailed || _isConfirmed)
      return;
    setState(() => _checkingPayment = true);
    try {
      final status =
          await ref.read(ordersUseCasesProvider).refreshPayment(payment.id);
      if (!mounted) return;
      _paymentStatus = status;
      if (status.status == 'paid') {
        _paymentTimer?.cancel();
        ref.invalidate(myOrdersProvider);
        ref.read(cartProvider.notifier).clear();
        setState(() {
          _isConfirmed = true;
          _checkingPayment = false;
        });
        return;
      }
      if (status.status == 'failed' || status.status == 'refunded') {
        _paymentTimer?.cancel();
        ref.invalidate(myOrdersProvider);
        setState(() {
          _paymentFailed = true;
          _checkingPayment = false;
        });
        return;
      }
    } catch (_) {
      // Keep pending if the status service is temporarily unavailable.
    }
    if (mounted) setState(() => _checkingPayment = false);
  }

  void _retryCheckout() {
    _paymentTimer?.cancel();
    setState(() {
      _pendingPayment = null;
      _paymentStatus = null;
      _paymentFailed = false;
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

    if (_pendingPayment != null) {
      return _PaymentPendingView(
          payment: _pendingPayment!,
          status: _paymentStatus?.status ?? 'pending',
          checking: _checkingPayment,
          failed: _paymentFailed,
          onOpen: _openPaymentPage,
          onRefresh: _refreshPayment,
          onRetry: _retryCheckout);
    }

    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalProvider);
    final total = ref.watch(checkoutTotalProvider);
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
              child: Column(children: [
                _checkoutField(_nameController, 'Nom complet'),
                _checkoutField(_emailController, 'Email du reçu',
                    type: TextInputType.emailAddress),
                _checkoutField(_phoneController, 'Téléphone',
                    type: TextInputType.phone),
                _checkoutField(_streetController, 'Rue et numéro'),
                Row(children: [
                  Expanded(child: _checkoutField(_cityController, 'Ville')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _checkoutField(_countryController, 'Pays'))
                ]),
              ]),
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
                          'FedaPay · Sandbox',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Paiement sécurisé en francs CFA (XOF).',
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

Widget _checkoutField(TextEditingController controller, String label,
        {TextInputType? type}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextField(
          controller: controller,
          keyboardType: type,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label)),
    );

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
              '${formatCfa(option.fee)}',
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
            '${formatCfa(item.subtotal)}',
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
                    : const Text('Continuer vers le paiement'),
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
          '${formatCfa(value)}',
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
                'Paiement confirmé',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'La boutique peut maintenant préparer votre commande.',
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
                      value: '${formatCfa(total)}',
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

class _PaymentPendingView extends StatelessWidget {
  final CheckoutPayment payment;
  final String status;
  final bool checking;
  final bool failed;
  final VoidCallback onOpen;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  const _PaymentPendingView(
      {required this.payment,
      required this.status,
      required this.checking,
      required this.failed,
      required this.onOpen,
      required this.onRefresh,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final amount = formatCfa(payment.amountXof);
    return Scaffold(
        appBar: AppBar(title: const Text('Paiement de la commande')),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : Icons.lock_clock_rounded,
                    size: 58,
                    color: failed ? AppColors.danger : AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(failed ? 'Paiement non abouti' : 'Paiement en attente',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(
                    failed
                        ? 'La commande n’a pas été transmise à la boutique. Votre panier est conservé.'
                        : 'Terminez le paiement chez FedaPay, puis revenez ici. Le serveur vérifie le statut.',
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                Text(amount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text('Référence ' + payment.id, textAlign: TextAlign.center),
                if (checking) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: CircularProgressIndicator())
                ],
                const SizedBox(height: AppSpacing.xl),
                if (!failed) ...[
                  ElevatedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Ouvrir FedaPay')),
                  OutlinedButton.icon(
                      onPressed: checking ? null : onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(status == 'paid'
                          ? 'Paiement confirmé'
                          : 'Vérifier le paiement')),
                ] else
                  ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Réessayer le paiement')),
              ]),
        )));
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
