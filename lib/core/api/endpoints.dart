class Endpoints {
  static const String baseUrl = 'https://flash-transfer.com';

  // Auth endpoints
  static const String register = '/api/user/register-email';
  static const String login = '/api/user/sign-in';
  static const String verifyEmail = '/api/user/verify-email';
  static const String resendVerification = '/api/user/resend-verification';
  static const String googleAuth = '/api/user/authenticate-google';
  static const String facebookAuth = '/api/user/authenticate-facebook';
  static const String appleAuth = '/api/user/authenticate-apple';
  static const String walletAuth = '/api/user/authenticate-wallet';

  // currency endpoints
  static const String exchangeRates = '$baseUrl/api/exchange/rates';
  static const String exchangeCalculate = '$baseUrl/api/exchange/calculate';
  static const String exchangePairs = '$baseUrl/api/exchange/pairs';
  static const String currencies = '$baseUrl/api/exchange/currencies';

  // External API
  static const String countries = 'https://restcountries.com/v3.1/all';
}
