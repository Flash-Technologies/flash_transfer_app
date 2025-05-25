import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart'
    hide CardScanResult, CardType;
import '../core/models/credit_card_model.dart';
import '../core/services/card_service.dart';

class CardState {
  final List<CreditCard> cards;
  final CreditCard? currentCard;
  final bool isLoading;
  final bool isScanning;
  final String? error;
  final Map<String, String> validationErrors;
  final CardScanResult? scanResult;

  const CardState({
    this.cards = const [],
    this.currentCard,
    this.isLoading = false,
    this.isScanning = false,
    this.error,
    this.validationErrors = const {},
    this.scanResult,
  });

  CardState copyWith({
    List<CreditCard>? cards,
    CreditCard? currentCard,
    bool? isLoading,
    bool? isScanning,
    String? error,
    Map<String, String>? validationErrors,
    CardScanResult? scanResult,
    bool clearError = false,
    bool clearCurrentCard = false,
    bool clearScanResult = false,
  }) {
    return CardState(
      cards: cards ?? this.cards,
      currentCard: clearCurrentCard ? null : (currentCard ?? this.currentCard),
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : (error ?? this.error),
      validationErrors: validationErrors ?? this.validationErrors,
      scanResult: clearScanResult ? null : (scanResult ?? this.scanResult),
    );
  }
}

// Card service provider
final cardServiceProvider = Provider<CardService>((ref) {
  return CardService();
});

// Card state notifier
class CardNotifier extends StateNotifier<CardState> {
  final CardService _cardService;

  CardNotifier(this._cardService) : super(const CardState());

