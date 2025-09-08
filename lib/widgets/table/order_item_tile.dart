import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/translations.dart';

class OrderItemTile extends StatefulWidget {
  final OrderItem item;
  final int index;
  final VoidCallback onRemove;
  final Color userColor;
  final Function(int index, String comment)? onCommentUpdate;
  final Function(int index, int quantity)? onQuantityUpdate;

  const OrderItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.userColor,
    this.onCommentUpdate,
    this.onQuantityUpdate,
  });

  @override
  State<OrderItemTile> createState() => _OrderItemTileState();
}

class _OrderItemTileState extends State<OrderItemTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showEditDialog(context),
      child: Container(
        margin: EdgeInsets.zero, // Remove margin
        padding: EdgeInsets.zero, // Remove padding
        decoration: const BoxDecoration(
          // No background color - let parent container styling show through
          // No border radius - let parent container handle it
          // No border - let parent container handle it
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16, // Increased from 14 to 16
                    ),
                  ),
                  if (widget.item.comment?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4), // Increased from 2 to 4
                    Text(
                      'Note: ${widget.item.comment}',
                      style: TextStyle(
                        fontSize: 14, // Increased from 12 to 14
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6), // Increased from 4 to 6
                  Text(
                    '\$${widget.item.price.toStringAsFixed(2)} × ${widget.item.quantity}',
                    style: TextStyle(
                      fontSize: 14, // Increased from 12 to 14
                      color: widget.userColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(widget.item.price * widget.item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increased from 14 to 16
                  ),
                ),
                const SizedBox(height: 6), // Increased from 4 to 6
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  iconSize: 28, // Increased from 20 to 28
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32, // Increased from 24 to 32
                    minHeight: 32, // Increased from 24 to 32
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final commentController = TextEditingController(text: widget.item.comment ?? '');
    int currentQuantity = widget.item.quantity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${AppTranslations.editItem} ${widget.item.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: AppTranslations.commentOptional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentQuantity > 1 ? () {
                      setState(() => currentQuantity--);
                    } : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currentQuantity.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => currentQuantity++);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppTranslations.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.onCommentUpdate != null) {
                  widget.onCommentUpdate!(widget.index, commentController.text);
                }
                if (widget.onQuantityUpdate != null && currentQuantity != widget.item.quantity) {
                  widget.onQuantityUpdate!(widget.index, currentQuantity);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000000),
                foregroundColor: Colors.white,
              ),
              child: Text(AppTranslations.update),
            ),
          ],
        ),
      ),
    );
  }
}
