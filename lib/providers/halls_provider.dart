import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/data_persistence_service.dart';

class HallsNotifier extends StateNotifier<List<Hall>> {
  HallsNotifier() : super([]) {
    _loadFromCache();
  }

  final _dataPersistence = DataPersistenceService();

  // Load halls from cache first, then API
  Future<void> _loadFromCache() async {
    try {
      final cachedHalls = await _dataPersistence.loadHalls();
      if (cachedHalls.isNotEmpty) {
        state = cachedHalls;
        print('Loaded ${cachedHalls.length} halls from cache');
      }
    } catch (e) {
      print('Error loading halls from cache: $e');
    }
  }

  // Load halls from API
  Future<void> loadFromApi() async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final halls = await apiService.getHalls();
        state = halls;
        
        // Save to cache
        await _dataPersistence.saveHalls(halls);
        
        print('Successfully loaded ${halls.length} halls from API and cached');
      }
    } catch (e) {
      print('Failed to load halls from API: $e');
      // Keep current state (from cache if available)
    }
  }

  // Load halls with fallback to cache
  Future<void> loadHalls() async {
    try {
      await loadFromApi();
    } catch (e) {
      print('API failed, using cached data: $e');
      await _loadFromCache();
    }
  }

  void createHall(String name) {
    final newHall = Hall(
      id: 'hall_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      tables: [],
    );
    state = [...state, newHall];
    
    // Save to cache
    _dataPersistence.saveHalls(state);
  }

  Future<void> addTable(String hallId, String tableName) async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final newTable = await apiService.addTable(hallId, tableName);
        state = state.map((hall) {
          if (hall.id == hallId) {
            return hall.copyWith(tables: [...hall.tables, newTable]);
          }
          return hall;
        }).toList();
      } else {
        // Offline mode
        state = state.map((hall) {
          if (hall.id == hallId) {
            final newTable = TableInfo(
              id: 'table_${DateTime.now().millisecondsSinceEpoch}',
              name: tableName,
              status: TableStatus.free,
            );
            return hall.copyWith(tables: [...hall.tables, newTable]);
          }
          return hall;
        }).toList();
      }
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    } catch (e) {
      print('Failed to add table: $e');
      // Fallback to local operation
      state = state.map((hall) {
        if (hall.id == hallId) {
          final newTable = TableInfo(
            id: 'table_${DateTime.now().millisecondsSinceEpoch}',
            name: tableName,
            status: TableStatus.free,
          );
          return hall.copyWith(tables: [...hall.tables, newTable]);
        }
        return hall;
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    }
  }

  Future<void> setTableStatus(String tableId, TableStatus status) async {
    try {
      // Extract actual table ID if it's in hallId_tableId format
      final actualTableId = tableId.contains('_') ? tableId.split('_').last : tableId;
      
      final apiService = ApiService();
      if (apiService.isConfigured) {
        if (status == TableStatus.free) {
          // Use the specific free table endpoint
          await apiService.freeTable(actualTableId);
        } else {
          // For occupied status, use the regular update method
          String? waiterId;
          // Find current waiter for this table to maintain assignment
          for (final hall in state) {
            for (final table in hall.tables) {
              if (table.id == actualTableId && table.waiterId != null) {
                waiterId = table.waiterId;
                break;
              }
            }
          }
          await apiService.updateTableStatus(actualTableId, status, waiterId: waiterId);
        }
      }
      
      // Update local state
      state = state.map((hall) {
        final updatedTables = hall.tables.map((table) {
          if (table.id == actualTableId) {
            return table.copyWith(status: status);
          }
          return table;
        }).toList();
        return hall.copyWith(tables: updatedTables);
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    } catch (e) {
      print('Failed to update table status: $e');
      // Update local state anyway for offline mode
      final actualTableId = tableId.contains('_') ? tableId.split('_').last : tableId;
      state = state.map((hall) {
        final updatedTables = hall.tables.map((table) {
          if (table.id == actualTableId) {
            return table.copyWith(status: status);
          }
          return table;
        }).toList();
        return hall.copyWith(tables: updatedTables);
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    }
  }

  Future<void> assignWaiter(String tableId, String? waiterId) async {
    try {
      // Extract actual table ID if it's in hallId_tableId format
      final actualTableId = tableId.contains('_') ? tableId.split('_').last : tableId;
      
      final apiService = ApiService();
      if (apiService.isConfigured) {
        await apiService.updateTableStatus(actualTableId, TableStatus.occupied, waiterId: waiterId); // Updated to use updateTableStatus
      }
      
      // Update local state
      state = state.map((hall) {
        final updatedTables = hall.tables.map((table) {
          if (table.id == actualTableId) {
            return table.copyWith(waiterId: waiterId);
          }
          return table;
        }).toList();
        return hall.copyWith(tables: updatedTables);
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    } catch (e) {
      print('Failed to assign waiter: $e');
      // Update local state anyway for offline mode
      final actualTableId = tableId.contains('_') ? tableId.split('_').last : tableId;
      state = state.map((hall) {
        final updatedTables = hall.tables.map((table) {
          if (table.id == actualTableId) {
            return table.copyWith(waiterId: waiterId);
          }
          return table;
        }).toList();
        return hall.copyWith(tables: updatedTables);
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    }
  }

  Future<void> freeTable(String tableId) async {
    try {
      // Extract actual table ID if it's in hallId_tableId format
      final actualTableId = tableId.contains('_') ? tableId.split('_').last : tableId;
      
      final apiService = ApiService();
      if (apiService.isConfigured) {
        await apiService.freeTable(actualTableId);
      }
      
      // Update local state
      state = state.map((hall) {
        final updatedTables = hall.tables.map((table) {
          if (table.id == actualTableId) {
            return table.copyWith(status: TableStatus.free, waiterId: null);
          }
          return table;
        }).toList();
        return hall.copyWith(tables: updatedTables);
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    } catch (e) {
      print('Failed to free table: $e');
      // Update local state anyway for offline mode
      final actualTableId = tableId.contains('_') ? tableId.split('_').last : tableId;
      state = state.map((hall) {
        final updatedTables = hall.tables.map((table) {
          if (table.id == actualTableId) {
            return table.copyWith(status: TableStatus.free, waiterId: null);
          }
          return table;
        }).toList();
        return hall.copyWith(tables: updatedTables);
      }).toList();
      
      // Save to cache
      await _dataPersistence.saveHalls(state);
    }
  }

  void renameTable(String tableId, String newName) {
    state = state.map((hall) {
      final updatedTables = hall.tables.map((table) {
        if (table.id == tableId) {
          return table.copyWith(name: newName);
        }
        return table;
      }).toList();
      return hall.copyWith(tables: updatedTables);
    }).toList();
    
    // Save to cache
    _dataPersistence.saveHalls(state);
  }

  // Clear cache
  Future<void> clearCache() async {
    await _dataPersistence.clearCache();
    state = [];
  }
}

// Provider
final hallsProvider = StateNotifierProvider<HallsNotifier, List<Hall>>((ref) {
  return HallsNotifier();
});
