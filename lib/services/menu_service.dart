import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_api_service.dart';

class MenuService extends BaseApiService {
  // Products and Categories - Following TechTrek POS workflow
  static Future<List<MenuItem>> getProducts() async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/Sales/products'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    // Handle different response formats
    if (data is List) {
      return (data as List).map((json) => MenuItem.fromJson(json as Map<String, dynamic>)).toList();
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      return (data['data'] as List).map((json) => MenuItem.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      // Return empty list if no products
      return [];
    }
  }

  static Future<MenuItem> getProduct(int productId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // Since there's no single product endpoint, get all products and filter
    final products = await getProducts();
    final product = products.where((p) => p.id == productId.toString()).firstOrNull;
    
    if (product != null) {
      return product;
    }
    
    throw ApiException(statusCode: 404, message: 'Product not found');
  }

  static Future<List<String>> getCategories() async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/Sales/categories'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    // Handle different response formats
    if (data is List) {
      return (data as List).map((item) => item['name']?.toString() ?? 'Unknown').toList();
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      return (data['data'] as List).map((item) => item['name']?.toString() ?? 'Unknown').toList();
    } else {
      // Return empty list if no categories
      return [];
    }
  }

  static Future<Map<String, dynamic>> checkHappyHour(int productId, DateTime checkTime) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/products/$productId/check-happy-hour'),
      headers: BaseApiService.headers,
      body: json.encode({
        'checkTime': checkTime.toIso8601String(),
      }),
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return data['data'];
    }
    throw ApiException(statusCode: 0, message: 'Failed to check happy hour pricing');
  }

  // Legacy/Backward Compatibility Methods
  static Future<List<MenuItem>> getMenu() async {
    return await getProducts();
  }
}
