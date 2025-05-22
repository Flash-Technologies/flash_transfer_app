import 'dart:convert';
import 'package:flash_transfer_app/core/api/endpoints.dart';
import '../models/credit_card_model.dart';
import '../api/api_client.dart';
import '../utils/exceptions.dart';

class CardService {
  final ApiClient _apiClient;
  static const String _baseEndpoint = '/api/credit-cards';

  CardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(baseUrl: Endpoints.baseUrl);

  /// Get all cards for the current user
  Future<List<CreditCard>> getAllCards() async {
    try {
      final response = await _apiClient.get(_baseEndpoint);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> cardsJson = data['data'];
          return cardsJson.map((json) => CreditCard.fromJson(json)).toList();
        } else {
          throw ApiException(
            message: data['message'] ?? 'Failed to fetch cards',
            statusCode: response.statusCode ?? 0,
          );
        }
      } else {
        throw ApiException(
          message: 'Failed to fetch cards',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Add a new credit card
  Future<CreditCard> addCard(Map<String, dynamic> cardData) async {
    try {
      // Validate required fields
      _validateCardData(cardData);

      final response = await _apiClient.post(_baseEndpoint, data: cardData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return CreditCard.fromJson(data['data']);
        } else {
          throw ApiException(
            message: data['message'] ?? 'Failed to add card',
            statusCode: response.statusCode ?? 0,
          );
        }
      } else if (response.statusCode == 400) {
        final data = response.data;
        throw ValidationException(
          message: data['message'] ?? 'Invalid card data',
          validationErrors: _parseValidationErrors(data),
        );
      } else {
        throw ApiException(
          message: 'Failed to add card',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on ApiException {
      rethrow;
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Get a specific card by ID
  Future<CreditCard> getCard(int cardId) async {
    try {
      final response = await _apiClient.get('$_baseEndpoint/$cardId');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return CreditCard.fromJson(data['data']);
        } else {
          throw ApiException(
            message: data['message'] ?? 'Card not found',
            statusCode: response.statusCode ?? 0,
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Card not found');
      } else {
        throw ApiException(
          message: 'Failed to fetch card',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on ApiException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Update an existing card
  Future<CreditCard> updateCard(
    int cardId,
    Map<String, dynamic> cardData,
  ) async {
    try {
      _validateCardData(cardData);

      final response = await _apiClient.put(
        '$_baseEndpoint/$cardId',
        data: cardData,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return CreditCard.fromJson(data['data']);
        } else {
          throw ApiException(
            message: data['message'] ?? 'Failed to update card',
            statusCode: response.statusCode ?? 0,
          );
        }
      } else if (response.statusCode == 400) {
        final data = response.data;
        throw ValidationException(
          message: data['message'] ?? 'Invalid card data',
          validationErrors: _parseValidationErrors(data),
        );
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Card not found');
      } else {
        throw ApiException(
          message: 'Failed to update card',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on ApiException {
      rethrow;
    } on ValidationException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Delete a card
  Future<void> deleteCard(int cardId) async {
    try {
      final response = await _apiClient.delete('$_baseEndpoint/$cardId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        final data = response.data;

        if (data['success'] != true) {
          throw ApiException(
            message: data['message'] ?? 'Failed to delete card',
            statusCode: response.statusCode ?? 0,
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Card not found');
      } else {
        throw ApiException(
          message: 'Failed to delete card',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on ApiException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Set a card as default
  Future<CreditCard> setDefaultCard(int cardId) async {
    try {
      final response = await _apiClient.post(
        '$_baseEndpoint/$cardId/set-default',
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return CreditCard.fromJson(data['data']);
        } else {
          throw ApiException(
            message: data['message'] ?? 'Failed to set default card',
            statusCode: response.statusCode ?? 0,
          );
        }
      } else if (response.statusCode == 404) {
        throw NotFoundException(message: 'Card not found');
      } else {
        throw ApiException(
          message: 'Failed to set default card',
          statusCode: response.statusCode ?? 0,
        );
      }
    } on ApiException {
      rethrow;
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  /// Validate card with external service (optional)
  Future<CardValidationResult> validateCardWithProvider(
    String cardNumber,
    int expiryMonth,
    int expiryYear,
    String cvv,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_baseEndpoint/validate',
        data: {
          'cardNumber': cardNumber,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'cvv': cvv,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        return CardValidationResult(
          isValid: data['isValid'] ?? false,
          cardType: data['cardType'] ?? 'unknown',
          issuer: data['issuer'],
          country: data['country'],
          message: data['message'],
        );
      } else {
        throw ApiException(
          message: 'Failed to validate card',
          statusCode: response.statusCode ?? 0,
        );
      }
    } catch (e) {
      // If validation service fails, fall back to local validation
      return CardValidationResult(
        isValid:
            CardValidation.isValidCardNumber(cardNumber) &&
            CardValidation.isValidExpiryDate(expiryMonth, expiryYear) &&
            CardValidation.isValidCVV(
              cvv,
              CardValidation.detectCardType(cardNumber),
            ),
        cardType: CardValidation.detectCardType(cardNumber).name,
        message: 'Local validation only',
      );
    }
  }

  // Private helper methods
  void _validateCardData(Map<String, dynamic> cardData) {
    final requiredFields = [
      'cardNumber',
      'cardHolderName',
      'expiryMonth',
      'expiryYear',
      'cvv',
    ];

    for (final field in requiredFields) {
      if (!cardData.containsKey(field) || cardData[field] == null) {
        throw ValidationException(
          message: 'Missing required field: $field',
          validationErrors: {field: 'This field is required'},
        );
      }
    }

    // Additional validation
    final cardNumber = cardData['cardNumber'].toString();
    final cardHolderName = cardData['cardHolderName'].toString();
    final expiryMonth = cardData['expiryMonth'] as int;
    final expiryYear = cardData['expiryYear'] as int;
    final cvv = cardData['cvv'].toString();

    final errors = <String, String>{};

    if (!CardValidation.isValidCardNumber(cardNumber)) {
      errors['cardNumber'] = 'Invalid card number';
    }

    if (cardHolderName.trim().length < 2) {
      errors['cardHolderName'] =
          'Cardholder name must be at least 2 characters';
    }

    if (!CardValidation.isValidExpiryDate(expiryMonth, expiryYear)) {
      errors['expiry'] = 'Invalid or expired date';
    }

    final cardType = CardValidation.detectCardType(cardNumber);
    if (!CardValidation.isValidCVV(cvv, cardType)) {
      errors['cvv'] = 'Invalid CVV';
    }

    if (errors.isNotEmpty) {
      throw ValidationException(
        message: 'Card validation failed',
        validationErrors: errors,
      );
    }
  }

  Map<String, String> _parseValidationErrors(Map<String, dynamic> data) {
    final errors = <String, String>{};

    if (data['errors'] != null && data['errors'] is Map) {
      final errorMap = data['errors'] as Map<String, dynamic>;
      errorMap.forEach((key, value) {
        if (value is List) {
          errors[key] = value.first.toString();
        } else {
          errors[key] = value.toString();
        }
      });
    }

    return errors;
  }
}

// Card validation result model
class CardValidationResult {
  final bool isValid;
  final String cardType;
  final String? issuer;
  final String? country;
  final String? message;

  const CardValidationResult({
    required this.isValid,
    required this.cardType,
    this.issuer,
    this.country,
    this.message,
  });
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String> validationErrors;

  const ValidationException({
    required this.message,
    this.validationErrors = const {},
  });

  @override
  String toString() => 'ValidationException: $message';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException({required this.message});

  @override
  String toString() => 'NotFoundException: $message';
}
