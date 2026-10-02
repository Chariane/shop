import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shophub/domain/entities/app_user.dart';
import '../domain/usecases/catalog_use_cases.dart';
import '../core/providers/core_providers.dart';

class VendorsNotifier extends StateNotifier<AsyncValue<List<AppUser>>> {
  final CatalogUseCases _useCases;

  VendorsNotifier(this._useCases) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _useCases.getVendors());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  List<AppUser> get _items => state.valueOrNull ?? const [];

  void upsertVendor(AppUser vendor) {
    final exists = _items.any((item) => item.id == vendor.id);
    state = AsyncData(
      exists
          ? [
              for (final item in _items)
                if (item.id == vendor.id) vendor else item,
            ]
          : [vendor, ..._items],
    );
  }
}

final vendorsProvider =
    StateNotifierProvider<VendorsNotifier, AsyncValue<List<AppUser>>>((ref) {
  return VendorsNotifier(ref.watch(catalogUseCasesProvider));
});

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
