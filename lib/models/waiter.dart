import 'package:flutter/material.dart';
import 'enums.dart';

class Waiter {
  final String id;
  final String name;
  final Color color;
  final String pin;

  const Waiter({
    required this.id,
    required this.name,
    required this.color,
    required this.pin,
  });

  factory Waiter.fromJson(Map<String, dynamic> json) {
    return Waiter(
      id: json['id'].toString(),
      name: json['name'] as String,
      color: colorFromHex(json['color'] as String),
      pin: json['pin'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': colorToHex(color),
      'pin': pin,
    };
  }
}
