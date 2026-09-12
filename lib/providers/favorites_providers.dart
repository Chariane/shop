import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final FavoritesRepository _repository;

  FavoritesNotifier(this._repository) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    state = await _repository.load();
  }

  Future<void> toggle(String productId) async {
    final next = {...state};
    if (next.contains(productId)) {
      next.remove(productId);
    } else {
      next.add(productId);
    }
    state = next;
    await _repository.save(next);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider));
});

final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(favoritesProvider).contains(productId);
});