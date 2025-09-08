import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/translations.dart';

class PreviousOrdersSection extends StatelessWidget {
  final List<Order> previousOrders;
  final VoidCallback onTap;

  const PreviousOrdersSection({
    super.key,
    required this.previousOrders,
    required this.onTap,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Previous Orders header
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF6F6F6),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                AppTranslations.previousOrders,
                style: TextStyle(
                  fontSize: 22, // Increased from 18 to 22
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (previousOrders.isNotEmpty)
                Text(
                  '\$${previousOrders.fold<double>(0, (sum, order) => sum + order.total).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20, // Increased from 16 to 20
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
            ],
          ),
        ),
        // Previous Orders Content
        Expanded(
          child: previousOrders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppTranslations.noData,
                        style: TextStyle(
                          fontSize: 20, // Increased from 16 to 20
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        AppTranslations.loadingData,
                        style: TextStyle(
                          fontSize: 18, // Increased from 14 to 18
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          // Combined icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.history,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Combined details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppTranslations.previousOrders,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${previousOrders.length} ${AppTranslations.orders} • ${previousOrders.fold(0, (sum, order) => sum + order.items.length)} ${AppTranslations.total} ${AppTranslations.items}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                if (previousOrders.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${AppTranslations.lastOrder}: ${_formatDateTime(previousOrders.first.createdAt ?? DateTime.now())}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Combined total
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${previousOrders.fold<double>(0, (sum, order) => sum + order.total).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
