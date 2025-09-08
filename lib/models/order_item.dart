class OrderItem {
  final String? id; // TempTav ID for individual deletion
  final String name;
  final double price;
  final int quantity;
  final String? comment;

  const OrderItem({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.comment,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      comment: json['comment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'comment': comment,
    };
  }

  OrderItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? comment,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      comment: comment ?? this.comment,
    );
  }
}
