import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shophub/domain/entities/delivery_option.dart';
import 'cart_providers.dart';
import 'platform_config_provider.dart';

final deliveryOptionsProvider = Provider<List<DeliveryOption>>((ref) {
  return ref.watch(platformConfigProvider).deliveryOptions;
});

final selectedDeliveryOptionIdProvider = StateProvider<String>((ref) {
  return 'standard';
});

final selectedDeliveryOptionProvider = Provider<DeliveryOption>((ref) {
  final selectedId = ref.watch(selectedDeliveryOptionIdProvider);
  final options = ref.watch(deliveryOptionsProvider);

  return options.firstWhere(
    (option) => option.id == selectedId,
    orElse: () => options.first,
  );
});

final checkoutTotalProvider = Provider<double>((ref) {
  final cartTotal = ref.watch(cartTotalProvider);
  final deliveryFee = ref.watch(selectedDeliveryOptionProvider).fee;

  return cartTotal + deliveryFee;
});
