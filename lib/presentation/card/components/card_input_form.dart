import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/credit_card_model.dart';
import '../../../providers/card_provider.dart';

class CardInputForm extends ConsumerStatefulWidget {
  final CreditCard? initialCard;
  final VoidCallback? onValidationChanged;
  final bool enabled;

  const CardInputForm({
    Key? key,
    this.initialCard,
    this.onValidationChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  ConsumerState<CardInputForm> createState() => _CardInputFormState();
}

class _CardInputFormState extends ConsumerState<CardInputForm>
    with TickerProviderStateMixin {
  late final TextEditingController _cardNumberController;
  late final TextEditingController _cardHolderController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvvController;

  late final FocusNode _cardNumberFocus;
  late final FocusNode _cardHolderFocus;
  late final FocusNode _expiryFocus;
  late final FocusNode _cvvFocus;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  bool _cvvVisible = false;

  @override
  void initState() {
    super.initState();
    
    _cardNumberController = TextEditingController();
    _cardHolderController = TextEditingController();
    _expiryController = TextEditingController();
    _cvvController = TextEditingController();

    _cardNumberFocus = FocusNode();
    _cardHolderFocus = FocusNode();
    _expiryFocus = FocusNode();
    _cvvFocus = FocusNode();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // Initialize with existing card data
    if (widget.initialCard != null) {
      _populateFromCard(widget.initialCard!);
    }

    // Add listeners for real-time validation
    _cardNumberController.addListener(_onCardNumberChanged);
    _cardHolderController.addListener(_onCardHolderChanged);
    _expiryController.addListener(_onExpiryChanged);
    _cvvController.addListener(_onCVVChanged);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    
    _cardNumberFocus.dispose();
    _cardHolderFocus.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    
    _shakeController.dispose();
    super.dispose();
  }

  void _populateFromCard(CreditCard card) {
    _cardNumberController.text = CardValidation.formatCardNumber(
      card.cardNumber, 
      card.cardType
    );
    _cardHolderController.text = card.cardHolderName;
    _expiryController.text = card.formattedExpiryDate;
    _cvvController.text = card.cvv;
  }

  void _onCardNumberChanged() {
    final value = _cardNumberController.text.replaceAll(' ', '');
    ref.read(cardProvider.notifier).updateCardField('cardNumber', value);
    
    // Auto-format card number
    final cardType = CardValidation.detectCardType(value);
    final formatted = CardValidation.formatCardNumber(value, cardType);
    
    if (formatted != _cardNumberController.text) {
      final selection = _cardNumberController.selection;
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: selection.baseOffset + (formatted.length - _cardNumberController.text.length),
        ),
      );
    }

    // Auto-focus next field when card number is complete
    if (value.length >= 16 && CardValidation.isValidCardNumber(value)) {
      _cardHolderFocus.requestFocus();
    }
  }

  void _onCardHolderChanged() {
    ref.read(cardProvider.notifier).updateCardField('cardHolderName', _cardHolderController.text);
  }

