import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/credit_card_model.dart';
import '../../providers/card_provider.dart';
import 'components/card_input_form.dart';
import 'components/card_preview_widget.dart';

class EnterCardScreen extends ConsumerStatefulWidget {
  final CreditCard? existingCard;

  const EnterCardScreen({Key? key, this.existingCard}) : super(key: key);

  @override
  ConsumerState<EnterCardScreen> createState() => _EnterCardScreenState();
}

class _EnterCardScreenState extends ConsumerState<EnterCardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _cardPreviewController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _cardPreviewAnimation;

  bool _isFormValid = false;
  bool _showCardPreview = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _cardPreviewController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _cardPreviewAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardPreviewController, curve: Curves.elasticOut),
    );

    // Initialize card if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingCard != null) {
        ref.read(cardProvider.notifier).setCurrentCard(widget.existingCard);
      } else {
        // Initialize with empty card
        ref
            .read(cardProvider.notifier)
            .setCurrentCard(
              const CreditCard(
                cardHolderName: '',
                cardNumber: '',
                last4Digits: '',
                expiryMonth: 1,
                expiryYear: 2025,
                cvv: '',
                cardType: CardType.unknown,
              ),
            );
      }
    });

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardPreviewController.dispose();
    super.dispose();
  }

  void _toggleCardPreview() {
    setState(() {
      _showCardPreview = !_showCardPreview;
    });

    if (_showCardPreview) {
      _cardPreviewController.forward();
    } else {
      _cardPreviewController.reverse();
    }
  }

  void _onValidationChanged() {
    final cardState = ref.read(cardProvider);
    final isValid =
        cardState.validationErrors.isEmpty &&
        cardState.currentCard != null &&
        cardState.currentCard!.cardNumber.isNotEmpty &&
        cardState.currentCard!.cardHolderName.isNotEmpty &&
        cardState.currentCard!.cvv.isNotEmpty;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _startCardScanning() async {
    try {
      await ref.read(cardProvider.notifier).startCardScanning();

      final cardState = ref.read(cardProvider);
      if (cardState.scanResult != null && cardState.scanResult!.isValid) {
        _showScanSuccessDialog();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to scan card: $e');
    }
  }

  void _showScanSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Card Scanned Successfully!'),
            content: const Text(
              'Card details have been automatically filled. Please review and complete any missing information.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final cardState = ref.read(cardProvider);
    if (cardState.currentCard == null) return;

    // Navigate to confirm card screen
    context.push('/card/confirm', extra: cardState.currentCard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: Consumer(
        builder: (context, ref, child) {
          final cardState = ref.watch(cardProvider);

          // Update form validation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onValidationChanged();
          });

          return SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),

                // Content
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Section
                          _buildTitleSection(context),

                          const SizedBox(height: 24),

                          // Card Preview Toggle
                          if (cardState.currentCard != null &&
                              cardState.currentCard!.cardNumber.isNotEmpty)
                            _buildCardPreviewToggle(context),

                          // Card Preview
                          if (_showCardPreview)
                            AnimatedBuilder(
                              animation: _cardPreviewAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _cardPreviewAnimation.value,
                                  child: Opacity(
                                    opacity: _cardPreviewAnimation.value,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 24),
                                      child: CardPreviewWidget(
                                        card: cardState.currentCard!,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Scan Card Button
                          _buildScanCardButton(context, cardState),

                          const SizedBox(height: 24),

                          // Card Input Form
                          CardInputForm(
                            initialCard: cardState.currentCard,
                            onValidationChanged: _onValidationChanged,
                            enabled: !cardState.isLoading,
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Actions
                _buildBottomActions(context, cardState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceVariant,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            widget.existingCard != null ? 'Edit Card' : 'Add New Card',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your card information',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please enter your card details securely. All information is encrypted and stored safely.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCardPreviewToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.credit_card, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Card Preview',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: _showCardPreview,
            onChanged: (_) => _toggleCardPreview(),
            activeColor: const Color(0xFFFFC000),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCardButton(BuildContext context, CardState cardState) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: cardState.isScanning ? null : _startCardScanning,
        icon:
            cardState.isScanning
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
                : const Icon(Icons.camera_alt_outlined),
        label: Text(
          cardState.isScanning ? 'Scanning...' : 'Scan Card with Camera',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, CardState cardState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  (_isFormValid && !cardState.isLoading)
                      ? _handleContinue
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC000),
                foregroundColor: Colors.black,
                disabledBackgroundColor: theme.colorScheme.surfaceVariant,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  cardState.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      )
                      : const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: cardState.isLoading ? null : () => context.pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.outline,
                side: BorderSide(color: theme.colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
