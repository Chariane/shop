import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

class FavoritesNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final FavoritesRepository _repository;

  FavoritesNotifier(this._repository) : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await _repository.load();
      if (!mounted) return;
      state = AsyncData(ids);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<bool> toggle(String productId) async {
    final previous = state.valueOrNull ?? const <String>{};
    final next = {...previous};
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = AsyncData(next);
    try {
      await _repository.save(next);
      return next.contains(productId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<Set<String>>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider));
});

final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(favoritesProvider).maybeWhen(
        data: (ids) => ids.contains(productId),
        orElse: () => false,
      );
});

final favoritesCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider).maybeWhen(
        data: (ids) => ids.length,
        orElse: () => 0,
      );
});
