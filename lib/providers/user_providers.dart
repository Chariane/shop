import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_user.dart';
import 'product_providers.dart';

/// [PROVIDER] Liste des vendeurs (async)
final vendorsProvider = FutureProvider<List<AppUser>>((ref) async {
  return ref.watch(marketplaceApiProvider).fetchVendors();
});

/// [PROVIDER] Un vendeur par ID — retourne un AsyncValue<AppUser>.
/// Utilisation : ref.watch(vendorByIdProvider(id)).when(...)
final vendorByIdProvider =
    Provider.family<AsyncValue<AppUser>, String>((ref, id) {
  final vendors = ref.watch(vendorsProvider);
  return vendors.whenData(
    (list) => list.firstWhere(
      (v) => v.id == id,
      orElse: () => throw StateError('Vendeur introuvable : $id'),
    ),
  );
});