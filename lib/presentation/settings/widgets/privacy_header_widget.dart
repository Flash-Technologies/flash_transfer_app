import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

// Privacy Header Widget
class PrivacyHeaderWidget extends StatefulWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onSearchPressed;
  final bool isSearchMode;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const PrivacyHeaderWidget({
    super.key,
    required this.onBackPressed,
    required this.onSearchPressed,
    required this.isSearchMode,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  State<PrivacyHeaderWidget> createState() => _PrivacyHeaderWidgetState();
}

class _PrivacyHeaderWidgetState extends State<PrivacyHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(PrivacyHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSearchMode != oldWidget.isSearchMode) {
      if (widget.isSearchMode) {
        _searchAnimationController.forward();
        _searchFocusNode.requestFocus();
      } else {
        _searchAnimationController.reverse();
        _searchFocusNode.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService.instance;

    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main header row
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onBackPressed();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        translationService.translate('privacy.screen.back'),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 400),
              ),

              const SizedBox(width: 16),

              // Title
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      widget.isSearchMode
                          ? const SizedBox.shrink()
                          : Text(
                            translationService.translate(
                              'privacy.screen.title',
                            ),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181F30),
                            ),
                          ).animate().fadeIn(
                            delay: const Duration(milliseconds: 500),
                            duration: const Duration(milliseconds: 400),
                          ),
                ),
              ),

              // Search button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onSearchPressed();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        widget.isSearchMode
                            ? const Color(0xFF2475FF)
                            : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.isSearchMode ? Icons.close : Icons.search,
                    size: 20,
                    color:
                        widget.isSearchMode ? Colors.white : Colors.grey[700],
                  ),
                ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 400),
              ),
            ],
          ),

          // Search bar
          AnimatedBuilder(
            animation: _searchAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _searchAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextField(
                    controller: widget.searchController,
                    focusNode: _searchFocusNode,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: translationService.translate(
                        'privacy.screen.search',
                      ),
                      hintStyle: const TextStyle(
                        color: Color(0xFF6E757D),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF6E757D),
                        size: 20,
                      ),
                      suffixIcon:
                          widget.searchController.text.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  widget.searchController.clear();
                                  widget.onSearchChanged('');
                                  HapticFeedback.lightImpact();
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF6E757D),
                                  size: 20,
                                ),
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEBECED)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2475FF),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF181F30),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