  void _onExpiryChanged() {
    final value = _expiryController.text;
    
    // Auto-format expiry date
    if (value.length == 2 && !value.contains('/')) {
      _expiryController.text = '$value/';
      _expiryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _expiryController.text.length),
      );
      return;
    }

    // Parse and validate expiry
    if (value.contains('/')) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final month = int.tryParse(parts[0]) ?? 0;
        final year = int.tryParse(parts[1]) ?? 0;
        
        if (month > 0) {
          ref.read(cardProvider.notifier).updateCardField('expiryMonth', month.toString());
        }
        
        if (year > 0) {
          // Handle 2-digit year conversion
          final fullYear = year < 100 ? (year < 50 ? 2000 + year : 1900 + year) : year;
          ref.read(cardProvider.notifier).updateCardField('expiryYear', fullYear.toString());
        }
      }
    }

    // Auto-focus CVV when expiry is complete
    if (value.length >= 5) {
      _cvvFocus.requestFocus();
    }
  }

  void _onCVVChanged() {
    ref.read(cardProvider.notifier).updateCardField('cvv', _cvvController.text);
  }

  void _shakeField() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardState = ref.watch(cardProvider);
    final theme = Theme.of(context);
    
    // Trigger shake animation on validation errors
    if (cardState.validationErrors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _shakeField();
      });
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            10 * _shakeAnimation.value * 
            (1 - 2 * (_shakeAnimation.value - 0.5).abs()),
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Number Field
              _buildAnimatedField(
                label: 'Card Number',
                controller: _cardNumberController,
                focusNode: _cardNumberFocus,
                hintText: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(19), // Max length with spaces
                ],
                prefixIcon: _buildCardTypeIcon(cardState.currentCard?.cardType),
                errorText: cardState.validationErrors['cardNumber'],
                enabled: widget.enabled,
              ),
              
              const SizedBox(height: 16),
              
              // Card Holder Name Field
              _buildAnimatedField(
                label: 'Cardholder Name',
                controller: _cardHolderController,
                focusNode: _cardHolderFocus,
                hintText: 'John Doe',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  LengthLimitingTextInputFormatter(30),
                ],
                errorText: cardState.validationErrors['cardHolderName'],
                enabled: widget.enabled,
              ),
              
              const SizedBox(height: 16),
              
              // Expiry Date and CVV Row
              Row(
                children: [
                  // Expiry Date Field
                  Expanded(
                    child: _buildAnimatedField(
                      label: 'Expiry Date',
                      controller: _expiryController,
                      focusNode: _expiryFocus,
                      hintText: 'MM/YY',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryDateFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      errorText: cardState.validationErrors['expiry'],
                      enabled: widget.enabled,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // CVV Field
                  Expanded(
                    child: _buildAnimatedField(
                      label: 'CVV',
                      controller: _cvvController,
                      focusNode: _cvvFocus,
                      hintText: cardState.currentCard?.cardType == CardType.americanExpress ? '1234' : '123',
                      keyboardType: TextInputType.number,
                      obscureText: !_cvvVisible,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          cardState.currentCard?.cardType == CardType.americanExpress ? 4 : 3
                        ),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _cvvVisible ? Icons.visibility_off : Icons.visibility,
                          color: theme.colorScheme.outline,
                        ),
                        onPressed: () {
                          setState(() {
                            _cvvVisible = !_cvvVisible;
                          });
                        },
                      ),
                      errorText: cardState.validationErrors['cvv'],
                      enabled: widget.enabled,
                    ),
                  ),
                ],
              ),
              
              // CVV Help Text
              if (cardState.currentCard?.cardType != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getCVVHelpText(cardState.currentCard!.cardType),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    bool obscureText = false,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError 
                    ? theme.colorScheme.error
                    : focusNode.hasFocus
                        ? const Color(0xFFFFC000)
                        : theme.colorScheme.outline.withOpacity(0.3),
                width: hasError || focusNode.hasFocus ? 2 : 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              obscureText: obscureText,
              enabled: enabled,
              textCapitalization: textCapitalization,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (hasError)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 4),
              child: Text(
                errorText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildCardTypeIcon(CardType? cardType) {
    if (cardType == null || cardType == CardType.unknown) {
      return null;
    }

    return Container(
      margin: const EdgeInsets.all(12),
      child: Image.asset(
        cardType.name,
        width: 32,
        height: 20,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.credit_card,
            color: Theme.of(context).colorScheme.outline,
          );
        },
      ),
    );
  }

  String _getCVVHelpText(CardType cardType) {
    switch (cardType) {
      case CardType.americanExpress:
        return 'The 4-digit code on the front of your American Express card';
      default:
        return 'The 3-digit code on the back of your card';
    }
  }
}

// Custom formatter for expiry date
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.length == 2 && oldValue.text.length == 1) {
      return TextEditingValue(
        text: '$text/',
        selection: TextSelection.collapsed(offset: 3),
      );
    }
    
    return newValue;
  }
}