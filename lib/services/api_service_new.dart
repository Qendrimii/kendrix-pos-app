import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _baseUrl;
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  bool get isConfigured => _baseUrl != null && _baseUrl!.isNotEmpty;

  Future<void> configure(String baseUrl) async {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl!);
  }

  Future<void> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {'success': true, 'data': response.body};
      }
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          message: errorBody['message'] ?? 'API Error: ${response.statusCode}',
          body: response.body,
        );
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'API Error: ${response.statusCode}',
          body: response.body,
        );
      }
    }
  }

  // Authentication
  Future<Map<String, dynamic>> login(String password) async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Login/login'),
      headers: _headers,
      body: json.encode({'password': password}),
    );
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> logout() async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Login/logout'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  // Halls and Tables
  Future<List<Hall>> getHalls() async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Halls'),
      headers: _headers,
    );
    
    final data = _handleResponse(response);
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Hall.fromJson(json))
          .toList();
    }
    throw ApiException(statusCode: 0, message: 'Failed to load halls');
  }

  Future<TableInfo> updateTable(String tableId, {String? name, TableStatus? status, String? waiterId}) async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    // For status or waiter updates, use the status endpoint
    if (status != null || waiterId != null) {
      final requestBody = <String, dynamic>{};
      if (status != null) requestBody['status'] = status.name;
      if (waiterId != null) requestBody['waiterId'] = int.tryParse(waiterId);
      
      final response = await http.put(
        Uri.parse('$_baseUrl/api/Halls/tables/$tableId/status'),
        headers: _headers,
        body: json.encode(requestBody),
      );
      
      final data = _handleResponse(response);
      if (data['success'] == true) {
        return TableInfo.fromJson(data['data']);
      }
      throw ApiException(statusCode: response.statusCode, message: 'Failed to update table');
    }
    
    // For other updates, this might need a different endpoint
    throw ApiException(statusCode: 0, message: 'Table update operation not supported by current API');
  }

  // Orders
  Future<Order> createOrder(String tableId) async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    try {
      // Get available products first
      final menuResponse = await http.get(
        Uri.parse('$_baseUrl/api/Sales/products'),
        headers: _headers,
      );
      
      if (menuResponse.statusCode == 200) {
        final menuData = json.decode(menuResponse.body);
        if (menuData['success'] == true && menuData['data'].isNotEmpty) {
          final firstProductId = menuData['data'][0]['id'];
          
          // Create order with the first available product (temporary item)
          final response = await http.post(
            Uri.parse('$_baseUrl/api/Orders'),
            headers: _headers,
            body: json.encode({
              'tableId': tableId,
              'productId': firstProductId,
              'quantity': 0.0, // Zero quantity as placeholder
              'notes': 'New order - placeholder item'
            }),
          );
          
          final data = _handleResponse(response);
          if (data['success'] == true) {
            return Order.fromJson(data['data']);
          }
        } else {
          throw ApiException(statusCode: 0, message: 'No products available to create order');
        }
      }
      
      throw ApiException(statusCode: 0, message: 'Failed to get products for order creation');
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Failed to create order: $e');
    }
  }

  Future<List<Order>> getOrdersByTable(String tableId) async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Orders/table/$tableId'),
      headers: _headers,
    );
    
    final data = _handleResponse(response);
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Order.fromJson(json))
          .toList();
    }
    throw ApiException(statusCode: 0, message: 'Failed to load orders');
  }

  Future<Order> addItemToOrder(String tableId, String menuItemId, int quantity, String? comment) async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    try {
      // Create a new order for this item (API uses one order per item approach)
      final response = await http.post(
        Uri.parse('$_baseUrl/api/Orders'),
        headers: _headers,
        body: json.encode({
          'tableId': tableId,
          'productId': int.parse(menuItemId),
          'quantity': quantity.toDouble(),
          'notes': comment ?? '',
        }),
      );
      
      final data = _handleResponse(response);
      if (data['success'] == true) {
        return Order.fromJson(data['data']);
      }
      throw ApiException(statusCode: 0, message: 'Failed to add item to order');
    } catch (e) {
      throw ApiException(statusCode: 0, message: 'Failed to add item to order: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/Orders/$orderId'),
      headers: _headers,
    );
    
    final data = _handleResponse(response);
    if (data['success'] != true) {
      throw ApiException(statusCode: response.statusCode, message: 'Failed to delete order');
    }
  }

  // Menu
  Future<List<MenuItem>> getMenu() async {
    if (!isConfigured) throw ApiException(statusCode: 0, message: 'API not configured');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Sales/products'),
      headers: _headers,
    );
    
    final data = _handleResponse(response);
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => MenuItem.fromJson(json))
          .toList();
    }
    throw ApiException(statusCode: 0, message: 'Failed to load menu');
  }

  // Utilities
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Unsupported operations - return meaningful errors
  Future<Order> updateOrderItem(String orderId, int itemIndex, int quantity, String? comment) async {
    throw ApiException(statusCode: 0, message: 'Order item updates not supported by current API - use add/remove instead');
  }

  Future<Order> removeItemFromOrder(String orderId, int itemIndex) async {
    throw ApiException(statusCode: 0, message: 'Individual item removal not supported by current API - use order deletion instead');
  }

  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    throw ApiException(statusCode: 0, message: 'Order status updates not supported by current API - use deletion for closing orders');
  }

  Future<List<String>> getWaiters() async {
    throw ApiException(statusCode: 0, message: 'Waiters endpoint not available in API');
  }

  Future<Map<String, dynamic>> printOrder(String tableId) async {
    throw ApiException(statusCode: 0, message: 'Print functionality not supported by API');
  }

  Future<Map<String, dynamic>> printReceiptCopy(String tableId) async {
    throw ApiException(statusCode: 0, message: 'Print functionality not supported by API');
  }

  Future<Map<String, dynamic>> processPayment({
    required List<String> orderIds,
    required String paymentMethod,
    required double totalAmount,
    String? notes,
  }) async {
    throw ApiException(statusCode: 0, message: 'Payment processing not supported by current API');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
