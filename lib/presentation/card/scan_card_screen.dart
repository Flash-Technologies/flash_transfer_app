import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/credit_card_model.dart';
import '../../core/utils/exceptions.dart';
import '../../providers/card_provider.dart';
import 'components/card_scanner_overlay.dart';

class ScanCardScreen extends ConsumerStatefulWidget {
  const ScanCardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScanCardScreen> createState() => _ScanCardScreenState();
}

class _ScanCardScreenState extends ConsumerState<ScanCardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  double? _scanProgress;

  late AnimationController _focusController;
  late Animation<double> _focusAnimation;

  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _focusAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _focusController, curve: Curves.easeOut));

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusController.dispose();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        throw CardScanException(
          message: 'Camera permission denied',
          type: CardScanErrorType.cameraPermissionDenied,
        );
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw CardScanException(
          message: 'No cameras available',
          type: CardScanErrorType.cameraNotAvailable,
        );
      }

      // Initialize camera controller
      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _handleCameraError(e);
    }
  }

  void _disposeCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
  }

  void _handleCameraError(dynamic error) {
    String message;
    if (error is CardScanException) {
      message = error.userFriendlyMessage;
    } else {
      message = 'Failed to initialize camera: ${error.toString()}';
    }

    _showErrorDialog(message);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Camera Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _startScanning() async {
    if (_isScanning || _cameraController == null) return;

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
    });

    try {
      // Simulate scanning progress
      for (int i = 0; i <= 100; i += 10) {
        if (!_isScanning) break;

        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _scanProgress = i / 100.0;
          });
        }
      }

      if (_isScanning) {
        // Start actual card scanning
        await ref.read(cardProvider.notifier).startCardScanning();

        final cardState = ref.read(cardProvider);
        if (cardState.scanResult != null && cardState.scanResult!.isValid) {
          _handleScanSuccess();
        } else {
          throw CardScanException(
            message: 'Failed to detect card details',
            type: CardScanErrorType.noCardDetected,
          );
        }
      }
    } catch (e) {
      _handleScanError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanProgress = null;
        });
      }
    }
  }

  void _handleScanSuccess() {
    // Show success feedback
    _showSuccessDialog();
  }

  void _handleScanError(dynamic error) {
    String message;
    if (error is CardScanException) {
      message = error.userFriendlyMessage;
    } else {
      message = 'Scanning failed: ${error.toString()}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Try Again',
          textColor: Colors.white,
          onPressed: _startScanning,
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text('Card Scanned!'),
              ],
            ),
            content: const Text(
              'Card details have been successfully captured. You can now review and complete the information.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop(); // Return to previous screen
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _onTapToFocus(TapDownDetails details) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final offset = details.localPosition;
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Convert tap position to camera coordinates
    final double x = offset.dx / size.width;
    final double y = offset.dy / size.height;

    setState(() {
      _focusPoint = offset;
    });

    _focusController.forward().then((_) {
      _focusController.reverse();
    });

    // Set camera focus
    _cameraController!.setFocusPoint(Offset(x, y));
    _cameraController!.setExposurePoint(Offset(x, y));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: _onTapToFocus,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            _buildCameraPlaceholder(),

          // Focus indicator
          if (_focusPoint != null)
            AnimatedBuilder(
              animation: _focusAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _focusPoint!.dx - 30,
                  top: _focusPoint!.dy - 30,
                  child: Opacity(
                    opacity: _focusAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFFFC000),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Scanner overlay
          CardScannerOverlay(
            onClose: () => context.pop(),
            instructionText: 'Position your card within the frame',
            isScanning: _isScanning,
            scanProgress: _scanProgress,
          ),

          // Scan button
          if (_isCameraInitialized && !_isScanning)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(child: _buildScanButton()),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC000)),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC000),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC000).withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: _startScanning,
          child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
        ),
      ),
    );
  }
}

// Camera permission handler
class CameraPermissionHandler {
  static Future<bool> checkAndRequestPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Open settings for user to manually enable permission
      await openAppSettings();
      return false;
    }

    return false;
  }
}

// Camera settings utility
class CameraSettings {
  static Future<void> optimizeForCardScanning(
    CameraController controller,
  ) async {
    try {
      // Set focus mode to auto
      await controller.setFocusMode(FocusMode.auto);

      // Set exposure mode to auto
      await controller.setExposureMode(ExposureMode.auto);

      // Enable flash if needed (usually not needed for cards)
      await controller.setFlashMode(FlashMode.off);
    } catch (e) {
      // Handle settings errors gracefully
      print('Camera settings error: $e');
    }
  }
}
