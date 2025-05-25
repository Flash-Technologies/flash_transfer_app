import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isLoading;
  final bool disabled;
  final EdgeInsets? padding;
  final BoxBorder? border;
  final Duration animationDuration;

  const AnimatedButton({
    super.key,
    this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.isLoading = false,
    this.disabled = false,
    this.padding,
    this.border,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isEnabled) return;

    setState(() {
      _isPressed = true;
    });

    HapticFeedback.lightImpact();
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!_isEnabled) return;

    setState(() {
      _isPressed = false;
    });

    _animationController.reverse();
  }

  void _onTapCancel() {
    if (!_isEnabled) return;

    setState(() {
      _isPressed = false;
    });

    _animationController.reverse();
  }

  bool get _isEnabled =>
      widget.onPressed != null && !widget.disabled && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: _isEnabled ? widget.onPressed : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                height: widget.height,
                padding:
                    widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      _isEnabled
                          ? (widget.backgroundColor ??
                              Theme.of(context).primaryColor)
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: widget.border,
                  boxShadow:
                      _isEnabled && !_isPressed
                          ? [
                            BoxShadow(
                              color: (widget.backgroundColor ??
                                      Theme.of(context).primaryColor)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child:
                    widget.isLoading
                        ? Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.foregroundColor ?? Colors.white,
                              ),
                            ),
                          ),
                        )
                        : DefaultTextStyle(
                          style: TextStyle(
                            color:
                                _isEnabled
                                    ? (widget.foregroundColor ?? Colors.white)
                                    : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                          child: widget.child,
                        ),
              ),
            ),
          ),
        );
      },
    );
  }
}
