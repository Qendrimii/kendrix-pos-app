import 'package:flutter/material.dart';

// Enums
enum TableStatus { free, occupied, reserved }
enum OrderStatus { open, closed, printed }

// Helper functions for enum conversion
TableStatus tableStatusFromString(String status) {
  switch (status) {
    case 'free':
      return TableStatus.free;
    case 'occupied':
      return TableStatus.occupied;
    case 'reserved':
      return TableStatus.reserved;
    default:
      return TableStatus.free;
  }
}

OrderStatus orderStatusFromString(String status) {
  switch (status) {
    case 'open':
      return OrderStatus.open;
    case 'closed':
      return OrderStatus.closed;
    case 'printed':
      return OrderStatus.printed;
    default:
      return OrderStatus.open;
  }
}

// Color utility functions
Color colorFromHex(String hexColor) {
  final hex = hexColor.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}
