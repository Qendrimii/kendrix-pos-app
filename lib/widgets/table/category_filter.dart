import 'package:flutter/material.dart';
import '../../utils/translations.dart';

class CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Increased from 60 to 80 for bigger buttons
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased vertical padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) => onCategorySelected(category),
              backgroundColor: const Color(0xFFFFFFFF), // White
              selectedColor: const Color(0xFF000000), // Black when selected
              labelStyle: TextStyle(
                color: isSelected 
                    ? const Color(0xFFFFFFFF) // White text when selected
                    : const Color(0xFF000000), // Black text when not selected
                fontWeight: FontWeight.w600,
                fontSize: 18, // Increased from 16 to 18 for mobile
              ),
              checkmarkColor: const Color(0xFFFFFFFF), // White checkmark
              side: BorderSide(
                color: isSelected 
                    ? const Color(0xFF000000) 
                    : const Color(0xFFE0E0E0),
                width: 2, // Increased from 1 to 2 for better visibility
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Increased padding for mobile
            ),
          );
        },
      ),
    );
  }
}
