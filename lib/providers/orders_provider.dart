import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/base_api_service.dart';

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super([]);

  // Load orders for a specific table from API
  Future<void> loadTableOrders(String tableId) async {
    try {
      print('Loading table orders for tableId: $tableId');
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final orders = await apiService.getTableOrders(tableId);
        print('Received ${orders.length} orders from API for table $tableId');
        state = orders;
        print('State updated with ${state.length} orders');
      } else {
        print('API service not configured');
      }
    } catch (e) {
      print('Failed to load orders from API: $e');
      // Keep using current state for offline mode
    }
  }

  Future<void> createOrder(String tableId) async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final newOrder = await apiService.createOrder(tableId);
        state = [...state, newOrder];
      } else {
        // Offline mode
        final order = Order(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tableId: tableId,
          items: [],
          status: OrderStatus.open,
          createdAt: DateTime.now(),
        );
        state = [...state, order];
      }
    } catch (e) {
      print('Failed to create order: $e');
      // Fallback to local operation
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tableId: tableId,
        items: [],
        status: OrderStatus.open,
        createdAt: DateTime.now(),
      );
      state = [...state, order];
    }
  }

  Future<void> addItemToOrder(String tableId, MenuItem menuItem, {int quantity = 1, String? comment}) async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        // Add item to TempTav via API
        print('🌐 Adding item to TempTav: ${menuItem.name} x$quantity');
        await apiService.addItemToOrder(tableId, menuItem.id, quantity, comment);
        
        // Immediately reload table orders to get updated TempTav items with server-assigned IDs
        print('🔄 Reloading table orders to get updated TempTav IDs...');
        await loadTableOrders(tableId);
        print('✅ Table orders reloaded with TempTav IDs');
        return;
      }
      
      // Fallback for offline mode - only add locally
      _addItemLocallyOnly(tableId, menuItem, quantity, comment);
    } catch (e) {
      print('Failed to add item to order via API: $e');
      // Fallback to local operation
      _addItemLocallyOnly(tableId, menuItem, quantity, comment);
    }
  }

  void _addItemLocallyOnly(String tableId, MenuItem menuItem, int quantity, String? comment) {
    // Find the open order for this table or create one
    var openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;
    
    if (openOrder == null) {
      // Create a new local order if none exists
      final newOrder = Order.withTimestamp(
        id: 'temp_$tableId',
        tableId: tableId,
        items: [],
        status: OrderStatus.open,
        timestamp: DateTime.now(),
      );
      state = [...state, newOrder];
    }
    
    // Add item to local state - new items go first (most recent at top)
    state = state.map((order) {
      if (order.tableId == tableId && order.status == OrderStatus.open) {
        final orderItem = OrderItem(
          name: menuItem.name,
          price: menuItem.price,
          quantity: quantity,
          comment: comment,
        );
        return order.copyWith(items: [orderItem, ...order.items]); // Add new items on top
      }
      return order;
    }).toList();
  }

  Future<void> removeOrderItem(String tableId, int itemIndex) async {
    print('🗑️ removeOrderItem called for tableId: $tableId, itemIndex: $itemIndex');
    
    try {
      // Find the open order for this table
      final openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;
      
      if (openOrder != null && itemIndex < openOrder.items.length) {
        final itemToRemove = openOrder.items[itemIndex];
        print('📦 Item to remove: ${itemToRemove.name} (ID: ${itemToRemove.id})');
        
        final apiService = ApiService();
        bool serverDeletionAttempted = false;
        bool serverDeletionSuccessful = false;
        
        if (apiService.isConfigured && itemToRemove.id != null && itemToRemove.id!.isNotEmpty) {
          // Use individual TempTav deletion for items with TempTav IDs
          final tempTavId = int.tryParse(itemToRemove.id!);
          if (tempTavId != null) {
            print('🌐 Calling deleteTempOrder for TempTav ID: $tempTavId');
            serverDeletionAttempted = true;
            try {
              await apiService.deleteTempOrder(tempTavId);
              serverDeletionSuccessful = true;
              print('✅ Successfully deleted TempTav order from server');
            } catch (deleteError) {
              print('❌ Failed to delete TempTav order from server: $deleteError');
              // Continue with local deletion
            }
          } else {
            print('❌ Could not parse TempTav ID: ${itemToRemove.id}');
          }
        } else {
          if (!apiService.isConfigured) {
            print('⚠️ API not configured, removing locally only');
          } else if (itemToRemove.id == null || itemToRemove.id!.isEmpty) {
            print('⚠️ Item has no server ID, removing locally only');
          }
        }
        
        // Update local state regardless of server deletion result
        state = state.map((order) {
          if (order.tableId == tableId && order.status == OrderStatus.open) {
            final updatedItems = List<OrderItem>.from(order.items);
            if (itemIndex < updatedItems.length) {
              updatedItems.removeAt(itemIndex);
            }
            return order.copyWith(items: updatedItems);
          }
          return order;
        }).toList();
        
        print('✅ Local state updated, remaining items: ${openOrder.items.length - 1}');
        
        // If server deletion was attempted and successful, reload to ensure consistency
        if (serverDeletionAttempted && serverDeletionSuccessful) {
          print('🔄 Reloading table orders to ensure consistency after server deletion...');
          await loadTableOrders(tableId);
          print('✅ Table orders reloaded after server deletion');
        }
      } else {
        print('❌ No open order found or invalid item index');
      }
    } catch (e) {
      print('❌ Failed to remove order item: $e');
      // Fallback to local operation
      state = state.map((order) {
        if (order.tableId == tableId && order.status == OrderStatus.open) {
          final updatedItems = List<OrderItem>.from(order.items);
          if (itemIndex < updatedItems.length) {
            updatedItems.removeAt(itemIndex);
          }
          return order.copyWith(items: updatedItems);
        }
        return order;
      }).toList();
    }
  }

  Future<void> updateOrderItemComment(String tableId, int itemIndex, String comment) async {
    try {
      // Find the open order for this table
      final openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;
      
      if (openOrder != null) {
        final apiService = ApiService();
        if (apiService.isConfigured) {
          final currentItem = openOrder.items[itemIndex];
          await apiService.updateOrderItem(openOrder.id, itemIndex, currentItem.quantity, comment);
        }
        
        // Update local state
        state = state.map((order) {
          if (order.tableId == tableId && order.status == OrderStatus.open) {
            final updatedItems = List<OrderItem>.from(order.items);
            if (itemIndex < updatedItems.length) {
              updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(comment: comment);
            }
            return order.copyWith(items: updatedItems);
          }
          return order;
        }).toList();
      }
    } catch (e) {
      print('Failed to update order item comment: $e');
      // Fallback to local operation
      state = state.map((order) {
        if (order.tableId == tableId && order.status == OrderStatus.open) {
          final updatedItems = List<OrderItem>.from(order.items);
          if (itemIndex < updatedItems.length) {
            updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(comment: comment);
          }
          return order.copyWith(items: updatedItems);
        }
        return order;
      }).toList();
    }
  }

  Future<void> updateOrderItemQuantity(String tableId, int itemIndex, int quantity) async {
    try {
      // Find the open order for this table
      final openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;
      
      if (openOrder != null) {
        final apiService = ApiService();
        if (apiService.isConfigured) {
          final currentItem = openOrder.items[itemIndex];
          await apiService.updateOrderItem(openOrder.id, itemIndex, quantity, currentItem.comment);
        }
        
        // Update local state
        state = state.map((order) {
          if (order.tableId == tableId && order.status == OrderStatus.open) {
            final updatedItems = List<OrderItem>.from(order.items);
            if (itemIndex < updatedItems.length) {
              updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(quantity: quantity);
            }
            return order.copyWith(items: updatedItems);
          }
          return order;
        }).toList();
      }
    } catch (e) {
      print('Failed to update order item quantity: $e');
      // Fallback to local operation
      state = state.map((order) {
        if (order.tableId == tableId && order.status == OrderStatus.open) {
          final updatedItems = List<OrderItem>.from(order.items);
          if (itemIndex < updatedItems.length) {
            updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(quantity: quantity);
          }
          return order.copyWith(items: updatedItems);
        }
        return order;
      }).toList();
    }
  }

  Future<void> closeOrder(String orderId) async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        await apiService.deleteOrder(orderId);
      }
      
      // Update local state - remove the order since it's deleted
      state = state.where((order) => order.id != orderId).toList();
    } catch (e) {
      print('Failed to close order: $e');
      // Fallback to local operation - mark as closed
      state = state
          .map((order) => order.id == orderId ? order.copyWith(status: OrderStatus.closed) : order)
          .toList();
    }
  }

  Future<void> printOrder(String orderId) async {
    print('🖨️ printOrder called for orderId: $orderId');
    
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        print('✅ API service is configured');
        
        // For TempTav orders, use the batch order flow
        if (orderId.startsWith('temp_')) {
          print('📦 Processing temp order - extracting tableId...');
          final tableId = orderId.substring(5);
          print('📍 TableId extracted: $tableId');
          
          print('🚀 Calling createBatchOrder...');
          await apiService.createBatchOrder(tableId);
          print('✅ createBatchOrder completed');
          
          // Remove the temp order from local state since it's now converted to a real order
          print('🗑️ Removing temp order from local state...');
          state = state.where((order) => order.id != orderId).toList();
          print('✅ Temp order removed from state');
          
          // Reload orders to get the newly created order from the API
          print('🔄 Reloading table orders...');
          await loadTableOrders(tableId);
          print('✅ Table orders reloaded');
        } else {
          print('📋 Processing real order - updating status...');
          // For real orders, try to update status (though this might not be supported)
          await apiService.updateOrderStatus(orderId, OrderStatus.printed);
          
          // Update local state
          state = state
              .map((order) => order.id == orderId ? order.copyWith(status: OrderStatus.printed) : order)
              .toList();
          print('✅ Real order status updated');
        }
      } else {
        print('❌ API service is not configured');
      }
    } catch (e) {
      print('❌ Failed to print order: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is ApiException) {
        print('❌ API Exception details: ${e.message}');
      }
      // For temp orders, still try to mark as printed locally
      if (orderId.startsWith('temp_')) {
        // Keep the temp order but mark as printed
        state = state
            .map((order) => order.id == orderId ? order.copyWith(status: OrderStatus.printed) : order)
            .toList();
      } else {
        // Fallback to local operation for real orders
        state = state
            .map((order) => order.id == orderId ? order.copyWith(status: OrderStatus.printed) : order)
            .toList();
      }
    }
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  return OrdersNotifier();
});
