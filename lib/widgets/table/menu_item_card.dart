import 'package:flutter/material.dart';
import '../../models/models.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color userColor;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onLongPress,
    required this.userColor,
  });

  @override
  Widget build(BuildContext context) {
      String _trimProductName(String name) {
    if (name.length > 15) {
      return '${name.substring(0, 15)}...';
    }
    return name;
  }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(3.0), // Reduced from 8.0 to 3.0 to save space
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Prevent overflow
            children: [
              Text(
                _trimProductName(item.name),
                style: const TextStyle(
                  fontWeight: FontWeight.w600, // Increased from w500 to w600
                  fontSize: 14, // Reduced to fit better and prevent overflow
                  color: Color(0xFF000000), // Black text
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2), // Reduced from 4 to 2 to save space
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14, // Restored to original 14
                  fontWeight: FontWeight.bold,
                  color: userColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
