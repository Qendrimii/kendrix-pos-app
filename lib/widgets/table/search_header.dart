import 'package:flutter/material.dart';
import '../../utils/translations.dart';
import 'package:go_router/go_router.dart';

class SearchHeader extends StatefulWidget {
  final String tableName;
  final Function(String) onSearchChanged;
  final bool isSearching;
  final VoidCallback? onBack;

  const SearchHeader({
    super.key,
    required this.tableName,
    required this.onSearchChanged,
    required this.isSearching,
    this.onBack,
  });

  @override
  State<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends State<SearchHeader> {
  late FocusNode _searchFocusNode;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack ?? () => context.go('/halls'),
          iconSize: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.tableName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        // Search bar in header
        Container(
          width: 300, // Fixed width for search bar
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: widget.onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: AppTranslations.searchHint,
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: widget.isSearching 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            // Enable text selection and cursor
            enableInteractiveSelection: true,
            // Show keyboard on tap
            onTap: () {
              _searchFocusNode.requestFocus();
            },
          ),
        ),
      ],
    );
  }
}
