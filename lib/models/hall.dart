import 'table_info.dart';

class Hall {
  final String id;
  final String name;
  final List<TableInfo> tables;

  const Hall({
    required this.id,
    required this.name,
    required this.tables,
  });

  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'].toString(), // Convert to String to handle both int and String
      name: json['name'] as String,
      tables: (json['tables'] as List<dynamic>?)
          ?.map((tableJson) => TableInfo.fromJson(tableJson as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tables': tables.map((table) => table.toJson()).toList(),
    };
  }

  Hall copyWith({
    String? id,
    String? name,
    List<TableInfo>? tables,
  }) {
    return Hall(
      id: id ?? this.id,
      name: name ?? this.name,
      tables: tables ?? this.tables,
    );
  }
}
