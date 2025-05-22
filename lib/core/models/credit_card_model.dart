import 'package:equatable/equatable.dart';

enum CardType {
  visa,
  mastercard,
  americanExpress,
  discover,
  dinersClub,
  jcb,
  unionPay,
  unknown
}

class CreditCard extends Equatable {
  final int? id;
  final String cardHolderName;
  final String cardNumber;
  final String last4Digits;
  final int expiryMonth;
  final int expiryYear;
  final String cvv;
  final bool isDefault;
  final CardType cardType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CreditCard({
    this.id,
    required this.cardHolderName,
    required this.cardNumber,
    required this.last4Digits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.isDefault = false,
    required this.cardType,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for API response
  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      cardHolderName: json['cardHolderName'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
      last4Digits: json['last4Digits'] ?? '',
      expiryMonth: json['expiryMonth'] ?? 1,
      expiryYear: json['expiryYear'] ?? DateTime.now().year,
      cvv: json['cvv'] ?? '',
      isDefault: json['isDefault'] ?? false,
      cardType: _parseCardType(json['cardType']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
    );
  }

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'isDefault': isDefault,
      'cardType': cardType.name,
    };
  }

  // Create request object for API (without sensitive data for storage)
  Map<String, dynamic> toCreateRequest() {
    return {
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
    };
  }

  static CardType _parseCardType(String? type) {
    if (type == null) return CardType.unknown;
    
    switch (type.toLowerCase()) {
      case 'visa':
        return CardType.visa;
      case 'mastercard':
        return CardType.mastercard;
      case 'americanexpress':
      case 'amex':
        return CardType.americanExpress;
      case 'discover':
        return CardType.discover;
      case 'dinersclub':
        return CardType.dinersClub;
      case 'jcb':
        return CardType.jcb;
      case 'unionpay':
        return CardType.unionPay;
      default:
        return CardType.unknown;
    }
  }

  // Get masked card number for display
  String get maskedCardNumber {
    if (cardNumber.length < 4) return cardNumber;
    final visibleDigits = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $visibleDigits';
  }

  // Get formatted expiry date
  String get formattedExpiryDate {
    final month = expiryMonth.toString().padLeft(2, '0');
    final year = expiryYear.toString().substring(2);
    return '$month/$year';
  }

  // Check if card is expired
  bool get isExpired {
    final now = DateTime.now();
    final expiryDate = DateTime(expiryYear, expiryMonth + 1, 0);
    return now.isAfter(expiryDate);
  }

  // Get card brand image path
  String get brandImagePath {
    switch (cardType) {
      case CardType.visa:
        return 'assets/images/visa.png';
      case CardType.mastercard:
        return 'assets/images/mastercard.png';
      case CardType.americanExpress:
        return 'assets/images/amex.png';
      case CardType.discover:
        return 'assets/images/discover.png';
      default:
        return 'assets/images/card_default.png';
    }
  }

  // Get card brand color
  int get brandColor {
    switch (cardType) {
      case CardType.visa:
        return 0xFF1A1F71;
      case CardType.mastercard:
        return 0xFFEB001B;
      case CardType.americanExpress:
        return 0xFF006FCF;
      case CardType.discover:
        return 0xFFFF6000;
      default:
        return 0xFF666666;
    }
  }

  CreditCard copyWith({
    int? id,
    String? cardHolderName,
    String? cardNumber,
    String? last4Digits,
    int? expiryMonth,
    int? expiryYear,
    String? cvv,
    bool? isDefault,
    CardType? cardType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumber: cardNumber ?? this.cardNumber,
      last4Digits: last4Digits ?? this.last4Digits,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      cvv: cvv ?? this.cvv,
      isDefault: isDefault ?? this.isDefault,
      cardType: cardType ?? this.cardType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cardHolderName,
        cardNumber,
        last4Digits,
        expiryMonth,
        expiryYear,
        cvv,
        isDefault,
        cardType,
        createdAt,
        updatedAt,
      ];
}

// Card validation utilities
class CardValidation {
  // Validate card number using Luhn algorithm
  static bool isValidCardNumber(String cardNumber) {
    if (cardNumber.isEmpty) return false;
    
    // Remove spaces and non-numeric characters
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }

    int sum = 0;
    bool alternate = false;
    
    // Process digits from right to left
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  // Detect card type from number
  static CardType detectCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.isEmpty) return CardType.unknown;
    
    // Visa: starts with 4
    if (cleanNumber.startsWith('4')) {
      return CardType.visa;
    }
    
    // Mastercard: starts with 5 or 2221-2720
    if (cleanNumber.startsWith('5') || 
        (cleanNumber.length >= 4 && 
         int.parse(cleanNumber.substring(0, 4)) >= 2221 && 
         int.parse(cleanNumber.substring(0, 4)) <= 2720)) {
      return CardType.mastercard;
    }
    
    // American Express: starts with 34 or 37
    if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) {
      return CardType.americanExpress;
    }
    
    // Discover: starts with 6
    if (cleanNumber.startsWith('6')) {
      return CardType.discover;
    }
    
    // Diners Club: starts with 30, 36, 38
    if (cleanNumber.startsWith('30') || 
        cleanNumber.startsWith('36') || 
        cleanNumber.startsWith('38')) {
      return CardType.dinersClub;
    }
    
    // JCB: starts with 35
    if (cleanNumber.startsWith('35')) {
      return CardType.jcb;
    }
    
    return CardType.unknown;
  }

  // Validate expiry date
  static bool isValidExpiryDate(int month, int year) {
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0);
    
    return expiryDate.isAfter(now);
  }

  // Validate CVV based on card type
  static bool isValidCVV(String cvv, CardType cardType) {
    if (cvv.isEmpty) return false;
    
    final cleanCvv = cvv.replaceAll(RegExp(r'\D'), '');
    
    switch (cardType) {
      case CardType.americanExpress:
        return cleanCvv.length == 4;
      default:
        return cleanCvv.length == 3;
    }
  }

  // Format card number with spaces
  static String formatCardNumber(String cardNumber, CardType cardType) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.isEmpty) return '';
    
    switch (cardType) {
      case CardType.americanExpress:
        // American Express: 4-6-5 format
        if (cleanNumber.length <= 4) return cleanNumber;
        if (cleanNumber.length <= 10) {
          return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4)}';
        }
        return '${cleanNumber.substring(0, 4)} ${cleanNumber.substring(4, 10)} ${cleanNumber.substring(10)}';
      
      default:
        // Standard: 4-4-4-4 format
        final buffer = StringBuffer();
        for (int i = 0; i < cleanNumber.length; i++) {
          if (i > 0 && i % 4 == 0) buffer.write(' ');
          buffer.write(cleanNumber[i]);
        }
        return buffer.toString();
    }
  }
}

// Card scan result model
class CardScanResult extends Equatable {
  final String? cardNumber;
  final String? expiryDate;
  final String? cardHolderName;
  final CardType detectedType;
  final double confidence;

  const CardScanResult({
    this.cardNumber,
    this.expiryDate,
    this.cardHolderName,
    this.detectedType = CardType.unknown,
    this.confidence = 0.0,
  });

  bool get isValid => confidence > 0.7 && cardNumber != null;

  @override
  List<Object?> get props => [
        cardNumber,
        expiryDate,
        cardHolderName,
        detectedType,
        confidence,
      ];
}