
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LazyLoadingWidget extends ConsumerStatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Widget? placeholder;
  final Duration delay;
  final bool preload;

  const LazyLoadingWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.delay = const Duration(milliseconds: 100),
    this.preload = false,
  });

  @override
  ConsumerState<LazyLoadingWidget> createState() => _LazyLoadingWidgetState();
}

class _LazyLoadingWidgetState extends ConsumerState<LazyLoadingWidget> {
  bool _isLoaded = false;
  Widget? _cachedWidget;

  @override
  void initState() {
    super.initState();
    if (widget.preload) {
      _loadWidget();
    }
  }

  void _loadWidget() {
    if (_isLoaded) return;
    
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _cachedWidget = widget.builder(context);
          _isLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      if (!widget.preload) {
        _loadWidget();
      }
      
      return widget.placeholder ??
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    return _cachedWidget!;
  }
}
