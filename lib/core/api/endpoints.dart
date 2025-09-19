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

  // currency endpoints
  static const String exchangeRates = '$baseUrl/api/exchange/rates';
  static const String exchangeCalculate = '$baseUrl/api/exchange/calculate';
  static const String exchangePairs = '$baseUrl/api/exchange/pairs';
  static const String currencies = '$baseUrl/api/exchange/currencies';

  // beneficiary endpoints
  static const String beneficiaries = '$baseUrl/api/beneficiary';

  // notification endpoints
  static const String notifications = '/api/notifications';
  static const String createBeneficiary = '/api/beneficiary';

  // transaction endpoints
  static const String transactions = '$baseUrl/api/transaction';
  static const String transactionEstimate =
      '$baseUrl/api/transaction/estimate-mobile-money-to-crypto';
  static const String createCashToCryptoTransaction =
      '$baseUrl/api/transaction/cash-to-crypto-mobile-money';
  static const String cryptoToCashEstimate =
      '$baseUrl/api/transaction/estimate-crypto-to-fiat';
  static const String createCryptoToCashTransaction =
      '$baseUrl/api/transaction/crypto-to-fiat';

  // wallet endpoints
  static const String walletBalance = '/api/webhooks/walletBalance';
  static const String walletValidation = '/api/wallet-validation/validate';

  // NFT endpoints
  static const String userNFTs = '/api/nft/user-nfts';

  // External API
  static const String countries = 'https://restcountries.com/v3.1/all';
}
