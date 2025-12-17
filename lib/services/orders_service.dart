import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_api_service.dart';

class OrdersService extends BaseApiService {
  // Order Operations - Following TechTrek POS workflow
  static Future<List<Map<String, dynamic>>> getTempOrders(String tableId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // Use the TempTav API endpoint for current orders
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/TempTav/table/$tableId'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    print('Raw TempTav response for table $tableId: $data');
    
    // Handle different response formats
    if (data is Map && data.containsKey('data')) {
      // Handle case where data field might be a string representation of JSON
      if (data['data'] is String) {
        try {
          final parsedData = json.decode(data['data'] as String);
          if (parsedData is List) {
            final result = (parsedData as List).cast<Map<String, dynamic>>();
            return result;
          }
        } catch (e) {
          // Fall through to other parsing methods
        }
      }
    }
    
    if (data is List) {
      final result = (data as List).cast<Map<String, dynamic>>();
      return result;
    } else if (data is Map && data.containsKey('data')) {
      if (data['data'] is List) {
        final result = (data['data'] as List).cast<Map<String, dynamic>>();
        return result;
      } else if (data['data'] == null) {
        return [];
      }
    } else if (data is Map && data.containsKey('success') && data['success'] == true) {
      // Handle case where API returns {success: true} with no data key
      return [];
    }
    
    // Return empty list if no orders
    return [];
  }

