import 'enums.dart';

class TableInfo {
  final String id;
  final String name;
  final TableStatus status;
  final String? waiterId;
  final String? waiterName;
  final double total;

  const TableInfo({
    required this.id,
    required this.name,
    required this.status,
    this.waiterId,
    this.waiterName,
    this.total = 0.0,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      id: json['id'].toString(), // Convert to String to handle both int and String
      name: json['name'] as String,
      status: tableStatusFromString(json['status'] as String),
      waiterId: json['waiterId']?.toString(), // Convert to String if not null
      waiterName: json['waiterName'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status.name,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'total': total,
    };
  }

  TableInfo copyWith({
    String? id,
    String? name,
    TableStatus? status,
    String? waiterId,
    String? waiterName,
    double? total,
  }) {
    return TableInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      waiterId: waiterId ?? this.waiterId,
      waiterName: waiterName ?? this.waiterName,
      total: total ?? this.total,
    );
  }
}
