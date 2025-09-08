import 'package:flutter/material.dart';

class NumberButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;

  const NumberButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFFFFF), // White background
        foregroundColor: const Color(0xFF000000), // Black text
        disabledBackgroundColor: const Color(0xFFF0F0F0),
        disabledForegroundColor: const Color(0xFF999999),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Increased from 12 to 16
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Increased padding
        minimumSize: const Size(80, 80), // Increased minimum size
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 32, // Increased from 24 to 32
          fontWeight: FontWeight.w600, // Increased from w500 to w600
        ),
      ),
    );
  }
}
