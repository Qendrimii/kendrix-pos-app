import 'package:flutter/material.dart';

class PinDisplay extends StatelessWidget {
  final String pin;
  final int maxLength;

  const PinDisplay({
    super.key,
    required this.pin,
    this.maxLength = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12), // Increased from 8 to 12
          width: 28, // Increased from 20 to 28
          height: 28, // Increased from 20 to 28
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length 
                ? const Color(0xFF000000) // Black for filled
                : const Color(0xFFE0E0E0), // Light grey for empty
          ),
        );
      }),
    );
  }
}
