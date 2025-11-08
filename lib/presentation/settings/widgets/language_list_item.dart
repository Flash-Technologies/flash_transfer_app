import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/language_model.dart';

class LanguageListItem extends StatefulWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageListItem({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<LanguageListItem> createState() => _LanguageListItemState();
}

class _LanguageListItemState extends State<LanguageListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : _isPressed
                        ? Colors.grey.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : Border.all(
                        color: Colors.transparent,
                        width: 2,
                      ),
              ),
              child: Row(
                children: [
                  // Flag placeholder (will be replaced with actual flags)
                  Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[300],
                      border: Border.all(
                        color: Colors.grey[400]!,
                        width: 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        widget.language.flagAsset,
                        width: 32,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Failed to load flag: ${widget.language.flagAsset}, Error: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.flag_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Language info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.language.name,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: widget.isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: widget.isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        if (widget.language.nativeName != widget.language.name) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.language.nativeName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ).animate().scale(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}