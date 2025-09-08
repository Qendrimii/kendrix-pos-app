import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/translations.dart';

class MobileBottomBar extends StatelessWidget {
  final Waiter currentUser;
  final Order? activeOrder;
  final List<Order> tableOrders;
  final VoidCallback onPrintOrder;
  final VoidCallback? onShowPayment;

  const MobileBottomBar({
    super.key,
    required this.currentUser,
    required this.activeOrder,
    required this.tableOrders,
    required this.onPrintOrder,
    this.onShowPayment,
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Log button visibility status
    if (activeOrder?.items.isNotEmpty ?? false) {
      print('✅ Order button visible - activeOrder: ${activeOrder?.id}, items: ${activeOrder?.items.length}');
    } else {
      print('❌ Order button hidden - activeOrder null or empty: activeOrder=${activeOrder?.id}, items=${activeOrder?.items.length}');
    }
    
    // Check if payment button should be enabled
    final hasPastOrders = tableOrders.where((order) => !order.id.startsWith('temp_')).isNotEmpty;
    final hasCurrentOrders = tableOrders.any((order) => 
      order.id.startsWith('temp_') && order.items.isNotEmpty
    );
    final canShowPayment = hasPastOrders && !hasCurrentOrders && onShowPayment != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (activeOrder?.items.isNotEmpty ?? false) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: activeOrder != null ? () {
                  print('🔘 Order button clicked - activeOrder: ${activeOrder?.id}, items: ${activeOrder?.items.length}');
                  onPrintOrder();
                } : null,
                icon: const Icon(Icons.print, size: 20),
                label: Text(AppTranslations.order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentUser.color, // Use user's color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24), // Increased padding for mobile
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600), // Increased font size
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canShowPayment ? onShowPayment : null,
              icon: const Icon(Icons.payment, size: 20),
                              label: Text(AppTranslations.paymentButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: canShowPayment ? currentUser.color : Colors.grey, // Use user's color when enabled
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24), // Increased padding for mobile
                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600), // Increased font size
              ),
            ),
          ),
        ],
      ),
    );
  }
}
