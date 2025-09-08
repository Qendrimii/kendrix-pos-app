import 'order_item.dart';
import 'enums.dart';

class Order {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final double? apiTotal; // API-provided total to avoid recalculation

  const Order({
    required this.id,
    required this.tableId,
    required this.items,
    required this.status,
    required this.createdAt,
    this.apiTotal,
  });

  // Alternative constructor for backward compatibility
  Order.withTimestamp({
    required String id,
    required String tableId,
    required List<OrderItem> items,
    required OrderStatus status,
    required DateTime timestamp,
    double? apiTotal,
  }) : this(
    id: id,
    tableId: tableId,
    items: items,
    status: status,
    createdAt: timestamp,
    apiTotal: apiTotal,
  );

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      tableId: json['tableId'].toString(),
      items: (json['items'] as List<dynamic>?)
          ?.map((itemJson) => OrderItem.fromJson(itemJson as Map<String, dynamic>))
          .toList() ?? [],
      status: orderStatusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      apiTotal: (json['total'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableId': tableId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'total': apiTotal,
    };
  }

  double get total => apiTotal ?? items.fold(0, (sum, item) => sum + (item.price * item.quantity));

  Order copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    double? apiTotal,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      apiTotal: apiTotal ?? this.apiTotal,
    );
  }
}
