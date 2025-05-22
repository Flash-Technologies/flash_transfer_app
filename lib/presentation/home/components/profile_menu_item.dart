

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flash_transfer_app/config/constants.dart';

class ProfileMenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isLoading;
  final Widget? trailing;
  final Color? iconColor;

  const ProfileMenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.isLoading = false,
    this.trailing,
    this.iconColor,
  });
}

class ProfileMenuItem extends StatefulWidget {
  final ProfileMenuItemData data;
  final int delay;

  const ProfileMenuItem({
    super.key,
    required this.data,
    this.delay = 0,
  });

  @override
  State<ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<ProfileMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 60.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildMenuItem(),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.data.isLoading ? null : () {
        HapticFeedback.selectionClick();
        widget.data.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isPressed ? 0.96 : 1.0),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isPressed
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed
                ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.data.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: widget.data.isDestructive
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (widget.data.isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else if (widget.data.trailing != null)
              widget.data.trailing!
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.data.isDestructive
            ? Theme.of(context).colorScheme.error.withOpacity(0.1)
            : (widget.data.iconColor ?? Theme.of(context).colorScheme.primary)
                .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        widget.data.icon,
        size: 22,
        color: widget.data.isDestructive
            ? Theme.of(context).colorScheme.error
            : widget.data.iconColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}