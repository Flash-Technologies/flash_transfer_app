import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final bool isLoading;
  final bool isDisabled;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFFFC000),
    this.textColor = const Color(0xFF181F30),
    this.borderColor,
    this.isLoading = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isLoading && !widget.isDisabled;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? widget.onPressed : null,
        onTapDown: isInteractive
            ? (_) {
                setState(() {
                  _isPressed = true;
                });
              }
            : null,
        onTapUp: isInteractive
            ? (_) {
                setState(() {
                  _isPressed = false;
                });
              }
            : null,
        onTapCancel: isInteractive
            ? () {
                setState(() {
                  _isPressed = false;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Ink(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? widget.backgroundColor.withOpacity(0.5)
                : widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1.5)
                : null,
            boxShadow: _isPressed || widget.isDisabled || widget.borderColor != null
                ? null
                : [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
                    ),
                  )
                : Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.isDisabled
                          ? widget.textColor.withOpacity(0.5)
                          : widget.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    ).animate(target: _isPressed ? 1 : 0)
      .scale(end: const Offset(0.97, 0.97), duration: 100.ms);
  }
}