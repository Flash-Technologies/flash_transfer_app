
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitorWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final void Function(double fps)? onFpsUpdate;

  const PerformanceMonitorWidget({
    super.key,
    required this.child,
    this.enabled = false,
    this.onFpsUpdate,
  });

  @override
  State<PerformanceMonitorWidget> createState() => _PerformanceMonitorWidgetState();
}

class _PerformanceMonitorWidgetState extends State<PerformanceMonitorWidget>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  int _frameCount = 0;
  Duration _lastTime = Duration.zero;
  double _currentFps = 60.0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _ticker = createTicker(_onTick);
      _ticker.start();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      _ticker.dispose();
    }
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    
    if (elapsed - _lastTime >= const Duration(seconds: 1)) {
      final fps = _frameCount / (elapsed - _lastTime).inMilliseconds * 1000;
      setState(() {
        _currentFps = fps;
      });
      
      widget.onFpsUpdate?.call(fps);
      _frameCount = 0;
      _lastTime = elapsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 40,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _currentFps >= 50 ? Colors.green : _currentFps >= 30 ? Colors.orange : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentFps.toStringAsFixed(1)} FPS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}