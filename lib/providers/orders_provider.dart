import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/base_api_service.dart';

/// Result class for order operations to properly communicate success/failure
class OrderOperationResult {
  final bool success;
  final String? errorMessage;
  final bool isNetworkError;

  OrderOperationResult({
    required this.success,
    this.errorMessage,
    this.isNetworkError = false,
  });

  factory OrderOperationResult.successful() => OrderOperationResult(success: true);

  factory OrderOperationResult.failed(String message, {bool isNetworkError = false}) =>
    OrderOperationResult(success: false, errorMessage: message, isNetworkError: isNetworkError);
}

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super([]);

  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);

  /// Helper method to execute API calls with retry logic
  Future<T> _executeWithRetry<T>(
    Future<T> Function() apiCall, {
    int retries = maxRetries,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < retries) {
      try {
        return await apiCall();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;
        print('API call failed (attempt $attempts/$retries): $e');

        if (attempts < retries) {
          await Future.delayed(retryDelay * attempts);
        }
      }
    }

    throw lastException ?? Exception('API call failed after $retries attempts');
  }

  // Load orders for a specific table from API
  Future<void> loadTableOrders(String tableId) async {
    try {
      print('Loading table orders for tableId: $tableId');
      final apiService = ApiService();
      if (apiService.isConfigured) {
        final orders = await _executeWithRetry(
          () => apiService.getTableOrders(tableId),
        );
        print('Received ${orders.length} orders from API for table $tableId');
        state = orders;
        print('State updated with ${state.length} orders');
      } else {
        print('API service not configured');
      }
    } catch (e) {
      print('Failed to load orders from API: $e');
      // Keep using current state for offline mode - but log the error
    }
  }

  /// Creates an order - returns result indicating success/failure
  /// IMPORTANT: No longer silently falls back to local-only mode
  Future<OrderOperationResult> createOrder(String tableId) async {
    try {
      final apiService = ApiService();
      if (!apiService.isConfigured) {
        return OrderOperationResult.failed(
          'API not configured. Please check your connection settings.',
          isNetworkError: true,
        );
      }

      final newOrder = await _executeWithRetry(
        () => apiService.createOrder(tableId),
      );
      state = [...state, newOrder];
      return OrderOperationResult.successful();
    } catch (e) {
      print('Failed to create order: $e');
      return OrderOperationResult.failed(
        'Failed to create order: ${_getErrorMessage(e)}',
        isNetworkError: _isNetworkError(e),
      );
    }
  }

  /// Adds item to order - returns result indicating success/failure
  /// CRITICAL FIX: No longer silently falls back to local-only mode
  Future<OrderOperationResult> addItemToOrder(String tableId, MenuItem menuItem, {int quantity = 1, String? comment}) async {
    try {
      final apiService = ApiService();
      if (!apiService.isConfigured) {
        return OrderOperationResult.failed(
          'API not configured. Please check your connection settings.',
          isNetworkError: true,
        );
      }

      // Add item to TempTav via API with retry logic
      print('Adding item to TempTav: ${menuItem.name} x$quantity');
      await _executeWithRetry(
        () => apiService.addItemToOrder(tableId, menuItem.id, quantity, comment),
      );

      // Immediately reload table orders to get updated TempTav items with server-assigned IDs
      print('Reloading table orders to get updated TempTav IDs...');
      await loadTableOrders(tableId);
      print('Table orders reloaded with TempTav IDs');

      return OrderOperationResult.successful();
    } catch (e) {
      print('Failed to add item to order via API: $e');

      // CRITICAL: Do NOT fall back to local-only mode
      // This would cause the item to appear in UI but not be on server
      return OrderOperationResult.failed(
        'Failed to add item: ${_getErrorMessage(e)}',
        isNetworkError: _isNetworkError(e),
      );
    }
  }

  /// Removes an item from the order
  Future<OrderOperationResult> removeOrderItem(String tableId, int itemIndex) async {
    print('removeOrderItem called for tableId: $tableId, itemIndex: $itemIndex');

    try {
      // Find the open order for this table
      final openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;

      if (openOrder == null || itemIndex >= openOrder.items.length) {
        return OrderOperationResult.failed('No open order found or invalid item index');
      }

      final itemToRemove = openOrder.items[itemIndex];
      print('Item to remove: ${itemToRemove.name} (ID: ${itemToRemove.id})');

      final apiService = ApiService();

      if (apiService.isConfigured && itemToRemove.id != null && itemToRemove.id!.isNotEmpty) {
        // Use individual TempTav deletion for items with TempTav IDs
        final tempTavId = int.tryParse(itemToRemove.id!);
        if (tempTavId != null) {
          print('Calling deleteTempOrder for TempTav ID: $tempTavId');
          try {
            await _executeWithRetry(
              () => apiService.deleteTempOrder(tempTavId),
            );
            print('Successfully deleted TempTav order from server');

            // Reload to ensure consistency after server deletion
            await loadTableOrders(tableId);
            return OrderOperationResult.successful();
          } catch (deleteError) {
            print('Failed to delete TempTav order from server: $deleteError');
            return OrderOperationResult.failed(
              'Failed to remove item: ${_getErrorMessage(deleteError)}',
              isNetworkError: _isNetworkError(deleteError),
            );
          }
        } else {
          print('Could not parse TempTav ID: ${itemToRemove.id}');
        }
      }

      // If item has no server ID or API not configured, just update local state
      // This is acceptable for items that were never saved to server
      if (itemToRemove.id == null || itemToRemove.id!.isEmpty) {
        print('Item has no server ID, removing locally only');
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
        return OrderOperationResult.successful();
      }

      return OrderOperationResult.failed('Unable to remove item');
    } catch (e) {
      print('Failed to remove order item: $e');
      return OrderOperationResult.failed(
        'Failed to remove item: ${_getErrorMessage(e)}',
        isNetworkError: _isNetworkError(e),
      );
    }
  }

  Future<OrderOperationResult> updateOrderItemComment(String tableId, int itemIndex, String comment) async {
    try {
      // Find the open order for this table
      final openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;

      if (openOrder == null) {
        return OrderOperationResult.failed('No open order found');
      }

      final apiService = ApiService();
      if (apiService.isConfigured) {
        final currentItem = openOrder.items[itemIndex];
        await _executeWithRetry(
          () => apiService.updateOrderItem(openOrder.id, itemIndex, currentItem.quantity, comment),
        );
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

      return OrderOperationResult.successful();
    } catch (e) {
      print('Failed to update order item comment: $e');
      // For comments, we can still update locally as it's not critical
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
      return OrderOperationResult.successful(); // Comment update is not critical
    }
  }

  Future<OrderOperationResult> updateOrderItemQuantity(String tableId, int itemIndex, int quantity) async {
    try {
      // Find the open order for this table
      final openOrder = state.where((order) => order.tableId == tableId && order.status == OrderStatus.open).firstOrNull;

      if (openOrder == null) {
        return OrderOperationResult.failed('No open order found');
      }

      final apiService = ApiService();
      if (apiService.isConfigured) {
        final currentItem = openOrder.items[itemIndex];
        await _executeWithRetry(
          () => apiService.updateOrderItem(openOrder.id, itemIndex, quantity, currentItem.comment),
        );
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

      return OrderOperationResult.successful();
    } catch (e) {
      print('Failed to update order item quantity: $e');
      return OrderOperationResult.failed(
        'Failed to update quantity: ${_getErrorMessage(e)}',
        isNetworkError: _isNetworkError(e),
      );
    }
  }

  Future<OrderOperationResult> closeOrder(String orderId) async {
    try {
      final apiService = ApiService();
      if (apiService.isConfigured) {
        await _executeWithRetry(
          () => apiService.deleteOrder(orderId),
        );
      }

      // Update local state - remove the order since it's deleted
      state = state.where((order) => order.id != orderId).toList();
      return OrderOperationResult.successful();
    } catch (e) {
      print('Failed to close order: $e');
      return OrderOperationResult.failed(
        'Failed to close order: ${_getErrorMessage(e)}',
        isNetworkError: _isNetworkError(e),
      );
    }
  }

  /// Prints an order to kitchen
  /// CRITICAL FIX: Now properly validates success and doesn't mark as printed on failure
  Future<OrderOperationResult> printOrder(String orderId) async {
    print('printOrder called for orderId: $orderId');

    try {
      final apiService = ApiService();
      if (!apiService.isConfigured) {
        return OrderOperationResult.failed(
          'API not configured. Please check your connection settings.',
          isNetworkError: true,
        );
      }

      print('API service is configured');

      // For TempTav orders, use the batch order flow
      if (orderId.startsWith('temp_')) {
        print('Processing temp order - extracting tableId...');
        final tableId = orderId.substring(5);
        print('TableId extracted: $tableId');

        print('Calling createBatchOrder with retry...');
        final result = await _executeWithRetry(
          () => apiService.createBatchOrder(tableId),
        );
        print('createBatchOrder completed: $result');

        // CRITICAL: Validate the response properly
        final success = result['success'] == true;
        final message = result['message']?.toString() ?? '';

        // Check if there was a save error in the response
        if (message.toLowerCase().contains('save failed') ||
            message.toLowerCase().contains('database') ||
            message.toLowerCase().contains('critical')) {
          print('CRITICAL: Batch order response indicates save failure: $message');
          return OrderOperationResult.failed(
            'Order printed but may not have been saved: $message. Please verify.',
            isNetworkError: false,
          );
        }

        if (!success && result['error'] != null) {
          print('Batch order failed: ${result['error']}');
          return OrderOperationResult.failed(
            'Failed to print order: ${result['error']}',
            isNetworkError: false,
          );
        }

        // Only remove from local state and mark as printed if confirmed successful
        print('Removing temp order from local state...');
        state = state.where((order) => order.id != orderId).toList();
        print('Temp order removed from state');

        // Reload orders to get the newly created order from the API
        print('Reloading table orders...');
        await loadTableOrders(tableId);
        print('Table orders reloaded');

        return OrderOperationResult.successful();
      } else {
        print('Processing real order - updating status...');
        // For real orders, try to update status
        await _executeWithRetry(
          () => apiService.updateOrderStatus(orderId, OrderStatus.printed),
        );

        // Update local state only after confirmed success
        state = state
            .map((order) => order.id == orderId ? order.copyWith(status: OrderStatus.printed) : order)
            .toList();
        print('Real order status updated');

        return OrderOperationResult.successful();
      }
    } catch (e) {
      print('Failed to print order: $e');
      print('Error type: ${e.runtimeType}');
      if (e is ApiException) {
        print('API Exception details: ${e.message}');
      }

      // CRITICAL FIX: Do NOT mark as printed on failure
      // The previous code was marking orders as printed even when the API failed
      // This caused orders to appear "sent" when they weren't actually saved

      return OrderOperationResult.failed(
        'Failed to print order: ${_getErrorMessage(e)}',
        isNetworkError: _isNetworkError(e),
      );
    }
  }

  /// Helper to extract user-friendly error message
  String _getErrorMessage(dynamic e) {
    if (e is ApiException) {
      return e.message;
    } else if (e is Exception) {
      final msg = e.toString();
      // Clean up common exception prefixes
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    }
    return e.toString();
  }

  /// Helper to determine if error is network-related
  bool _isNetworkError(dynamic e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
           msg.contains('connection') ||
           msg.contains('timeout') ||
           msg.contains('network') ||
           msg.contains('host') ||
           msg.contains('refused');
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  return OrdersNotifier();
});
