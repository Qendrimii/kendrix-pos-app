import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class TableTile extends ConsumerWidget {
  final TableInfo table;
  final Waiter currentUser;
  final bool hasOrders;
  final VoidCallback onTap;

  const TableTile({
    super.key,
    required this.table,
    required this.currentUser,
    required this.hasOrders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiters = ref.watch(waitersProvider);
    final assignedWaiter = waiters.where((w) => w.id == table.waiterId).firstOrNull;
    
    final canAccess = table.status == TableStatus.free || 
                     table.waiterId == currentUser.id;

    Color backgroundColor;
    Color borderColor;

    if (table.status == TableStatus.free) {
      backgroundColor = Colors.white; // White background for free tables
      borderColor = const Color(0xFF000000); // Black border
    } else if (table.waiterId == currentUser.id) {
      backgroundColor = currentUser.color.withOpacity(0.1); // Light waiter color
      borderColor = currentUser.color; // Waiter's color
    } else {
      backgroundColor = assignedWaiter?.color.withOpacity(0.1) ?? const Color(0xFFE53E3E).withOpacity(0.1); // Light waiter color or red
      borderColor = assignedWaiter?.color ?? const Color(0xFFE53E3E); // Waiter's color or red
    }

    return GestureDetector(
      onTap: canAccess ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0), // Reduced from 6.0 to 3.0 to save space
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              Text(
                table.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF000000), // Black text
                ),
                textAlign: TextAlign.center,
              ),
              // Display waiter name from API
              if (table.waiterName != null && table.waiterName!.isNotEmpty) ...[
                const SizedBox(height: 2), // Reduced from 3 to 2 to save space
                Text(
                  table.waiterName!.trim(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // Display total amount when there are orders
              if (table.total > 0) ...[
                const SizedBox(height: 2), // Reduced from 3 to 2 to save space
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1), // Reduced padding to save space
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3), // Reduced from 4 to 3 to save space
                  ),
                  child: Text(
                    '\$${table.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 9,
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