  static Future<Map<String, dynamic>> addTempOrder(String tableId, int productId, double quantity, {String? notes}) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // Use the TempTav API endpoint for adding items
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/TempTav/table/$tableId/add'),
      headers: BaseApiService.headers,
      body: json.encode({
        'tableId': tableId,
        'productId': productId,
        'quantity': quantity,
        'options': notes ?? '',
      }),
    );
    
    return BaseApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateTempOrder(int tempOrderId, double quantity, {String? notes}) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.put(
      Uri.parse('${BaseApiService.baseUrl}/api/temp-orders/$tempOrderId'),
      headers: BaseApiService.headers,
      body: json.encode({
        'quantity': quantity,
        'notes': notes ?? '',
      }),
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to update temporary order');
  }

  static Future<Map<String, dynamic>> getTempOrderTotal(String tableId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/temp-orders/$tableId/total'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to calculate temporary order total');
  }

  static Future<bool> clearTempOrders(String tableId) async {
    print('🧹 clearTempOrders called for tableId: $tableId');
    
    if (!BaseApiService.isConfigured) {
      print('❌ API not configured for clearTempOrders');
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    print('🌐 Sending DELETE to /api/TempTav/table/$tableId/clear...');
    final response = await http.delete(
      Uri.parse('${BaseApiService.baseUrl}/api/TempTav/table/$tableId/clear'),
      headers: BaseApiService.headers,
    );
    
    print('📨 Clear response status: ${response.statusCode}');
    print('📨 Clear response body: ${response.body}');
    
    final data = BaseApiService.handleResponse(response);
    final success = data['success'] == true;
    print('✅ Clear TempTav result: $success');
    return success;
  }

  // Delete individual TempTav order by ID
  static Future<bool> deleteTempOrder(int orderId) async {
    print('🗑️ deleteTempOrder called for orderId: $orderId');
    
    if (!BaseApiService.isConfigured) {
      print('❌ API not configured for deleteTempOrder');
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    print('🌐 Sending DELETE to /api/TempTav/$orderId...');
    final response = await http.delete(
      Uri.parse('${BaseApiService.baseUrl}/api/TempTav/$orderId'),
      headers: BaseApiService.headers,
    );
    
    print('📨 Delete response status: ${response.statusCode}');
    print('📨 Delete response body: ${response.body}');
    
    final data = BaseApiService.handleResponse(response);
    final success = data['success'] == true;
    print('✅ Delete TempTav result: $success');
    return success;
  }

  // Legacy/Backward Compatibility Methods - For existing code
  static Future<List<Order>> getOrdersByTable(String tableId) async {
    // Get both current (TempTav) and previous (Orders) data
    try {
      List<Order> allOrders = [];
      
      // Get current orders from TempTav
      final tempOrders = await getTempOrders(tableId);
      print('TempTav orders for table $tableId: $tempOrders');
      
      if (tempOrders.isNotEmpty) {
        // Group TempTav items into a single Order object - reverse to show most recent first
        final orderItems = tempOrders.reversed.map((tempOrder) {
          return OrderItem(
            id: tempOrder['id']?.toString(), // Preserve TempTav ID for individual deletion
            name: tempOrder['productName'] ?? tempOrder['name'] ?? 'Unknown Item',
            price: (tempOrder['cmimi'] ?? tempOrder['price'] ?? 0.0).toDouble(),
            quantity: (tempOrder['sasia'] ?? tempOrder['quantity'] ?? 1.0).toInt(),
            comment: tempOrder['opsionet'] ?? tempOrder['options'] ?? tempOrder['notes'],
          );
        }).toList();
        
        allOrders.add(Order(
          id: 'temp_$tableId',
          tableId: tableId,
          items: orderItems,
          status: OrderStatus.open,
          createdAt: DateTime.now(),
        ));
      }
      
      // Get previous orders from Orders API
      try {
        final response = await http.get(
          Uri.parse('${BaseApiService.baseUrl}/api/Orders/table/$tableId'),
          headers: BaseApiService.headers,
        );
        
        final data = BaseApiService.handleResponse(response);
        
        if (data is List) {
          final previousOrders = (data as List)
              .map((json) => _convertApiOrderToOrder(json as Map<String, dynamic>))
              .toList();
          allOrders.addAll(previousOrders);
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          final previousOrders = (data['data'] as List)
              .map((json) => _convertApiOrderToOrder(json as Map<String, dynamic>))
              .toList();
          allOrders.addAll(previousOrders);
        }
      } catch (e) {
        print('Failed to load previous orders: $e');
      }
      
      print('Total orders loaded for table $tableId: ${allOrders.length}');
      for (var order in allOrders) {
        print('Order ${order.id}: ${order.items.length} items, status: ${order.status}');
      }
      
      return allOrders;
    } catch (e) {
      return [];
    }
  }

  // Helper method to convert API order format to our Order model
  static Order _convertApiOrderToOrder(Map<String, dynamic> json) {
    // Each API "order" is actually a single item
    final orderItem = OrderItem(
      name: json['productName'] ?? 'Unknown Item',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 1.0).toInt(),
      comment: json['notes'] ?? '',
    );

    final apiTotal = (json['total'] as num?)?.toDouble();
    print('📊 Converting API order ${json['id']}: ${json['productName']} - API total: $apiTotal');

    return Order(
      id: json['id'].toString(),
      tableId: json['tableId']?.toString() ?? '',
      items: [orderItem], // Single item per order from API
      status: json['status'] == 'open' ? OrderStatus.open : OrderStatus.closed,
      createdAt: json['orderTime'] != null 
          ? DateTime.tryParse(json['orderTime']) ?? DateTime.now()
          : DateTime.now(),
      apiTotal: apiTotal, // Use API-provided total
    );
  }

  static Future<List<Order>> getTableOrders(String tableId) async {
    return await getOrdersByTable(tableId);
  }

  static Future<Order> createOrder(String tableId) async {
    // For TempTav workflow, we don't need to create an order upfront
    return Order(
      id: 'temp_$tableId',
      tableId: tableId,
      items: [],
      status: OrderStatus.open,
      createdAt: DateTime.now(),
    );
  }

  static Future<Order> addItemToOrder(String tableId, String menuItemId, int quantity, String? comment) async {
    try {
      await addTempOrder(tableId, int.parse(menuItemId), quantity.toDouble(), notes: comment);
      return await getOrdersByTable(tableId).then((orders) => orders.first);
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Failed to add item to order: $e');
    }
  }

  static Future<void> deleteOrder(String orderId) async {
    print('🗑️ deleteOrder called for orderId: $orderId');
    
    // For TempTav workflow, extract table ID and clear temp orders
    if (orderId.startsWith('temp_')) {
      print('📦 Deleting temp order - extracting tableId...');
      final tableId = orderId.substring(5);
      print('📍 TableId extracted: $tableId');
      
      print('🧹 Calling clearTempOrders...');
      final success = await clearTempOrders(tableId);
      if (!success) {
        print('❌ Failed to clear temporary orders');
        throw ApiException(statusCode: 0, message: 'Failed to clear temporary orders');
      } else {
        print('✅ Temporary orders cleared successfully');
      }
    } else {
      print('❌ Cannot delete finalized orders: $orderId');
      throw ApiException(statusCode: 0, message: 'Cannot delete finalized orders');
    }
  }

  // Create batch order from TempTav items and clear TempTav
  // CRITICAL: This method now validates responses properly to prevent print-without-save issues
  static Future<Map<String, dynamic>> createBatchOrder(String tableId) async {
    print('createBatchOrder called for tableId: $tableId');

    if (!BaseApiService.isConfigured) {
      print('API not configured');
      throw ApiException(statusCode: 0, message: 'API not configured');
    }

    try {
      // First, get the current TempTav items to create the batch order
      print('Fetching TempTav items...');
      final tempOrders = await getTempOrders(tableId);
      print('Found ${tempOrders.length} temp orders');

      if (tempOrders.isEmpty) {
        print('No items to order');
        throw ApiException(statusCode: 0, message: 'No items to order');
      }

      // Convert TempTav items to the batch order format
      final products = tempOrders.map((tempOrder) => {
        'productId': tempOrder['productId'] ?? 0,
        'quantity': (tempOrder['sasia'] ?? tempOrder['quantity'] ?? 1.0).toInt(),
        'notes': tempOrder['opsionet'] ?? tempOrder['options'] ?? '',
      }).toList();

      print('Converted to batch format: ${products.length} products');

      final requestBody = {
        'tableId': tableId,
        'products': products,
      };

      // Create batch order
      print('Sending POST to /api/Orders/batch...');
      final batchResponse = await http.post(
        Uri.parse('${BaseApiService.baseUrl}/api/Orders/batch'),
        headers: BaseApiService.headers,
        body: json.encode(requestBody),
      );

      print('Batch response status: ${batchResponse.statusCode}');
      print('Batch response body: ${batchResponse.body}');

      final batchData = BaseApiService.handleResponse(batchResponse);
      print('Batch order response: $batchData');

      // CRITICAL: Validate the response properly
      final success = batchData['success'] == true;
      final message = batchData['message']?.toString() ?? '';
      final error = batchData['error']?.toString();

      // Check for explicit failure
      if (!success && error != null && error.isNotEmpty) {
        print('CRITICAL: Batch order failed with error: $error');
        throw ApiException(statusCode: 0, message: error);
      }

      // Check for save failure indicators in the message
      if (message.toLowerCase().contains('save failed') ||
          message.toLowerCase().contains('all orders failed') ||
          message.toLowerCase().contains('critical')) {
        print('CRITICAL: Batch order response indicates save failure: $message');
        throw ApiException(statusCode: 0, message: 'Order save failed: $message');
      }

      // Only clear TempTav if we're confident the order was saved
      if (success || batchResponse.statusCode < 300) {
        // Additional check: ensure we got some data back indicating orders were created
        final data = batchData['data'];
        if (data is List && data.isEmpty && products.isNotEmpty) {
          print('WARNING: API returned empty data but we sent ${products.length} products');
          // Don't throw, but include warning in response
          batchData['warning'] = 'Server returned empty data - verify order was saved';
        }

        print('Clearing TempTav orders...');
        try {
          final clearSuccess = await clearTempOrders(tableId);
          if (!clearSuccess) {
            print('Warning: Batch order created but failed to clear TempTav');
            batchData['tempTavClearFailed'] = true;
          } else {
            print('TempTav cleared successfully');
          }
        } catch (clearError) {
          print('Error clearing TempTav: $clearError');
          batchData['tempTavClearFailed'] = true;
          // Don't throw - order was saved, this is just cleanup
        }
      } else {
        print('Batch order not confirmed successful, not clearing TempTav');
        throw ApiException(
          statusCode: batchResponse.statusCode,
          message: 'Order creation not confirmed. Status: ${batchResponse.statusCode}',
        );
      }

      return batchData;
    } catch (e) {
      print('createBatchOrder error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(statusCode: 0, message: 'Failed to create batch order: $e');
    }
  }

  // Printing Operations - Following TechTrek POS workflow
  static Future<Map<String, dynamic>> printKitchenOrder(String tableId) async {
    // Use the new batch order flow
    return await createBatchOrder(tableId);
  }

  static Future<Map<String, dynamic>> printOrder(String tableId) async {
    return await printKitchenOrder(tableId);
  }

  // Deprecated/Unsupported operations - return meaningful errors
  static Future<Order> updateOrderItem(String orderId, int itemIndex, int quantity, String? comment) async {
    throw ApiException(statusCode: 0, message: 'Order item updates not supported by current API - use add/remove instead');
  }

  static Future<Order> removeItemFromOrder(String orderId, int itemIndex) async {
    throw ApiException(statusCode: 0, message: 'Individual item removal not supported by current API - use order deletion instead');
  }

  static Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    throw ApiException(statusCode: 0, message: 'Order status updates not supported by current API - use deletion for closing orders');
  }
}
