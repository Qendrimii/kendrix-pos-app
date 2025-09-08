import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/translations.dart';

class MobilePastOrders extends StatelessWidget {
  final Waiter currentUser;
  final List<Order> pastOrders;
  final VoidCallback onTap;

  const MobilePastOrders({
    super.key,
    required this.currentUser,
    required this.pastOrders,
    required this.onTap,
  });

  String _trimProductName(String name) {
    if (name.length > 17) {
      return '${name.substring(0, 17)}...';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final double pastOrdersTotal = pastOrders.fold<double>(0, (sum, order) => sum + order.total);
    
    // Aggregate all products from all past orders
    final Map<String, Map<String, dynamic>> productSummary = {};
    for (final order in pastOrders) {
      for (final item in order.items) {
        final key = _trimProductName(item.name);
        if (productSummary.containsKey(key)) {
          productSummary[key]!['quantity'] = (productSummary[key]!['quantity'] as int) + item.quantity;
          productSummary[key]!['total'] = (productSummary[key]!['total'] as double) + (item.price * item.quantity);
        } else {
          productSummary[key] = {
            'name': _trimProductName(item.name),
            'quantity': item.quantity,
            'price': item.price,
            'total': item.price * item.quantity,
          };
        }
      }
    }
    
    final List<Map<String, dynamic>> productList = productSummary.values.toList();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16), // Same padding as mobile order summary
      decoration: BoxDecoration(
        color: currentUser.color.withOpacity(0.05), // Very light user color background
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
              const Icon(Icons.history, color: Colors.black54, size: 20),
              const SizedBox(width: 8),
              Text(
                '${AppTranslations.pastOrdersMobile} (${pastOrders.length})',
                style: const TextStyle(
                  fontSize: 20, // Increased from 16 to 20
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              if (pastOrders.isNotEmpty)
                Text(
                  '\$${pastOrdersTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20, // Increased from 16 to 20
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (pastOrders.isEmpty)
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text(
                  AppTranslations.noData,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 18, // Increased from 14 to 18
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 65,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: productList.length,
                itemBuilder: (context, index) {
                  final product = productList[index];
                  return GestureDetector(
                    onTap: onTap,
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: currentUser.color.withOpacity(0.15), // Light user color for past order items
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentUser.color.withOpacity(0.3), // Light user color border
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // Prevent overflow
                        children: [
                          Text(
                            _trimProductName(product['name'] as String),
                            style: const TextStyle(
                              fontSize: 12, // Increased from 9 to 12
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2), // Increased from 1 to 2
                          Text(
                            'x${product['quantity']}',
                            style: const TextStyle(
                              fontSize: 14, // Increased from 11 to 14
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF000000),
                            ),
                          ),
                          const SizedBox(height: 2), // Increased from 1 to 2
                          Text(
                            '\$${(product['total'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10, // Increased from 7 to 10
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
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
