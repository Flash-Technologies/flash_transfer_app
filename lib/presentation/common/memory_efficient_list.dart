import 'package:flutter/material.dart';

class MemoryEfficientList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double itemExtent;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final int cacheExtent;

  const MemoryEfficientList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemExtent,
    this.controller,
    this.padding,
    this.cacheExtent = 5,
  });

  @override
  State<MemoryEfficientList<T>> createState() => _MemoryEfficientListState<T>();
}

class _MemoryEfficientListState<T> extends State<MemoryEfficientList<T>> {
  final Map<int, Widget> _cachedWidgets = {};
  late ScrollController _scrollController;
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    final firstVisible = (scrollOffset / widget.itemExtent).floor();
    final lastVisible =
        ((scrollOffset + viewportHeight) / widget.itemExtent).ceil();

    if (firstVisible != _firstVisibleIndex ||
        lastVisible != _lastVisibleIndex) {
      setState(() {
        _firstVisibleIndex = firstVisible;
        _lastVisibleIndex = lastVisible;
      });

      _cleanupCache();
    }
  }

  void _cleanupCache() {
    final toRemove = <int>[];

    _cachedWidgets.forEach((index, cachedWidget) {
      if (index < _firstVisibleIndex - widget.cacheExtent ||
          index > _lastVisibleIndex + widget.cacheExtent) {
        toRemove.add(index);
      }
    });

    for (final index in toRemove) {
      _cachedWidgets.remove(index);
    }
  }

  Widget _buildItem(int index) {
    if (_cachedWidgets.containsKey(index)) {
      return _cachedWidgets[index]!;
    }

    final item = widget.items[index];
    final builtWidget = widget.itemBuilder(context, item, index);

    _cachedWidgets[index] = builtWidget;
    return builtWidget;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.items.length,
      itemExtent: widget.itemExtent,
      padding: widget.padding,
      cacheExtent: widget.cacheExtent * widget.itemExtent,
      itemBuilder: (context, index) => _buildItem(index),
    );
  }
}
