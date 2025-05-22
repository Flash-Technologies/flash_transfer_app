import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class LanguageSearchBar extends StatefulWidget {
  final Function(String) onChanged;
  final String? hintText;
  final Duration debounceDuration;

  const LanguageSearchBar({
    super.key,
    required this.onChanged,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<LanguageSearchBar> createState() => _LanguageSearchBarState();
}

class _LanguageSearchBarState extends State<LanguageSearchBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged(_controller.text);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged('');
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: _isFocused ? 2 : 1,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Search icon
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search,
                    color: _isFocused
                        ? Theme.of(context).primaryColor
                        : Colors.grey[500],
                    size: 24,
                  ),
                ),
              ),
              
              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Search languages...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    _focusNode.unfocus();
                  },
                ),
              ),
              
              // Clear button
              if (_controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedScale(
                    scale: _controller.text.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _clearSearch,
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ).animate().scale(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.elasticOut,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}