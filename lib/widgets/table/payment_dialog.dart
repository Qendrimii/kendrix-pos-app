import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/providers.dart';
import '../../utils/translations.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final List<Order> orders;
  final String tableId;
  final String tableName;
  final VoidCallback onPaymentComplete;

  const PaymentDialog({
    super.key,
    required this.orders,
    required this.tableId,
    required this.tableName,
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
  bool _isProcessingPayment = false;
  bool _printStaffEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchPaymentMethods();
    _loadPrintStaffSetting();
  }

  Future<void> _loadPrintStaffSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _printStaffEnabled = prefs.getBool('print_staff') ?? false;
    });
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
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: screenSize.width * 0.95,
        height: screenSize.height * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.payment,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _isProcessingPayment ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table & Order info
                    Row(
                      children: [
                        _infoCard(
                          icon: Icons.table_restaurant,
                          label: AppTranslations.table,
                          value: widget.tableName,
                        ),
                        const SizedBox(width: 16),
                        _infoCard(
                          icon: Icons.receipt_long,
                          label: AppTranslations.orders,
                          value: '${widget.orders.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Total
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            AppTranslations.total,
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Payment Method
                    Text(
                      AppTranslations.paymentMethod,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: paymentMethods.map((method) {
                        final isSelected = selectedPaymentMethodId == method['id'];
                        return ChoiceChip(
                          label: Text(
                            method['name'] ?? method['code'] ?? '',
                            style: const TextStyle(fontSize: 16),
                          ),
                          selected: isSelected,
                          onSelected: _isProcessingPayment ? null : (_) {
                            setState(() {
                              selectedPaymentMethodId = method['id'];
                            });
                          },
                          selectedColor: const Color(0xFF000000),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Cash input (only for cash payment id == 1)
                    if (selectedPaymentMethodId == 1) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cashController,
                              decoration: InputDecoration(
                                labelText: AppTranslations.cashReceived,
                                prefixText: '\$',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 18),
                              onChanged: (value) {
                                setState(() {
                                  cashReceived = double.tryParse(value) ?? 0.0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(AppTranslations.fullPayment),
                          ),
                        ],
                      ),
                      if (change >= 0 && cashReceived > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF4CAF50)),
                          ),
                          child: Text(
                            '${AppTranslations.change}: \$${change.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom action buttons (always visible)
            const Divider(height: 24, thickness: 1),
            Text(
              AppTranslations.completePayment,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Paguaj button - only visible when print_staff setting is ON
                if (_printStaffEnabled) ...[
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isProcessingPayment || !_canProcessPayment(total))
                            ? null
                            : () => _processKitchenPayment(total),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        child: _isProcessingPayment
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Paguaj'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Kupon Fiskal button - always visible
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isProcessingPayment || !_canProcessPayment(total))
                          ? null
                          : () => _processPayment(total),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.green[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      child: _isProcessingPayment
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Kupon Fiskal'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _isProcessingPayment ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: Text(AppTranslations.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
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
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);
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
            content: Text('${AppTranslations.paymentCompletedWithChange} \$${(cashReceived - total).toStringAsFixed(2)}'),
            backgroundColor: const Color(0xFF006400),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      widget.onPaymentComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.paymentFailed}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _processKitchenPayment(double total) async {
    if (selectedPaymentMethodId == null) return;
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);
    try {
      final api = ApiService();
      await api.processKitchenSale(widget.tableId, selectedPaymentMethodId!);
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
            content: Text('${AppTranslations.kitchenPaymentCompleted} \$${(cashReceived - total).toStringAsFixed(2)}'),
            backgroundColor: const Color(0xFF000000),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      widget.onPaymentComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppTranslations.kitchenPaymentFailed}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
