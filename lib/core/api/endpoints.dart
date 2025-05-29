class Endpoints {
  static const String baseUrl = 'https://flash-transfer.com';

  // Auth endpoints
  static const String register = '/api/user/register-email';
  static const String login = '/api/user/sign-in';
  static const String getUserProfile = '/api/user/profile';
  static const String updateUserProfile = '/api/user/profile';
  static const String verifyEmail = '/api/user/verify-email';
  static const String resendVerification = '/api/user/resend-verification';
  static const String googleAuth = '/api/user/login-google';
  static const String facebookAuth = '/api/user/authenticate-facebook';
  static const String appleAuth = '/api/user/authenticate-apple';
  static const String walletAuth = '/api/user/authenticate-wallet';

  // Alternative endpoints to test if above doesn't work
  // static const String googleAuth = '/api/user/authenticate-google';
  // static const String googleAuth = '/api/auth/google';
  // static const String googleAuth = '/api/user/google-auth';
  // static const String googleAuth = '/api/v1/auth/google';
  // static const String googleAuth = '/auth/google';

  // currency endpoints
  static const String exchangeRates = '$baseUrl/api/exchange/rates';
  static const String exchangeCalculate = '$baseUrl/api/exchange/calculate';
  static const String exchangePairs = '$baseUrl/api/exchange/pairs';
  static const String currencies = '$baseUrl/api/exchange/currencies';

  // beneficiary endpoints
  static const String beneficiaries = '$baseUrl/api/beneficiary';

  // transaction endpoints
  static const String transactionEstimate =
      '$baseUrl/api/transaction/estimate-mobile-money-to-crypto';
  static const String createCashToCryptoTransaction =
      '$baseUrl/api/transaction/cash-to-crypto-mobile-money';

  // External API
  static const String countries = 'https://restcountries.com/v3.1/all';
}
