import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacebookService {
  static const String _appId = '967460942254022';

  /// Initialize Facebook SDK for the current platform
  static Future<void> initialize() async {
    try {
      // For web platform, initialize with specific settings
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: _appId,
        cookie: true,
        xfbml: true,
        version: "v18.0",
      );
      debugPrint('✅ Facebook SDK initialized successfully');
    } catch (e) {
      debugPrint('❌ Facebook SDK initialization failed: $e');
    }
  }

  /// Perform native Facebook login
  static Future<FacebookLoginResult> login() async {
    try {
      debugPrint('🔐 Starting Facebook native login...');

      // Clear any existing login session first
      await FacebookAuth.instance.logOut();

      // Perform login with required permissions
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
        loginBehavior:
            LoginBehavior.nativeWithFallback, // Use native login with fallback
      );

      debugPrint('📱 Facebook login status: ${result.status}');
      debugPrint('📱 Facebook login message: ${result.message}');

      switch (result.status) {
        case LoginStatus.success:
          if (result.accessToken != null) {
            debugPrint('✅ Facebook login successful');
            debugPrint(
              '🔑 Access Token: ${result.accessToken!.token}',
            );

            // Get user data
            final userData = await _getUserData(result.accessToken!.token);

            return FacebookLoginResult.success(
              accessToken: result.accessToken!.token,
              userData: userData,
            );
          } else {
            debugPrint('❌ Facebook login success but no access token');
            return FacebookLoginResult.error('Access token not found');
          }

        case LoginStatus.cancelled:
          debugPrint('❌ Facebook login cancelled by user');
          return FacebookLoginResult.cancelled();

        case LoginStatus.failed:
          debugPrint('❌ Facebook login failed: ${result.message}');
          return FacebookLoginResult.error(result.message ?? 'Login failed');

        case LoginStatus.operationInProgress:
          debugPrint('⏳ Facebook login operation in progress');
          return FacebookLoginResult.error(
            'Login operation already in progress',
          );

        default:
          debugPrint('❌ Facebook login unknown status: ${result.status}');
          return FacebookLoginResult.error('Unknown login status');
      }
    } catch (e) {
      debugPrint('💥 Facebook login error: $e');
      return FacebookLoginResult.error('Login error: ${e.toString()}');
    }
  }

  /// Get user data using access token
  static Future<Map<String, dynamic>?> _getUserData(String accessToken) async {
    try {
      final userData = await FacebookAuth.instance.getUserData(
        fields: "name,email,picture.width(200),first_name,last_name",
      );

      debugPrint('👤 Facebook user data: $userData');
      return userData;
    } catch (e) {
      debugPrint('❌ Failed to get Facebook user data: $e');
      return null;
    }
  }

  /// Get user's country using IP geolocation
  static Future<String> getUserCountry() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://ipapi.co/json/'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final country = data['country_name'] as String?;
        debugPrint('🌍 User country detected: $country');
        return country ?? 'Unknown';
      } else {
        debugPrint('❌ Failed to get country: HTTP ${response.statusCode}');
        return 'Unknown';
      }
    } catch (e) {
      debugPrint('❌ Failed to get user country: $e');
      return 'Unknown';
    }
  }

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      return accessToken != null && !accessToken.isExpired;
    } catch (e) {
      debugPrint('❌ Error checking Facebook login status: $e');
      return false;
    }
  }

  /// Logout from Facebook
  static Future<void> logout() async {
    try {
      await FacebookAuth.instance.logOut();
      debugPrint('✅ Facebook logout successful');
    } catch (e) {
      debugPrint('❌ Facebook logout error: $e');
    }
  }

  /// Get current access token
  static Future<String?> getCurrentAccessToken() async {
    try {
      final accessToken = await FacebookAuth.instance.accessToken;
      return accessToken?.token;
    } catch (e) {
      debugPrint('❌ Error getting Facebook access token: $e');
      return null;
    }
  }
}

/// Result class for Facebook login operations
class FacebookLoginResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? accessToken;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  const FacebookLoginResult._({
    required this.isSuccess,
    required this.isCancelled,
    this.accessToken,
    this.userData,
    this.errorMessage,
  });

  /// Success result
  factory FacebookLoginResult.success({
    required String accessToken,
    Map<String, dynamic>? userData,
  }) {
    return FacebookLoginResult._(
      isSuccess: true,
      isCancelled: false,
      accessToken: accessToken,
      userData: userData,
    );
  }

  /// Cancelled result
  factory FacebookLoginResult.cancelled() {
    return const FacebookLoginResult._(isSuccess: false, isCancelled: true);
  }

  /// Error result
  factory FacebookLoginResult.error(String message) {
    return FacebookLoginResult._(
      isSuccess: false,
      isCancelled: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'FacebookLoginResult.success(accessToken: ${accessToken?.substring(0, 20)}...)';
    } else if (isCancelled) {
      return 'FacebookLoginResult.cancelled()';
    } else {
      return 'FacebookLoginResult.error($errorMessage)';
    }
  }
}
