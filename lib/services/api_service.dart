import '../models/models.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import 'halls_service.dart';
import 'orders_service.dart';
import 'menu_service.dart';
import 'payment_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main API service that composes all other services for backward compatibility
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? get baseUrl => BaseApiService.baseUrl;
  bool get isConfigured => BaseApiService.isConfigured;

  // Initialization and Configuration
  Future<void> initialize() async {
    await BaseApiService.initialize();
  }

  Future<void> configure(String baseUrl) async {
    await BaseApiService.configure(baseUrl);
  }

  Future<void> setBaseUrl(String baseUrl) async {
    await BaseApiService.setBaseUrl(baseUrl);
  }

  Future<void> loadConfiguration() async {
    await BaseApiService.loadConfiguration();
  }

  Future<bool> testConnection() async {
    return await BaseApiService.testConnection();
  }

  // Authentication Methods
  Future<Map<String, dynamic>> login(String password) async {
    return await AuthService.login(password);
  }

  Future<Map<String, dynamic>> authenticateWithPin(String pin) async {
    return await AuthService.authenticateWithPin(pin);
  }

  Future<Map<String, dynamic>> logout() async {
    return await AuthService.logout();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await AuthService.getCurrentUser();
  }

  // Halls and Tables Methods
  Future<List<Hall>> getHalls() async {
    return await HallsService.getHalls();
  }

  Future<List<TableInfo>> getTablesForHall(String hallId) async {
    return await HallsService.getTablesForHall(hallId);
  }

  Future<TableInfo> getTable(String tableId) async {
    return await HallsService.getTable(tableId);
  }

  Future<TableInfo> updateTableStatus(String tableId, TableStatus status, {String? waiterId}) async {
    return await HallsService.updateTableStatus(tableId, status, waiterId: waiterId);
  }

  Future<TableInfo> addTable(String hallId, String tableName) async {
    return await HallsService.addTable(hallId, tableName);
  }

  Future<TableInfo> updateTable(String tableId, {String? name, TableStatus? status, String? waiterId}) async {
    return await HallsService.updateTable(tableId, name: name, status: status, waiterId: waiterId);
  }

  Future<TableInfo> freeTable(String tableId) async {
    return await HallsService.freeTable(tableId);
  }

  // Orders Methods
  Future<List<Map<String, dynamic>>> getTempOrders(String tableId) async {
    return await OrdersService.getTempOrders(tableId);
  }

  Future<Map<String, dynamic>> addTempOrder(String tableId, int productId, double quantity, {String? notes}) async {
    return await OrdersService.addTempOrder(tableId, productId, quantity, notes: notes);
  }

  Future<Map<String, dynamic>> updateTempOrder(int tempOrderId, double quantity, {String? notes}) async {
    return await OrdersService.updateTempOrder(tempOrderId, quantity, notes: notes);
  }

  Future<bool> deleteTempOrder(int tempOrderId) async {
    return await OrdersService.deleteTempOrder(tempOrderId);
  }

  Future<Map<String, dynamic>> getTempOrderTotal(String tableId) async {
    return await OrdersService.getTempOrderTotal(tableId);
  }

  Future<bool> clearTempOrders(String tableId) async {
    return await OrdersService.clearTempOrders(tableId);
  }

  Future<List<Order>> getOrdersByTable(String tableId) async {
    return await OrdersService.getOrdersByTable(tableId);
  }

  Future<List<Order>> getTableOrders(String tableId) async {
    return await OrdersService.getTableOrders(tableId);
  }

  Future<Order> createOrder(String tableId) async {
    return await OrdersService.createOrder(tableId);
  }

  Future<Order> addItemToOrder(String tableId, String menuItemId, int quantity, String? comment) async {
    return await OrdersService.addItemToOrder(tableId, menuItemId, quantity, comment);
  }

  Future<void> deleteOrder(String orderId) async {
    return await OrdersService.deleteOrder(orderId);
  }

  Future<Map<String, dynamic>> printKitchenOrder(String tableId) async {
    return await OrdersService.printKitchenOrder(tableId);
  }

  Future<Map<String, dynamic>> printOrder(String tableId) async {
    return await OrdersService.printOrder(tableId);
  }

  Future<Map<String, dynamic>> createBatchOrder(String tableId) async {
    return await OrdersService.createBatchOrder(tableId);
  }

  // Menu Methods
  Future<List<MenuItem>> getProducts() async {
    return await MenuService.getProducts();
  }

  Future<MenuItem> getProduct(int productId) async {
    return await MenuService.getProduct(productId);
  }

  Future<List<String>> getCategories() async {
    return await MenuService.getCategories();
  }

  Future<Map<String, dynamic>> checkHappyHour(int productId, DateTime checkTime) async {
    return await MenuService.checkHappyHour(productId, checkTime);
  }

  Future<List<MenuItem>> getMenu() async {
    return await MenuService.getMenu();
  }

  // Payment Methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    return await PaymentService.getPaymentMethods();
  }

  Future<Map<String, dynamic>> finalizeOrder(String tableId, int paymentMethodId, {int? customerId}) async {
    return await PaymentService.finalizeOrder(tableId, paymentMethodId, customerId: customerId);
  }

  Future<Map<String, dynamic>> processStaffSale(String tableId, int paymentMethodId) async {
    return await PaymentService.processStaffSale(tableId, paymentMethodId);
  }

  Future<Map<String, dynamic>> processCustomerSale(String tableId, int paymentMethodId, {int? customerId}) async {
    return await PaymentService.processCustomerSale(tableId, paymentMethodId, customerId: customerId);
  }

  Future<Map<String, dynamic>> processKitchenSale(String tableId, int paymentMethodId, {int? customerId}) async {
    return await PaymentService.processKitchenSale(tableId, paymentMethodId, customerId: customerId);
  }

  Future<Map<String, dynamic>> printCustomerReceipt(String transactionId) async {
    return await PaymentService.printCustomerReceipt(transactionId);
  }

  Future<Map<String, dynamic>> printFiscalReceipt(String transactionId) async {
    return await PaymentService.printFiscalReceipt(transactionId);
  }

  Future<Map<String, dynamic>> processPayment({
    required List<String> orderIds,
    required String paymentMethod,
    required double totalAmount,
    String? notes,
  }) async {
    return await PaymentService.processPayment(
      orderIds: orderIds,
      paymentMethod: paymentMethod,
      totalAmount: totalAmount,
      notes: notes,
    );
  }

  Future<Map<String, dynamic>> printReceiptCopy(String tableId) async {
    return await PaymentService.printReceiptCopy(tableId);
  }

  // Deprecated/Unsupported operations - return meaningful errors
  Future<Order> updateOrderItem(String orderId, int itemIndex, int quantity, String? comment) async {
    return await OrdersService.updateOrderItem(orderId, itemIndex, quantity, comment);
  }

  Future<Order> removeItemFromOrder(String orderId, int itemIndex) async {
    return await OrdersService.removeItemFromOrder(orderId, itemIndex);
  }

  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    return await OrdersService.updateOrderStatus(orderId, status);
  }

  Future<List<String>> getWaiters() async {
    throw ApiException(statusCode: 0, message: 'Waiters endpoint not available in API');
  }

  // Search Methods
  Future<List<MenuItem>> searchProducts(String query) async {
    try {
      if (!BaseApiService.isConfigured) {
        return [];
      }
      
      final url = Uri.parse('${BaseApiService.baseUrl}/api/Orders/products/search?name=$query');
      final response = await http.get(url, headers: BaseApiService.headers);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> products = responseData['data'];
          return products.map((product) => MenuItem(
            id: product['id'].toString(),
            name: product['name'] ?? '',
            price: (product['price'] ?? 0.0).toDouble(),
            category: product['categoryName'] ?? product['category'] ?? 'Unknown',
            isAvailable: product['isAvailable'] ?? false,
            description: product['description'],
          )).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Search products failed: $e');
      return [];
    }
  }
}