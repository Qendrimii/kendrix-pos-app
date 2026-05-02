import 'package:flutter/material.dart';
import '../../models/models.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color userColor;

  const MenuItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    required this.userColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF000000),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  item.price.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: userColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
