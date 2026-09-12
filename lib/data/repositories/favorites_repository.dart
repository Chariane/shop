import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const _storageKey = 'favorites_ids';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? const [];
    return ids.toSet();
  }

  Future<void> save(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, ids.toList()..sort());
  }
}
