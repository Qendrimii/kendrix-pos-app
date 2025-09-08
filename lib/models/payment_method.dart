class PaymentMethod {
  final int id;
  final String name;
  final int? bankId;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.name,
    this.bankId,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String,
      bankId: json['bankId'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bankId': bankId,
      'isActive': isActive,
    };
  }

  // Helper method to check if this is a bank payment
  bool get isBankPayment => bankId != null;

  // Helper method to get display name
  String get displayName => isBankPayment ? '$name (Bank)' : name;
}
