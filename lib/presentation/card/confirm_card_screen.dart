import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/credit_card_model.dart';
import '../../providers/card_provider.dart';
import '../../providers/language_provider.dart';
import 'components/card_preview_widget.dart';

class ConfirmCardScreen extends ConsumerStatefulWidget {
  final CreditCard card;

  const ConfirmCardScreen({Key? key, required this.card}) : super(key: key);

  @override
  ConsumerState<ConfirmCardScreen> createState() => _ConfirmCardScreenState();
}

class _ConfirmCardScreenState extends ConsumerState<ConfirmCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _cardController;
  late AnimationController _detailsController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _detailsAnimation;

  bool _setAsDefault = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _detailsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _detailsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _detailsController, curve: Curves.easeOutBack),
    );

    // Start animations
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _detailsController.forward();
    });

    // Set card in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardProvider.notifier).setCurrentCard(widget.card);
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _confirmCard() async {
    if (!_agreedToTerms) {
      _showTermsDialog();
      return;
    }

    final cardToSave = widget.card.copyWith(isDefault: _setAsDefault);

    try {
      final success = await ref.read(cardProvider.notifier).addCard(cardToSave);

      if (success) {
        context.pushReplacement('/card/success');
      } else {
        _showErrorDialog('Failed to save card. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred while saving your card.');
    }
  }

  void _showTermsDialog() {
    final tr = ref.read(translationHelperProvider);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(tr('card.confirm.termsDialog.title')),
            content: Text(
              tr('card.confirm.termsDialog.message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('card.confirm.termsDialog.ok')),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    final tr = ref.read(translationHelperProvider);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(tr('card.confirm.errorDialog.title')),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('card.confirm.errorDialog.ok')),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardState = ref.watch(cardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF0F1),
      body: SafeArea(
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

                      const SizedBox(height: 32),

                      // Card Preview
                      AnimatedBuilder(
                        animation: _cardAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _cardAnimation.value,
                            child: Opacity(
                              opacity: _cardAnimation.value,
                              child: CardPreviewWidget(
                                card: widget.card,
                                animated: true,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Card Details
                      AnimatedBuilder(
                        animation: _detailsAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              50 * (1 - _detailsAnimation.value),
                            ),
                            child: Opacity(
                              opacity: _detailsAnimation.value,
                              child: _buildCardDetails(context),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Options
                      _buildOptions(context),

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
          Consumer(
            builder: (context, ref, child) {
              final tr = ref.watch(translationHelperProvider);
              return Text(
                tr('card.confirm.title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              );
            },
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
        Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationHelperProvider);
            return Text(
              tr('card.confirm.headerTitle'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final tr = ref.watch(translationHelperProvider);
            return Text(
              tr('card.confirm.subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCardDetails(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Consumer(
                  builder: (context, ref, child) {
                    final tr = ref.watch(translationHelperProvider);
                    return Text(
                      tr('card.confirm.cardDetails'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final tr = ref.watch(translationHelperProvider);
                    return _buildDetailRow(
                      tr('card.confirm.cardNumber'),
                      widget.card.maskedCardNumber,
                      Icons.credit_card,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final tr = ref.watch(translationHelperProvider);
                    return _buildDetailRow(
                      tr('card.confirm.cardholderName'),
                      widget.card.cardHolderName.toUpperCase(),
                      Icons.person,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final tr = ref.watch(translationHelperProvider);
                    return _buildDetailRow(
                      tr('card.confirm.expiryDate'),
                      widget.card.formattedExpiryDate,
                      Icons.calendar_today,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final tr = ref.watch(translationHelperProvider);
                    return _buildDetailRow(
                      tr('card.confirm.cardType'),
                      _getCardTypeName(widget.card.cardType),
                      Icons.account_balance_wallet,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Set as default option
          CheckboxListTile(
            value: _setAsDefault,
            onChanged: (value) {
              setState(() {
                _setAsDefault = value ?? false;
              });
            },
            title: Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('card.confirm.setAsDefault'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            subtitle: Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('card.confirm.setAsDefaultDescription'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            activeColor: const Color(0xFFFFC000),
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
          ),

          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)),

          // Terms and conditions
          CheckboxListTile(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
            title: Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('card.confirm.agreeToTerms'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                );
              },
            ),
            subtitle: Consumer(
              builder: (context, ref, child) {
                final tr = ref.watch(translationHelperProvider);
                return Text(
                  tr('card.confirm.agreeToTermsDescription'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
            activeColor: const Color(0xFFFFC000),
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
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
          // Save Card Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: cardState.isLoading ? null : _confirmCard,
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
                      : Consumer(
                        builder: (context, ref, child) {
                          final tr = ref.watch(translationHelperProvider);
                          return Text(
                            tr('card.confirm.saveCard'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
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
              child: Consumer(
                builder: (context, ref, child) {
                  final tr = ref.watch(translationHelperProvider);
                  return Text(
                    tr('card.confirm.cancel'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCardTypeName(CardType cardType) {
    final tr = ref.read(translationHelperProvider);
    switch (cardType) {
      case CardType.visa:
        return tr('card.cardTypes.visa');
      case CardType.mastercard:
        return tr('card.cardTypes.mastercard');
      case CardType.americanExpress:
        return tr('card.cardTypes.americanExpress');
      case CardType.discover:
        return tr('card.cardTypes.discover');
      case CardType.dinersClub:
        return tr('card.cardTypes.dinersClub');
      case CardType.jcb:
        return tr('card.cardTypes.jcb');
      case CardType.unionPay:
        return tr('card.cardTypes.unionPay');
      default:
        return tr('card.cardTypes.creditCard');
    }
  }
}
