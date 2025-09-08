import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/providers.dart';
import '../../utils/translations.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final List<Order> orders;
  final String tableId;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.orders,
    required this.tableId,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final TextEditingController _cashController = TextEditingController();
  double cashReceived = 0.0;
  int? selectedPaymentMethodId;
  List<Map<String, dynamic>> paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentMethods() async {
    final api = ApiService();
    try {
      final result = await api.getPaymentMethods();
      setState(() {
        paymentMethods = result;
        if (paymentMethods.isNotEmpty) {
          selectedPaymentMethodId = paymentMethods.first['id'];
        }
      });
    } catch (e) {
      // Handle error (show message, etc.)
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.orders.fold<double>(0, (sum, order) => sum + order.total);
    final change = cashReceived - total;

    return AlertDialog(
      title: Text(
        AppTranslations.payment,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // Increased font size
      ),
      content: SizedBox(
        width: 400, // Increased from 350 to 400 for better spacing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppTranslations.table}: ${widget.tableId}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // Increased font size
            ),
            Text(
              '${AppTranslations.orders}: ${widget.orders.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // Increased font size
            ),
            const SizedBox(height: 20), // Increased from 16 to 20
            Text(
              '${AppTranslations.total}: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24, // Increased from 18 to 24
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20), // Increased from 16 to 20
            Text(
              AppTranslations.paymentMethod,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Increased font size
            ),
            const SizedBox(height: 12), // Increased from 8 to 12
            Wrap(
              spacing: 16, // Increased from 12 to 16 for better separation
              runSpacing: 12, // Add vertical spacing between rows
              children: paymentMethods.map((method) {
                final isSelected = selectedPaymentMethodId == method['id'];
                return ChoiceChip(
                  label: Text(
                    method['name'] ?? method['code'] ?? '',
                    style: TextStyle(fontSize: 16), // Increased font size
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      selectedPaymentMethodId = method['id'];
                    });
                  },
                  selectedColor: const Color(0xFF000000),
                  backgroundColor: Colors.grey[300],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 16, // Increased font size
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased padding for better touch targets
                  materialTapTargetSize: MaterialTapTargetSize.padded, // Ensures proper touch target size
                );
              }).toList(),
            ),
            const SizedBox(height: 20), // Increased from 16 to 20
            // Show cash input only for cash payment (id == 1)
            if (selectedPaymentMethodId == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cashController,
                      decoration: const InputDecoration(
                        labelText: 'Cash received',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased padding
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          cashReceived = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12), // Increased from 8 to 12
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        cashReceived = total;
                        _cashController.text = total.toStringAsFixed(2);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // Increased padding
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), // Increased font size
                    ),
                    child: const Text('Full Payment'),
                  ),
                ],
              ),
              if (change >= 0 && cashReceived > 0) ...[
                const SizedBox(height: 16),
                Text(
                  '${AppTranslations.change}: \$${change.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20, // Increased from 16 to 20
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppTranslations.cancel,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // Increased font size
          ),
        ),
        ElevatedButton(
          onPressed: _canProcessPayment(total) ? () => _processPayment(total) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32), // Increased padding
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), // Increased font size
          ),
          child: Text(AppTranslations.completePayment),
        ),
      ],
    );
  }

  bool _canProcessPayment(double total) {
    if (selectedPaymentMethodId == 1) {
      return cashReceived >= total;
    } else {
      return selectedPaymentMethodId != null;
    }
  }

  void _processPayment(double total) async {
    if (selectedPaymentMethodId == null) return;
    try {
      final api = ApiService();
      await api.processCustomerSale(widget.tableId, selectedPaymentMethodId!);
      // Close all orders
      for (final order in widget.orders) {
        ref.read(ordersProvider.notifier).closeOrder(order.id);
      }
      // Free the table - single API call with null waiterId
      ref.read(hallsProvider.notifier).assignWaiter(widget.tableId, null);
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment completed! Change: \$${(cashReceived - total).toStringAsFixed(2)}'),
            backgroundColor: const Color(0xFF000000),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      widget.onPaymentComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
