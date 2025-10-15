
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';

class ErrorBoundaryWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundaryWidget> createState() => _ErrorBoundaryWidgetState();
}

class _ErrorBoundaryWidgetState extends State<ErrorBoundaryWidget> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace!);
      } else {
        return _DefaultErrorWidget(
          error: _error!,
          onRetry: () {
            setState(() {
              _error = null;
              _stackTrace = null;
            });
          },
        );
      }
    }

    return ErrorBoundary(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
        widget.onError?.call(error, stackTrace);
      },
      child: widget.child,
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _DefaultErrorWidget extends ConsumerWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationHelperProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            tr('common.error.title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr('common.error.subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC000),
              foregroundColor: const Color(0xFF181F30),
            ),
            child: Text(tr('common.error.tryAgain')),
          ),
        ],
      ),
    );
  }
}
