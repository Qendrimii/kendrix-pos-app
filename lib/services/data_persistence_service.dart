import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class DataPersistenceService {
  static final DataPersistenceService _instance = DataPersistenceService._internal();
  factory DataPersistenceService() => _instance;
  DataPersistenceService._internal();

  static const String _hallsKey = 'cached_halls';
  static const String _menuKey = 'cached_menu';
  static const String _waitersKey = 'cached_waiters';
  static const String _ordersKey = 'cached_orders';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Save halls data
  Future<void> saveHalls(List<Hall> halls) async {
    final prefs = await SharedPreferences.getInstance();
    final hallsJson = halls.map((hall) => hall.toJson()).toList();
    await prefs.setString(_hallsKey, json.encode(hallsJson));
    await _updateLastSync();
  }

  // Load halls data
  Future<List<Hall>> loadHalls() async {
    final prefs = await SharedPreferences.getInstance();
    final hallsString = prefs.getString(_hallsKey);
    if (hallsString != null) {
      try {
        final hallsJson = json.decode(hallsString) as List;
        return hallsJson.map((json) => Hall.fromJson(json)).toList();
      } catch (e) {
        print('Error loading halls from cache: $e');
        return [];
      }
    }
    return [];
  }

  // Save menu data
  Future<void> saveMenu(List<MenuItem> menu) async {
    final prefs = await SharedPreferences.getInstance();
    final menuJson = menu.map((item) => item.toJson()).toList();
    await prefs.setString(_menuKey, json.encode(menuJson));
    await _updateLastSync();
  }

  // Load menu data
  Future<List<MenuItem>> loadMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final menuString = prefs.getString(_menuKey);
    if (menuString != null) {
      try {
        final menuJson = json.decode(menuString) as List;
        return menuJson.map((json) => MenuItem.fromJson(json)).toList();
      } catch (e) {
        print('Error loading menu from cache: $e');
        return [];
      }
    }
    return [];
  }

  // Save waiters data
  Future<void> saveWaiters(List<Waiter> waiters) async {
    final prefs = await SharedPreferences.getInstance();
    final waitersJson = waiters.map((waiter) => waiter.toJson()).toList();
    await prefs.setString(_waitersKey, json.encode(waitersJson));
    await _updateLastSync();
  }

  // Load waiters data
  Future<List<Waiter>> loadWaiters() async {
    final prefs = await SharedPreferences.getInstance();
    final waitersString = prefs.getString(_waitersKey);
    if (waitersString != null) {
      try {
        final waitersJson = json.decode(waitersString) as List;
        return waitersJson.map((json) => Waiter.fromJson(json)).toList();
      } catch (e) {
        print('Error loading waiters from cache: $e');
        return [];
      }
    }
    return [];
  }

  // Save orders data
  Future<void> saveOrders(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final ordersJson = orders.map((order) => order.toJson()).toList();
    await prefs.setString(_ordersKey, json.encode(ordersJson));
    await _updateLastSync();
  }

  // Load orders data
  Future<List<Order>> loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersString = prefs.getString(_ordersKey);
    if (ordersString != null) {
      try {
        final ordersJson = json.decode(ordersString) as List;
        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } catch (e) {
        print('Error loading orders from cache: $e');
        return [];
      }
    }
    return [];
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Update last sync timestamp
  Future<void> _updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Clear all cached data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hallsKey);
    await prefs.remove(_menuKey);
    await prefs.remove(_waitersKey);
    await prefs.remove(_ordersKey);
    await prefs.remove(_lastSyncKey);
  }

  // Check if cache is stale (older than 1 hour)
  Future<bool> isCacheStale() async {
    final lastSync = await getLastSync();
    if (lastSync == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inHours >= 1;
  }

  // Get cache size info
  Future<Map<String, int>> getCacheInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'halls': prefs.getString(_hallsKey)?.length ?? 0,
      'menu': prefs.getString(_menuKey)?.length ?? 0,
      'waiters': prefs.getString(_waitersKey)?.length ?? 0,
      'orders': prefs.getString(_ordersKey)?.length ?? 0,
    };
  }
}
