import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/data_persistence_service.dart';

// Menu Notifier for API integration
class MenuNotifier extends StateNotifier<List<MenuItem>> {
  MenuNotifier() : super([]) {
    _loadFromCache();
  }

  final _dataPersistence = DataPersistenceService();

  // Load menu from cache first, then API
  Future<void> _loadFromCache() async {
    try {
      final cachedMenu = await _dataPersistence.loadMenu();
      if (cachedMenu.isNotEmpty) {
        state = cachedMenu;
        print('Loaded ${cachedMenu.length} menu items from cache');
      }
    } catch (e) {
      print('Error loading menu from cache: $e');
    }
  }

  // Load menu from API
  Future<void> loadFromApi() async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final menu = await apiService.getProducts(); // Updated to use getProducts
        state = menu;
        
        // Save to cache
        await _dataPersistence.saveMenu(menu);
        
        print('Successfully loaded ${menu.length} menu items from API and cached');
      }
    } catch (e) {
      print('Failed to load menu from API: $e');
      // Keep current state (from cache if available)
    }
  }

  // Load menu with fallback to cache
  Future<void> loadMenu() async {
    try {
      await loadFromApi();
    } catch (e) {
      print('API failed, using cached data: $e');
      await _loadFromCache();
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    await _dataPersistence.clearCache();
    state = [];
  }
}

// Provider
final menuProvider = StateNotifierProvider<MenuNotifier, List<MenuItem>>((ref) {
  return MenuNotifier();
});
