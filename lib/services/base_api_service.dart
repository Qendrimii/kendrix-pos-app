import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseApiService {
  static String? _baseUrl;
  
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static bool get isConfigured => _baseUrl != null && _baseUrl!.isNotEmpty;
  static String? get baseUrl => _baseUrl;

  static Future<void> initialize() async {
    await loadConfiguration();
  }

  static Future<void> configure(String baseUrl) async {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl!);
  }

  static Future<void> setBaseUrl(String baseUrl) async {
    await configure(baseUrl);
  }

  static Future<void> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_base_url');
  }

  static Map<String, dynamic> handleResponse(http.Response response) {
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

  static Future<bool> testConnection() async {
    if (!isConfigured) return false;
    
    try {
      print('Testing connection to: $_baseUrl/health');
      print('Running on platform: ${Uri.base.scheme}'); // web vs file
      
      // Try a simple GET request with a longer timeout
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      ).timeout(const Duration(seconds: 15)); // Longer timeout for mobile networks
      
      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        print('✅ Health check successful');
        return true;
      } else {
        print('❌ Health check failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
      print('Error type: ${e.runtimeType}');
      
      // Try alternative endpoint as fallback
      try {
        print('🔄 Trying alternative endpoint: $_baseUrl/api/info');
        final response = await http.get(
          Uri.parse('$_baseUrl/api/info'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));
        
        print('Alternative endpoint status: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('✅ Alternative endpoint successful');
          return true;
        }
        return false;
      } catch (e2) {
        print('❌ Alternative endpoint also failed: $e2');
        
        // Final attempt: Try to reach any endpoint to test basic connectivity
        try {
          print('🔄 Final attempt: Testing basic connectivity to $_baseUrl');
          final response = await http.get(
            Uri.parse('$_baseUrl'),
          ).timeout(const Duration(seconds: 10));
          
          print('Basic connectivity test status: ${response.statusCode}');
          // Even a 404 would indicate the server is reachable
          return response.statusCode < 500;
        } catch (e3) {
          print('❌ No connectivity to server: $e3');
          return false;
        }
      }
    }
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
