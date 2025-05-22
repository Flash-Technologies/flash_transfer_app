library exceptions;

/// Base exception class for all app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const AppException({required this.message, this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

/// API-related exceptions
class ApiException extends AppException {
  final int statusCode;
  final String? endpoint;

  const ApiException({
    required String message,
    required this.statusCode,
    this.endpoint,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  /// Check if the error is a network connectivity issue
  bool get isNetworkError => statusCode == 0 || statusCode >= 500;

  /// Check if the error is a client-side issue
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Check if the error is server-side issue
  bool get isServerError => statusCode >= 500;

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (statusCode) {
      case 0:
        return 'No internet connection. Please check your network and try again.';
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication failed. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This action conflicts with existing data.';
      case 422:
        return 'The provided data is invalid. Please check and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return message.isNotEmpty ? message : 'An unexpected error occurred.';
    }
  }
}

/// Validation-specific exceptions
class ValidationException extends AppException {
  final Map<String, String> validationErrors;

  const ValidationException({
    required String message,
    this.validationErrors = const {},
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'ValidationException: $message';

  /// Check if has validation errors for a specific field
  bool hasErrorForField(String field) => validationErrors.containsKey(field);

  /// Get error message for a specific field
  String? getErrorForField(String field) => validationErrors[field];

  /// Get all error messages as a list
  List<String> get allErrorMessages => validationErrors.values.toList();
}

/// Resource not found exceptions
class NotFoundException extends AppException {
  final String resourceType;
  final String? resourceId;

  const NotFoundException({
    required String message,
    this.resourceType = 'Resource',
    this.resourceId,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Authentication and authorization exceptions
class AuthException extends AppException {
  final AuthErrorType type;

  const AuthException({
    required String message,
    required this.type,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'AuthException: $message (Type: $type)';
}

enum AuthErrorType {
  invalidCredentials,
  tokenExpired,
  refreshTokenExpired,
  unauthorized,
  forbidden,
  accountLocked,
  accountDisabled,
}

/// Payment-related exceptions
class PaymentException extends AppException {
  final PaymentErrorType type;
  final String? transactionId;

  const PaymentException({
    required String message,
    required this.type,
    this.transactionId,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'PaymentException: $message (Type: $type)';

  String get userFriendlyMessage {
    switch (type) {
      case PaymentErrorType.cardDeclined:
        return 'Your card was declined. Please try a different payment method.';
      case PaymentErrorType.insufficientFunds:
        return 'Insufficient funds. Please check your account balance.';
      case PaymentErrorType.cardExpired:
        return 'Your card has expired. Please use a different card.';
      case PaymentErrorType.invalidCard:
        return 'Invalid card details. Please check and try again.';
      case PaymentErrorType.processingFailed:
        return 'Payment processing failed. Please try again.';
      case PaymentErrorType.networkTimeout:
        return 'Payment timeout. Please check your connection and try again.';
      case PaymentErrorType.duplicateTransaction:
        return 'This transaction has already been processed.';
      case PaymentErrorType.fraudDetected:
        return 'Transaction blocked for security reasons. Please contact support.';
      default:
        return message;
    }
  }
}

enum PaymentErrorType {
  cardDeclined,
  insufficientFunds,
  cardExpired,
  invalidCard,
  processingFailed,
  networkTimeout,
  duplicateTransaction,
  fraudDetected,
  providerError,
}

/// Card scanning exceptions
class CardScanException extends AppException {
  final CardScanErrorType type;

  const CardScanException({
    required String message,
    required this.type,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'CardScanException: $message (Type: $type)';

  String get userFriendlyMessage {
    switch (type) {
      case CardScanErrorType.cameraPermissionDenied:
        return 'Camera permission is required to scan cards. Please enable it in settings.';
      case CardScanErrorType.cameraNotAvailable:
        return 'Camera is not available on this device.';
      case CardScanErrorType.scanCancelled:
        return 'Card scanning was cancelled.';
      case CardScanErrorType.poorQuality:
        return 'Card image quality is too low. Please try again with better lighting.';
      case CardScanErrorType.noCardDetected:
        return 'No card detected. Please ensure the card is clearly visible.';
      case CardScanErrorType.ocrFailed:
        return 'Failed to read card details. Please enter manually.';
      case CardScanErrorType.unsupportedCardType:
        return 'This card type is not supported for scanning.';
      default:
        return message;
    }
  }
}

enum CardScanErrorType {
  cameraPermissionDenied,
  cameraNotAvailable,
  scanCancelled,
  poorQuality,
  noCardDetected,
  ocrFailed,
  unsupportedCardType,
  processingError,
}

/// Storage and cache exceptions
class StorageException extends AppException {
  final StorageErrorType type;

  const StorageException({
    required String message,
    required this.type,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'StorageException: $message (Type: $type)';
}

enum StorageErrorType {
  readFailed,
  writeFailed,
  deleteFailed,
  encryptionFailed,
  decryptionFailed,
  storageUnavailable,
  quotaExceeded,
}

/// Configuration and initialization exceptions
class ConfigException extends AppException {
  const ConfigException({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'ConfigException: $message';
}

/// Business logic exceptions
class BusinessLogicException extends AppException {
  final BusinessErrorType type;

  const BusinessLogicException({
    required String message,
    required this.type,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() => 'BusinessLogicException: $message (Type: $type)';
}

enum BusinessErrorType {
  invalidOperation,
  preconditionFailed,
  businessRuleViolation,
  dataInconsistent,
  operationNotAllowed,
  quotaExceeded,
  featureNotAvailable,
}

/// Utility class for exception handling
class ExceptionHandler {
  /// Convert generic exceptions to app-specific exceptions
  static AppException handleException(dynamic exception) {
    if (exception is AppException) {
      return exception;
    }

    if (exception is FormatException) {
      return ValidationException(
        message: 'Invalid data format: ${exception.message}',
        code: 'FORMAT_ERROR',
      );
    }

    if (exception is TimeoutException) {
      return ApiException(
        message: 'Request timeout. Please try again.',
        statusCode: 408,
        code: 'TIMEOUT',
      );
    }

    // Handle other common exceptions
    return ApiException(
      message: exception.toString(),
      statusCode: 0,
      code: 'UNKNOWN_ERROR',
    );
  }

  /// Get user-friendly error message from any exception
  static String getUserFriendlyMessage(dynamic exception) {
    if (exception is PaymentException) {
      return exception.userFriendlyMessage;
    }

    if (exception is CardScanException) {
      return exception.userFriendlyMessage;
    }

    if (exception is ApiException) {
      return exception.userFriendlyMessage;
    }

    if (exception is ValidationException) {
      return exception.allErrorMessages.isNotEmpty
          ? exception.allErrorMessages.first
          : exception.message;
    }

    if (exception is AppException) {
      return exception.message;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if exception requires user authentication
  static bool requiresAuthentication(dynamic exception) {
    if (exception is ApiException) {
      return exception.statusCode == 401;
    }

    if (exception is AuthException) {
      return exception.type == AuthErrorType.tokenExpired ||
          exception.type == AuthErrorType.unauthorized;
    }

    return false;
  }

  /// Check if exception is retryable
  static bool isRetryable(dynamic exception) {
    if (exception is ApiException) {
      return exception.statusCode >= 500 ||
          exception.statusCode == 0 ||
          exception.statusCode == 408 ||
          exception.statusCode == 429;
    }

    if (exception is PaymentException) {
      return exception.type == PaymentErrorType.networkTimeout ||
          exception.type == PaymentErrorType.processingFailed;
    }

    return false;
  }

  /// Get retry delay for retryable exceptions
  static Duration getRetryDelay(dynamic exception, int retryCount) {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 2 * (1 << retryCount));
    final jitter = Duration(
      milliseconds:
          (baseDelay.inMilliseconds *
                  0.1 *
                  (DateTime.now().millisecond % 100) /
                  100)
              .round(),
    );

    return baseDelay + jitter;
  }
}

/// Exception logging utility
class ExceptionLogger {
  static void logException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    // In a real app, this would log to a service like Firebase Crashlytics
    print('Exception logged: $exception');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    if (context != null) {
      print('Context: $context');
    }

    // TODO: Implement proper logging service integration
    // FirebaseCrashlytics.instance.recordError(exception, stackTrace, context: context);
  }
}

/// Timeout exception for network operations
class TimeoutException extends AppException {
  final Duration timeout;

  const TimeoutException({
    required String message,
    required this.timeout,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  @override
  String toString() =>
      'TimeoutException: $message (Timeout: ${timeout.inSeconds}s)';
}
