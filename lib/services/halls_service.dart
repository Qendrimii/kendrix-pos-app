import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_api_service.dart';

class HallsService extends BaseApiService {
  static Future<List<Hall>> getHalls() async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/halls'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => Hall.fromJson(json))
          .toList();
    }
    throw ApiException(statusCode: 0, message: 'Failed to load halls');
  }

  static Future<List<TableInfo>> getTablesForHall(String hallId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/halls/$hallId/tables'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return (data['data'] as List)
          .map((json) => TableInfo.fromJson(json))
          .toList();
    }
    throw ApiException(statusCode: 0, message: 'Failed to load tables');
  }

  static Future<TableInfo> getTable(String tableId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    final response = await http.get(
      Uri.parse('${BaseApiService.baseUrl}/api/tables/$tableId'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    if (data['success'] == true) {
      return TableInfo.fromJson(data['data']);
    }
    throw ApiException(statusCode: 0, message: 'Failed to load table');
  }

  static Future<TableInfo> updateTableStatus(String tableId, TableStatus status, {String? waiterId}) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    // According to API docs: only waiterId matters, status is ignored
    final requestBody = <String, dynamic>{};
    if (waiterId != null) {
      requestBody['waiterId'] = int.tryParse(waiterId);
    }
    // If waiterId is null, don't send it - API will set table to "free"
    
    print('🔄 Updating table status: tableId=$tableId, waiterId=$waiterId, requestBody=$requestBody');
    
    final response = await http.put(
      Uri.parse('${BaseApiService.baseUrl}/api/Halls/tables/$tableId/status'),
      headers: BaseApiService.headers,
      body: json.encode(requestBody),
    );
    
    final data = BaseApiService.handleResponse(response);
    // Handle different response formats
    if (data is Map && data.containsKey('id')) {
      return TableInfo.fromJson(data);
    } else if (data is Map && data.containsKey('data')) {
      return TableInfo.fromJson(data['data']);
    } else {
      // If update successful but no data returned, return a basic table info
      return TableInfo(
        id: tableId,
        name: 'Table $tableId',
        status: status,
        waiterId: waiterId,
      );
    }
  }

  static Future<TableInfo> addTable(String hallId, String tableName) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseApiService.baseUrl}/api/Tables'),
        headers: BaseApiService.headers,
        body: json.encode({
          'name': tableName,
          'hallId': hallId,
          'status': 'available'
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return TableInfo(
          id: data['id'].toString(),
          name: data['name'],
          status: TableStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == data['status'].toString().toLowerCase(),
            orElse: () => TableStatus.free,
          ),
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to create table: ${response.body}',
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Failed to create table: $e');
    }
  }

  static Future<TableInfo> updateTable(String tableId, {String? name, TableStatus? status, String? waiterId}) async {
    return await updateTableStatus(tableId, status ?? TableStatus.free, waiterId: waiterId);
  }

  static Future<TableInfo> freeTable(String tableId) async {
    if (!BaseApiService.isConfigured) {
      throw ApiException(statusCode: 0, message: 'API not configured');
    }
    
    print('🔄 Freeing table: tableId=$tableId');
    
    final response = await http.put(
      Uri.parse('${BaseApiService.baseUrl}/api/halls/tables/$tableId/free'),
      headers: BaseApiService.headers,
    );
    
    final data = BaseApiService.handleResponse(response);
    // Handle different response formats
    if (data is Map && data.containsKey('id')) {
      return TableInfo.fromJson(data);
    } else if (data is Map && data.containsKey('data')) {
      return TableInfo.fromJson(data['data']);
    } else {
      // If update successful but no data returned, return a basic table info
      return TableInfo(
        id: tableId,
        name: 'Table $tableId',
        status: TableStatus.free,
        waiterId: null,
      );
    }
  }
}
