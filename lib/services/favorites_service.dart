import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorites';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> addFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (!favorites.contains(word)) {
      favorites.add(word);
      await prefs.setStringList(_key, favorites);
    }
  }

  Future<void> removeFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.remove(word);
    await prefs.setStringList(_key, favorites);
  }

  Future<bool> isFavorite(String word) async {
    final favorites = await getFavorites();
    return favorites.contains(word);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
