import 'package:flutter/material.dart';

class BackspaceButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const BackspaceButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF000000), // Black background
        foregroundColor: const Color(0xFFFFFFFF), // White icon
        disabledBackgroundColor: const Color(0xFF999999),
        disabledForegroundColor: const Color(0xFFCCCCCC),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Increased from 12 to 16
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Added padding
        minimumSize: const Size(80, 80), // Added minimum size
      ),
      child: const Icon(
        Icons.backspace_outlined,
        size: 32, // Increased from 24 to 32
      ),
    );
  }
}
