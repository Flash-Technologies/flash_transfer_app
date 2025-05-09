class Endpoints {
  static const String baseUrl = 'https://flash-transfer.com';
  
  // Auth endpoints
  static const String register = '/api/user/register-email';
  static const String login = '/api/user/sign-in';
  static const String verifyEmail = '/api/user/verify-email';
  static const String resendVerification = '/api/user/resend-verification';
  static const String googleAuth = '/api/user/authenticate-google';
  static const String facebookAuth = '/api/user/authenticate-facebook';

  // External API
  static const String countries = 'https://restcountries.com/v3.1/all';
}