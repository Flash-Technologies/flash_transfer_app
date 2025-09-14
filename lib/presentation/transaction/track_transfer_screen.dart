import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../providers/tracking_provider.dart';
import 'individual_transaction_screen.dart';

class TrackTransferScreen extends ConsumerStatefulWidget {
  const TrackTransferScreen({super.key});

  @override
  ConsumerState<TrackTransferScreen> createState() =>
      _TrackTransferScreenState();
}

class _TrackTransferScreenState extends ConsumerState<TrackTransferScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _shakeAnimationController;

  late Animation<Offset> _headerSlideAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _shakeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _trackingController = TextEditingController();
  final FocusNode _trackingFocus = FocusNode();

  String? _validationError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutBack,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeAnimationController,
      curve: Curves.elasticInOut,
    ));
  }

  void _startAnimations() {
    _headerAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _formAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _formAnimationController.dispose();
    _shakeAnimationController.dispose();
    _trackingController.dispose();
    _trackingFocus.dispose();
    super.dispose();
  }


  void _validateAndSubmit() async {
    final trackingNumber = _trackingController.text.trim();

    setState(() {
      _validationError = null;
    });

    if (trackingNumber.isEmpty) {
      _showValidationError('Please enter a tracking number');
      return;
    }

    if (trackingNumber.length < 10) {
      _showValidationError('Tracking number must be at least 10 characters');
      return;
    }

    // Validate format (enhanced for the new API format)
    final isValidFormat =
        RegExp(r'^[A-Z0-9-]{10,25}$').hasMatch(trackingNumber.toUpperCase());
    if (!isValidFormat) {
      _showValidationError('Invalid tracking number format');
      return;
    }

    HapticFeedback.lightImpact();

    try {
      final result = await ref.read(trackingProvider.notifier).trackTransfer(
            trackingNumber: trackingNumber.toUpperCase(),
          );

      if (result && mounted) {
        HapticFeedback.mediumImpact();

        final transaction = ref.read(transactionProvider);

        if (transaction != null) {
          // Navigate to individual transaction details screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => IndividualTransactionScreen(
                transactionId: transaction.id,
                transaction: transaction,
              ),
            ),
          );
        } else {
          // Show success message if transaction found but loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Transfer found! Loading details...'),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      _showValidationError('Sorry, no transaction found for this tracking ID. Please check the tracking number and try again.');
    }
  }

  void _showValidationError(String message) {
    setState(() {
      _validationError = message;
    });

    HapticFeedback.heavyImpact();

    // Trigger shake animation
    _shakeAnimationController.reset();
    _shakeAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Column(
        children: [
          // Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: const Duration(milliseconds: 400),
                        duration: const Duration(milliseconds: 400),
                      ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track a Transfer',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF181F30),
                        ),
                      ).animate().fadeIn(
                            delay: const Duration(milliseconds: 500),
                            duration: const Duration(milliseconds: 600),
                          ),
                      const SizedBox(height: 12),
                      Text(
                        'Home is behind, the world ahead and there are many paths to tread through shadows to the edge.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6E757D),
                          height: 1.6,
                        ),
                      ).animate().fadeIn(
                            delay: const Duration(milliseconds: 600),
                            duration: const Duration(milliseconds: 600),
                          ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Form
                  SlideTransition(
                    position: _formSlideAnimation,
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_shakeAnimation.value, 0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Input Label
                                  Text(
                                    'Enter Tracking Number',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF181F30),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Input Field
                                  Focus(
                                    onFocusChange: (hasFocus) {
                                      if (hasFocus) {
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _validationError = null;
                                        });
                                      }
                                    },
                                    child: TextFormField(
                                      controller: _trackingController,
                                      focusNode: _trackingFocus,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        color: const Color(0xFF181F30),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Flash Tracking Number (FTN)',
                                        hintStyle: TextStyle(
                                          color: const Color(0xFF6E757D),
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          letterSpacing: 0,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _validationError != null
                                                ? Colors.red.shade400
                                                : const Color(0xFFD3D8DD),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _validationError != null
                                                ? Colors.red.shade400
                                                : const Color(0xFFD3D8DD),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: _validationError != null
                                                ? Colors.red.shade400
                                                : const Color(0xFFFFC000),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        suffixIcon: _validationError != null
                                            ? Container(
                                                margin:
                                                    const EdgeInsets.all(12),
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade400,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.priority_high,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        if (_validationError != null) {
                                          setState(() {
                                            _validationError = null;
                                          });
                                        }
                                      },
                                      onFieldSubmitted: (_) =>
                                          _validateAndSubmit(),
                                    ),
                                  ),

                                  // Error Message
                                  if (_validationError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _validationError!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ).animate().fadeIn().shake(),
                                  ],

                                  const SizedBox(height: 24),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: trackingState.isLoading
                                          ? null
                                          : _validateAndSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFFC000),
                                        foregroundColor:
                                            const Color(0xFF181F30),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                        disabledBackgroundColor:
                                            Colors.grey.shade300,
                                      ),
                                      child: trackingState.isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  const Color(0xFF181F30),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().scale(
                        delay: const Duration(milliseconds: 800),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
