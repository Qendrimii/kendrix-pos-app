import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/translations.dart';
import 'order_item_tile.dart';

class CurrentOrderSection extends StatelessWidget {
  final Order? activeOrder;
  final Waiter currentUser;
  final Function(int) onRemoveItem;
  final Function(int, String) onCommentUpdate;
  final Function(int, int) onQuantityUpdate;
  final VoidCallback onPrintOrder;

  const CurrentOrderSection({
    super.key,
    required this.activeOrder,
    required this.currentUser,
    required this.onRemoveItem,
    required this.onCommentUpdate,
    required this.onQuantityUpdate,
    required this.onPrintOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current Order header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF6F6F6),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                AppTranslations.currentOrder,
                style: TextStyle(
                  fontSize: 22, // Increased from 18 to 22
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (activeOrder?.items.isNotEmpty ?? false)
                Text(
                  '\$${activeOrder!.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20, // Increased from 16 to 20
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ),
        // Current Order Content
        Expanded(
          child: activeOrder?.items.isEmpty ?? true
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No items yet',
                        style: TextStyle(
                          fontSize: 20, // Increased from 16 to 20
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Add items from the menu',
                        style: TextStyle(
                          fontSize: 18, // Increased from 14 to 18
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16), // Add same padding as past orders
                        itemCount: activeOrder!.items.length,
                        itemBuilder: (context, index) {
                          final orderItem = activeOrder!.items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8), // Add margin between items
                            padding: const EdgeInsets.all(16), // Add same padding as past orders
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: OrderItemTile(
                              item: orderItem,
                              index: index,
                              onRemove: () => onRemoveItem(index),
                              userColor: currentUser.color,
                              onCommentUpdate: onCommentUpdate,
                              onQuantityUpdate: onQuantityUpdate,
                            ),
                          );
                        },
                      ),
                    ),
                    // Send to Kitchen button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onPrintOrder,
                          icon: const Icon(Icons.print),
                          label: Text(AppTranslations.order),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentUser.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Reduced padding to prevent overflow
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // Increased font size
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
