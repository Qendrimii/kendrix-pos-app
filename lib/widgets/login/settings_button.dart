import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SettingsButton({
    super.key, 
    required this.onPressed
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF666666), // Grey background
        foregroundColor: const Color(0xFFFFFFFF), // White icon
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Increased from 12 to 16
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Added padding
        minimumSize: const Size(80, 80), // Added minimum size
      ),
      child: const Icon(
        Icons.settings,
        size: 32, // Increased from 24 to 32
      ),
    );
  }
}
