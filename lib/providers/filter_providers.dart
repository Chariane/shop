import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product.dart';
import 'product_providers.dart';

enum SortOption {
  none('Pertinence'),
  priceAsc('Prix croissant'),
  priceDesc('Prix décroissant'),
  ratingDesc('Mieux notés'),
  newest('Nouveautés');

  final String label;
  const SortOption(this.label);
}

class FilterState {
  final String query;
  final String category;
  final SortOption sort;

  const FilterState({
    this.query = '',
    this.category = 'Tous',
    this.sort = SortOption.none,
  });

  FilterState copyWith({
    String? query,
    String? category,
    SortOption? sort,
  }) {
    return FilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      sort: sort ?? this.sort,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setQuery(String query) => state = state.copyWith(query: query);
  void setCategory(String category) =>
      state = state.copyWith(category: category);
  void setSort(SortOption sort) => state = state.copyWith(sort: sort);
  void reset() => state = const FilterState();
}

final filterProvider =
    StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(productsProvider);
  final filter = ref.watch(filterProvider);

  return products.whenData((list) {
    final result = list.where((p) {
      if (!p.isActive) return false;
      final matchQuery = filter.query.isEmpty ||
          p.name.toLowerCase().contains(filter.query.toLowerCase()) ||
          p.vendorName.toLowerCase().contains(filter.query.toLowerCase());
      final matchCategory =
          filter.category == 'Tous' || p.category == filter.category;
      return matchQuery && matchCategory;
    }).toList();

    switch (filter.sort) {
      case SortOption.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.ratingDesc:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.none:
        break;
    }
    return result;
  });
});
