import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/data_persistence_service.dart';

// Waiters Notifier for API integration
class WaitersNotifier extends StateNotifier<List<Waiter>> {
  WaitersNotifier() : super(_defaultWaiters) {
    _loadFromCache();
  }

  final _dataPersistence = DataPersistenceService();

  // Default waiters for offline/fallback mode
  static final List<Waiter> _defaultWaiters = [
    const Waiter(id: '1', name: 'Alice', color: Color(0xFF00BCD4), pin: '1111'), // Modern Cyan
    const Waiter(id: '2', name: 'Bob', color: Color(0xFF3F51B5), pin: '2222'), // Indigo
    const Waiter(id: '3', name: 'Charlie', color: Color(0xFFFF5722), pin: '3333'), // Deep Orange
    const Waiter(id: '4', name: 'Diana', color: Color(0xFF8BC34A), pin: '4444'), // Light Green
    const Waiter(id: '5', name: 'Emma', color: Color(0xFFE91E63), pin: '5555'), // Pink
    const Waiter(id: '6', name: 'Frank', color: Color(0xFF673AB7), pin: '6666'), // Deep Purple
    const Waiter(id: '7', name: 'Grace', color: Color(0xFF009688), pin: '7777'), // Teal
    const Waiter(id: '8', name: 'Henry', color: Color(0xFFFF6F00), pin: '8888'), // Amber
  ];

  // Load waiters from cache first, then API
  Future<void> _loadFromCache() async {
    try {
      final cachedWaiters = await _dataPersistence.loadWaiters();
      if (cachedWaiters.isNotEmpty) {
        state = cachedWaiters;
        print('Loaded ${cachedWaiters.length} waiters from cache');
      }
    } catch (e) {
      print('Error loading waiters from cache: $e');
    }
  }

  // Load waiters from API
  Future<void> loadFromApi() async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        // Since the API doesn't have a waiters endpoint, we'll skip API loading
        // and keep using the default waiters
        print('Waiters loaded from local data (API endpoint not available)');
        
        // Save current waiters to cache
        await _dataPersistence.saveWaiters(state);
      }
    } catch (e) {
      print('Failed to load waiters from API: $e');
      // Keep using default/current state
    }
  }

  // Load waiters with fallback to cache
  Future<void> loadWaiters() async {
    try {
      await loadFromApi();
    } catch (e) {
      print('API failed, using cached data: $e');
      await _loadFromCache();
    }
  }

  // Add a new waiter
  void addWaiter(Waiter waiter) {
    state = [...state, waiter];
    _dataPersistence.saveWaiters(state);
  }

  // Update a waiter
  void updateWaiter(String id, Waiter updatedWaiter) {
    state = state.map((waiter) {
      if (waiter.id == id) {
        return updatedWaiter;
      }
      return waiter;
    }).toList();
    _dataPersistence.saveWaiters(state);
  }

  // Remove a waiter
  void removeWaiter(String id) {
    state = state.where((waiter) => waiter.id != id).toList();
    _dataPersistence.saveWaiters(state);
  }

  // Clear cache
  Future<void> clearCache() async {
    await _dataPersistence.clearCache();
    state = _defaultWaiters;
  }
}

// Provider
final waitersProvider = StateNotifierProvider<WaitersNotifier, List<Waiter>>((ref) {
  return WaitersNotifier();
});
