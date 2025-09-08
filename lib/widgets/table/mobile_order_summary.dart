import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/translations.dart';

class MobileOrderSummary extends StatelessWidget {
  final Waiter currentUser;
  final Order activeOrder;
  final Function(String, OrderItem) onRemoveItem;

  const MobileOrderSummary({
    super.key,
    required this.currentUser,
    required this.activeOrder,
    required this.onRemoveItem,
  });

  String _trimProductName(String name) {
    if (name.length > 17) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero, // Remove all margins
      padding: const EdgeInsets.all(16), // Add consistent padding
      decoration: BoxDecoration(
        color: currentUser.color.withOpacity(0.1), // Light user color background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.black, size: 20),
              const SizedBox(width: 8),
              Text(
                '${AppTranslations.currentOrderMobile} (${activeOrder.items.length} ${AppTranslations.items})',
                style: const TextStyle(
                  fontSize: 20, // Increased from 16 to 20
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '\$${activeOrder.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22, // Increased from 18 to 22
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 85, // Increased height to accommodate original font sizes
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeOrder.items.length, // Items are ordered newest first
              itemBuilder: (context, index) {
                final item = activeOrder.items[index];
                return Container(
                  width: 140, // Increased width for better comment display
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: currentUser.color.withOpacity(0.2), // Light user color for items
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${_trimProductName(item.name)}', // Show quantity with trimmed name
                              style: const TextStyle(
                                fontSize: 16, // Increased from 13 to 16
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onRemoveItem(activeOrder.id, item),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3), // Reduced from 4 to 3 to save space
                      Text(
                        '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16, // Increased from 13 to 16
                          color: Color(0xFF000000),
                        ),
                      ),
                      if (item.comment?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                                                 Text(
                           '${AppTranslations.note}: ${item.comment}',
                           style: const TextStyle(
                             fontSize: 14, // Increased from 11 to 14
                             color: Colors.black54,
                             fontStyle: FontStyle.italic,
                           ),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                         ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
