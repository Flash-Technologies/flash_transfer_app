import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/transaction_model.dart';
import '../../../core/services/translation_service.dart';

class PrivacySectionWidget extends StatefulWidget {
  final PrivacySectionModel section;
  final bool isHighlighted;
  final String searchQuery;
  final VoidCallback onToggleExpanded;

  const PrivacySectionWidget({
    super.key,
    required this.section,
    this.isHighlighted = false,
    this.searchQuery = '',
    required this.onToggleExpanded,
  });

  @override
  State<PrivacySectionWidget> createState() => _PrivacySectionWidgetState();
}

class _PrivacySectionWidgetState extends State<PrivacySectionWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _highlightController;
  late Animation<double> _expandAnimation;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    
    _highlightAnimation = ColorTween(
      begin: Colors.transparent,
      end: const Color(0xFFFFC000).withOpacity(0.2),
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));

    if (widget.section.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PrivacySectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.section.isExpanded != oldWidget.section.isExpanded) {
      if (widget.section.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
    
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      if (widget.isHighlighted) {
        _highlightController.forward();
      } else {
        _highlightController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_expandAnimation, _highlightAnimation]),
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _highlightAnimation.value,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                GestureDetector(
                  onTap: widget.onToggleExpanded,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _highlightText(widget.section.title),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181F30),
                          ),
                        ),
                      ),
                      
                      if (widget.section.subsections != null)
                        AnimatedRotation(
                          turns: widget.section.isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF6E757D),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Section content
                Text(
                  _highlightText(widget.section.content),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6E757D),
                    height: 1.6,
                  ),
                ),
                
                // Subsections
                if (widget.section.subsections != null)
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        ...widget.section.subsections!.map((subsection) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFEBECED),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _highlightText(subsection.title),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF181F30),
                                  ),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Text(
                                  _highlightText(subsection.content),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6E757D),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ).animate()
                           .fadeIn(
                             delay: Duration(
                               milliseconds: widget.section.subsections!.indexOf(subsection) * 100,
                             ),
                             duration: const Duration(milliseconds: 300),
                           )
                           .slideY(begin: 0.3);
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _highlightText(String text) {
    // In a real implementation, you would highlight the search query
    // For now, we'll just return the original text
    return text;
  }
}