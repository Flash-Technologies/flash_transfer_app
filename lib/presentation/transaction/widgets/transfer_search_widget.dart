
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/tracking_provider.dart';

class TransferSearchWidget extends ConsumerStatefulWidget {
  final Function(String)? onSearch;
  final String? initialQuery;

  const TransferSearchWidget({
    super.key,
    this.onSearch,
    this.initialQuery,
  });

  @override
  ConsumerState<TransferSearchWidget> createState() => _TransferSearchWidgetState();
}

class _TransferSearchWidgetState extends ConsumerState<TransferSearchWidget> {
  late TextEditingController _searchController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
      
      widget.onSearch?.call(query);
      
      // Reset searching state after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (_) => _performSearch(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Enter tracking number (FTN)',
          hintStyle: const TextStyle(
            color: Color(0xFF6E757D),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
          suffixIcon: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    ).animate().slideY(
      begin: -0.5,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    );
  }
}
