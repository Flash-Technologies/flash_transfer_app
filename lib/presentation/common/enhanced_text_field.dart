
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EnhancedTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool required;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final int animationDelay;
  final bool showCharacterCount;

  const EnhancedTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.required = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.animationDelay = 0,
    this.showCharacterCount = false,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _focusAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(EnhancedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _hasError = widget.errorText != null;
      });
    }
  }

  void _onFocusChanged() {
    final isFocused = widget.focusNode.hasFocus;
    
    if (isFocused != _isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      
      if (isFocused) {
        HapticFeedback.selectionClick();
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    _animationController.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (_hasError) return Colors.red.shade400;
    if (_isFocused) return const Color(0xFFFFC000);
    return const Color(0xFFEBECED);
  }

  Color get _backgroundColor {
    if (!widget.enabled) return Colors.grey[100]!;
    if (_isFocused) return Colors.white;
    return Colors.grey[50]!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _focusAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                widget.label + (widget.required ? ' *' : ''),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hasError
                      ? Colors.red.shade600
                      : const Color(0xFF181F30),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Text Field
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _borderColor,
                    width: _isFocused ? 2 : 1,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFC000).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  onTap: widget.onTap,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.enabled
                        ? const Color(0xFF181F30)
                        : Colors.grey[600],
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: const Color(0xFF6E757D),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.suffixIcon,
                    counterText: widget.showCharacterCount ? null : '',
                  ),
                ),
              ),
              
              // Error Text
              if (_hasError) ...[
                const SizedBox(height: 6),
                Text(
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn().shake(),
              ],
              
              // Character Count (if enabled)
              if (widget.showCharacterCount && widget.maxLength != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.controller.text.length}/${widget.maxLength}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    ).animate().slideX(
      begin: -1,
      delay: Duration(milliseconds: widget.animationDelay),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
    );
  }
}