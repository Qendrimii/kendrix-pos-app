class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? description;
  final int? categoryId;
  final bool? isAvailable;
  final bool? isActive;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.categoryId,
    this.isAvailable,
    this.isActive,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'].toString(),
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['categoryName'] as String? ?? 'Unknown', // Use categoryName from API
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int?,
      isAvailable: json['isAvailable'] as bool?,
      isActive: json['isActive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'description': description,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
      'isActive': isActive,
    };
  }
}
