import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/translation_service.dart';

// Transaction Filter Widget
class TransactionFilterWidget extends StatefulWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const TransactionFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  State<TransactionFilterWidget> createState() =>
      _TransactionFilterWidgetState();
}

class _TransactionFilterWidgetState extends State<TransactionFilterWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _selectionController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _selectionAnimation;

  final List<String> _filters = [
    'all',
    'sent',
    'received',
    'thisMonth',
    'lastMonth',
  ];

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.elasticOut,
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _filters.map((filter) {
                  final isSelected = filter == widget.selectedFilter;
                  return _buildFilterChip(
                    filter,
                    translationService.translate('transaction.filters.$filter'),
                    isSelected,
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, bool isSelected) {
    return GestureDetector(
          onTap: () {
            if (!isSelected) {
              _selectionController.forward().then((_) {
                _selectionController.reverse();
              });
              widget.onFilterChanged(filter);
              HapticFeedback.selectionClick();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFC000) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  isSelected
                      ? null
                      : Border.all(color: Colors.grey[200]!, width: 1),
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? const Color(0xFF181F30)
                        : const Color(0xFF6E757D),
              ),
              child: Text(label),
            ),
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: const Duration(milliseconds: 100),
        );
  }
}