  // Load all cards
  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final cards = await _cardService.getAllCards();
      state = state.copyWith(cards: cards, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load cards: ${e.toString()}',
      );
    }
  }

  // Add new card
  Future<bool> addCard(CreditCard card) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Validate card before sending to API
      final validationErrors = _validateCard(card);
      if (validationErrors.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          validationErrors: validationErrors,
        );
        return false;
      }

      final newCard = await _cardService.addCard(card.toCreateRequest());
      final updatedCards = [...state.cards, newCard];

      state = state.copyWith(
        cards: updatedCards,
        isLoading: false,
        validationErrors: {},
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add card: ${e.toString()}',
      );
      return false;
    }
  }

  // Update card
  Future<bool> updateCard(CreditCard card) async {
    if (card.id == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final validationErrors = _validateCard(card);
      if (validationErrors.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          validationErrors: validationErrors,
        );
        return false;
      }

      final updatedCard = await _cardService.updateCard(
        card.id!,
        card.toCreateRequest(),
      );
      final updatedCards =
          state.cards.map((c) => c.id == card.id ? updatedCard : c).toList();

      state = state.copyWith(
        cards: updatedCards,
        isLoading: false,
        validationErrors: {},
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update card: ${e.toString()}',
      );
      return false;
    }
  }

  // Delete card
  Future<bool> deleteCard(int cardId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _cardService.deleteCard(cardId);
      final updatedCards = state.cards.where((c) => c.id != cardId).toList();

      state = state.copyWith(cards: updatedCards, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete card: ${e.toString()}',
      );
      return false;
    }
  }

  // Set default card
  Future<bool> setDefaultCard(int cardId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedCard = await _cardService.setDefaultCard(cardId);
      final updatedCards =
          state.cards.map((c) {
            if (c.id == cardId) {
              return updatedCard;
            } else {
              return c.copyWith(isDefault: false);
            }
          }).toList();

      state = state.copyWith(cards: updatedCards, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set default card: ${e.toString()}',
      );
      return false;
    }
  }

  // Set current card for editing
  void setCurrentCard(CreditCard? card) {
    state = state.copyWith(
      currentCard: card,
      clearCurrentCard: card == null,
      validationErrors: {},
      clearError: true,
    );
  }

  // Start card scanning - Placeholder since flutter_credit_card doesn't support scanning
  Future<void> startCardScanning() async {
    state = state.copyWith(isScanning: true, clearError: true);

    try {
      // Since flutter_credit_card doesn't provide scanning functionality,
      // you would need to integrate a separate scanning package or camera plugin
      // For now, this is a placeholder that simulates scanning

      await Future.delayed(
        const Duration(seconds: 2),
      ); // Simulate scanning delay

      // For demo purposes, create a mock scan result
      // In production, you would integrate a real scanning solution
      final mockScanResult = CardScanResult(
        cardNumber: '', // Empty for now
        expiryDate: '',
        cardHolderName: '',
        detectedType: CardType.unknown,
        confidence: 0.0,
      );

      state = state.copyWith(
        isScanning: false,
        error:
            'Card scanning is not available. Please enter card details manually.',
        scanResult: mockScanResult,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Failed to scan card: ${e.toString()}',
      );
    }
  }

  // Update card field with real-time validation
  void updateCardField(String field, String value) {
    if (state.currentCard == null) return;

    CreditCard updatedCard;
    Map<String, String> errors = Map.from(state.validationErrors);

    switch (field) {
      case 'cardNumber':
        final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
        final cardType = CardValidation.detectCardType(cleanNumber);
        updatedCard = state.currentCard!.copyWith(
          cardNumber: cleanNumber,
          cardType: cardType,
          last4Digits:
              cleanNumber.length >= 4
                  ? cleanNumber.substring(cleanNumber.length - 4)
                  : cleanNumber,
        );

        // Validate card number
        if (cleanNumber.isEmpty) {
          errors['cardNumber'] = 'Card number is required';
        } else if (!CardValidation.isValidCardNumber(cleanNumber)) {
          errors['cardNumber'] = 'Invalid card number';
        } else {
          errors.remove('cardNumber');
        }
        break;

      case 'cardHolderName':
        updatedCard = state.currentCard!.copyWith(cardHolderName: value);

        if (value.trim().isEmpty) {
          errors['cardHolderName'] = 'Cardholder name is required';
        } else if (value.trim().length < 2) {
          errors['cardHolderName'] = 'Name must be at least 2 characters';
        } else {
          errors.remove('cardHolderName');
        }
        break;

      case 'expiryMonth':
        final month = int.tryParse(value) ?? 0;
        updatedCard = state.currentCard!.copyWith(expiryMonth: month);

        if (month < 1 || month > 12) {
          errors['expiry'] = 'Invalid expiry date';
        } else if (!CardValidation.isValidExpiryDate(
          month,
          state.currentCard!.expiryYear,
        )) {
          errors['expiry'] = 'Card has expired';
        } else {
          errors.remove('expiry');
        }
        break;

      case 'expiryYear':
        final year = int.tryParse(value) ?? 0;
        updatedCard = state.currentCard!.copyWith(expiryYear: year);

        if (!CardValidation.isValidExpiryDate(
          state.currentCard!.expiryMonth,
          year,
        )) {
          errors['expiry'] = 'Card has expired';
        } else {
          errors.remove('expiry');
        }
        break;

      case 'cvv':
        updatedCard = state.currentCard!.copyWith(cvv: value);

        if (value.isEmpty) {
          errors['cvv'] = 'CVV is required';
        } else if (!CardValidation.isValidCVV(
          value,
          state.currentCard!.cardType,
        )) {
          final expectedLength =
              state.currentCard!.cardType == CardType.americanExpress ? 4 : 3;
          errors['cvv'] = 'CVV must be $expectedLength digits';
        } else {
          errors.remove('cvv');
        }
        break;

      default:
        return;
    }

    state = state.copyWith(currentCard: updatedCard, validationErrors: errors);
  }

  // Clear validation errors
  void clearValidationErrors() {
    state = state.copyWith(validationErrors: {});
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Clear scan result
  void clearScanResult() {
    state = state.copyWith(clearScanResult: true);
  }

  // Private methods
  Map<String, String> _validateCard(CreditCard card) {
    final Map<String, String> errors = {};

    // Validate card number
    if (card.cardNumber.isEmpty) {
      errors['cardNumber'] = 'Card number is required';
    } else if (!CardValidation.isValidCardNumber(card.cardNumber)) {
      errors['cardNumber'] = 'Invalid card number';
    }

    // Validate cardholder name
    if (card.cardHolderName.trim().isEmpty) {
      errors['cardHolderName'] = 'Cardholder name is required';
    } else if (card.cardHolderName.trim().length < 2) {
      errors['cardHolderName'] = 'Name must be at least 2 characters';
    }

    // Validate expiry date
    if (!CardValidation.isValidExpiryDate(card.expiryMonth, card.expiryYear)) {
      errors['expiry'] = 'Invalid or expired date';
    }

    // Validate CVV
    if (card.cvv.isEmpty) {
      errors['cvv'] = 'CVV is required';
    } else if (!CardValidation.isValidCVV(card.cvv, card.cardType)) {
      final expectedLength = card.cardType == CardType.americanExpress ? 4 : 3;
      errors['cvv'] = 'CVV must be $expectedLength digits';
    }

    return errors;
  }

  CreditCard _createCardFromScanResult(CardScanResult scanResult) {
    // Parse expiry date from scan result
    int expiryMonth = 1;
    int expiryYear = DateTime.now().year + 1;

    if (scanResult.expiryDate != null) {
      final parts = scanResult.expiryDate!.split('/');
      if (parts.length == 2) {
        expiryMonth = int.tryParse(parts[0]) ?? 1;
        var year = int.tryParse(parts[1]) ?? 0;
        // Handle 2-digit year
        if (year < 100) {
          year += (year < 50) ? 2000 : 1900;
        }
        expiryYear = year;
      }
    }

    final cardNumber = scanResult.cardNumber ?? '';
    return CreditCard(
      cardHolderName: scanResult.cardHolderName ?? '',
      cardNumber: cardNumber,
      last4Digits:
          cardNumber.length >= 4
              ? cardNumber.substring(cardNumber.length - 4)
              : cardNumber,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvv: '',
      cardType: scanResult.detectedType,
    );
  }
}

// Provider instance
final cardProvider = StateNotifierProvider<CardNotifier, CardState>((ref) {
  final cardService = ref.watch(cardServiceProvider);
  return CardNotifier(cardService);
});
