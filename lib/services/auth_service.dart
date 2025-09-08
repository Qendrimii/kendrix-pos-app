import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_api_service.dart';

class AuthService extends BaseApiService {
  // Authentication - Following TechTrek POS workflow
  static Future<Map<String, dynamic>> login(String password) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/Login/login'),
      headers: BaseApiService.headers,
      body: json.encode({'password': password}),
    );
    
    return BaseApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> authenticateWithPin(String pin) async {
    return await login(pin);
  }

  static Future<Map<String, dynamic>> logout() async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.post(
      Uri.parse('${BaseApiService.baseUrl}/api/Login/logout'),
      headers: BaseApiService.headers,
    );
    
    return BaseApiService.handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // API doesn't have current-user endpoint, return basic user info
    return {
      'username': 'admin',
      'role': 'admin',
      'authenticated': true,
    };
  }
}
