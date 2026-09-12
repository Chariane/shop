import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/delivery_option.dart';
import 'cart_providers.dart';

final deliveryAddressProvider = Provider<DeliveryAddress>((ref) {
  return const DeliveryAddress(
    fullName: 'Alex Martin',
    phone: '+229 01 97 00 00 00',
    street: 'Rue 12.345, Fidjrossè',
    city: 'Cotonou',
    country: 'Bénin',
  );
});

final deliveryOptionsProvider = Provider<List<DeliveryOption>>((ref) {
  return const [
    DeliveryOption(
      id: 'standard',
      name: 'Livraison standard',
      description: 'Livraison à domicile par coursier partenaire',
      estimatedLabel: '2 à 4 jours',
      fee: 4.99,
    ),
    DeliveryOption(
      id: 'express',
      name: 'Livraison express',
      description: 'Traitement prioritaire et livraison rapide',
      estimatedLabel: '24 à 48 h',
      fee: 9.99,
    ),
    DeliveryOption(
      id: 'pickup',
      name: 'Point relais',
      description: 'Retrait dans un point partenaire proche',
      estimatedLabel: '1 à 3 jours',
      fee: 2.49,
    ),
  ];
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
