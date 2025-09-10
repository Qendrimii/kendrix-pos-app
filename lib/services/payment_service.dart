import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_api_service.dart';

class PaymentService extends BaseApiService {
  // Payment and Transaction Processing - Following TechTrek POS workflow
  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/Payments/methods'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    // Accept both wrapped and raw list responses
    if (data is Map) {
      final list = (data['data'] as List?) ?? (data['methods'] as List?);
      if (list != null) {
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      // If server returns success but null data, treat as empty list
      if ((data['success'] == true) && data['data'] == null) {
        return <Map<String, dynamic>>[];
      }
    }
      if (data is List) {
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
    throw ApiException(statusCode: 0, message: 'Failed to load payment methods: unexpected response');
  }

  static Future<Map<String, dynamic>> finalizeOrder(String tableId, int paymentMethodId, {int? customerId}) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/tables/$tableId/finalize'),
      headers: BaseApiService.headers,
      body: json.encode({
        'paymentMethodId': paymentMethodId,
        'customerId': customerId,
      }),
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to finalize order');
  }

  static Future<Map<String, dynamic>> processStaffSale(String tableId, int paymentMethodId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/transactions/staff-sale'),
      headers: BaseApiService.headers,
      body: json.encode({
        'tableId': tableId,
        'paymentMethodId': paymentMethodId,
      }),
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to process staff sale');
  }

  static Future<Map<String, dynamic>> processCustomerSale(String tableId, int paymentMethodId, {int? customerId}) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // Use the actual Payments API endpoint
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/Payments/process'),
      headers: BaseApiService.headers,
      body: json.encode({
        'tableId': tableId,
        'paymentMethodId': paymentMethodId,
        'amount': 0.0, // Will be calculated by server
        'receivedAmount': 0.0,
        'adminPassword': '', // May need to be provided
        'printFiscal': true,
        'printKitchen': false,
      }),
    );
    
    return BaseApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> processKitchenSale(String tableId, int paymentMethodId, {int? customerId}) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // Use the actual Payments API endpoint with kitchen printing settings
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/Payments/process'),
      headers: BaseApiService.headers,
      body: json.encode({
        'tableId': tableId,
        'paymentMethodId': paymentMethodId,
        'amount': 0.0, // Will be calculated by server
        'receivedAmount': 0.0,
        'adminPassword': '', // May need to be provided
        'printFiscal': false,
        'printKitchen': true,
      }),
    );
    
    return BaseApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> printCustomerReceipt(String transactionId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/orders/$transactionId/print-receipt'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to print customer receipt');
  }

  static Future<Map<String, dynamic>> printFiscalReceipt(String transactionId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/transactions/$transactionId/print-fiscal'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to print fiscal receipt');
  }

  // Legacy/Backward Compatibility Methods
  static Future<Map<String, dynamic>> processPayment({
    required List<String> orderIds,
    required String paymentMethod,
    required double totalAmount,
    String? notes,
  }) async {
    // Extract table ID from order IDs (assuming temp_tableId format)
    if (orderIds.isEmpty) {
      throw ApiException(statusCode: 0, message: 'No orders to process');
    }
    
    final orderId = orderIds.first;
    if (orderId.startsWith('temp_')) {
      final tableId = orderId.substring(5);
      final paymentMethodId = paymentMethod == 'cash' ? 1 : 2; // Assuming cash=1, card=2
      
      return await processCustomerSale(tableId, paymentMethodId);
    } else {
      throw ApiException(statusCode: 0, message: 'Invalid order format for payment processing');
    }
  }

  static Future<Map<String, dynamic>> printReceiptCopy(String tableId) async {
    // This would need a transaction ID in real implementation
    throw ApiException(statusCode: 0, message: 'Receipt printing requires completed transaction');
  }
}
