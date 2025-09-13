import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import 'facebook_service.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<ApiResponse<RegistrationResponse>> register(
    RegisterRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        Endpoints.register,
        data: request.toJson(),
      );
      print("what the hell is response $response");
      return ApiResponse<RegistrationResponse>.fromJson(
        response.data,
        (json) => RegistrationResponse.fromJson(json),
      );
    } catch (e) {
      return ApiResponse<RegistrationResponse>(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Login with email and password
  Future<ApiResponse<User>> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        Endpoints.login,
        data: request.toJson(),
      );

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  // Resend verification email
  Future<ApiResponse<dynamic>> resendVerification(String email) async {
    try {
      final response = await _apiClient.post(
        Endpoints.resendVerification,
        data: {'email': email},
      );

      return ApiResponse<dynamic>.fromJson(response.data, (json) => json);
    } catch (e) {
      return ApiResponse<dynamic>(success: false, message: e.toString());
    }
  }

  // Authenticate with Google
  Future<ApiResponse<User>> authenticateWithGoogle(
    SocialAuthRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        Endpoints.googleAuth,
        data: request.toJson(),
      );

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  // Authenticate with Facebook
  Future<ApiResponse<User>> authenticateWithFacebook(
    SocialAuthRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        Endpoints.facebookAuth,
        data: request.toJson(),
      );

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<User>> loginWithFacebookNative() async {
    try {
      debugPrint('🚀 Starting enhanced Facebook login flow');

      final facebookResult = await FacebookService.login();

      if (!facebookResult.isSuccess) {
        if (facebookResult.isCancelled) {
          return ApiResponse<User>(
            success: false,
            message: 'Facebook login was cancelled',
          );
        } else {
          return ApiResponse<User>(
            success: false,
            message: facebookResult.errorMessage ?? 'Facebook login failed',
          );
        }
      }

      final countryName = await FacebookService.getUserCountry();

      final response = await _apiClient.post(
        Endpoints.facebookAuth,
        data: {
          'accessToken': facebookResult.accessToken!,
          'countryName': countryName,
        },
      );

      final apiResponse = ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );

      // Step 4: Save user data if successful
      if (apiResponse.success && apiResponse.data != null) {
        await saveUserData(apiResponse.data!);
        debugPrint('✅ Facebook login completed successfully');
      }

      return apiResponse;
    } catch (e) {
      debugPrint('💥 Facebook login error in AuthService: $e');
      return ApiResponse<User>(
        success: false,
        message: 'Facebook authentication failed: ${e.toString()}',
      );
    }
  }

  // Authenticate with Apple
  Future<ApiResponse<User>> authenticateWithApple(
    SocialAuthRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        Endpoints.appleAuth,
        data: request.toJson(),
      );

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  // Authenticate with Wallet
  Future<ApiResponse<User>> authenticateWithWallet(
    WalletAuthRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        Endpoints.walletAuth,
        data: request.toJson(),
      );

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  // Fetch countries list
  Future<List<CountryModel>> fetchCountries() async {
    try {
      final response = await http.get(Uri.parse(Endpoints.countries));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((country) => CountryModel.fromJson(country)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      throw Exception('Failed to load countries: $e');
    }
  }

  // Save user data to SharedPreferences
  Future<void> saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toJson()));
    await prefs.setString('token', user.token ?? '');

    // Set the token in API client for future requests
    if (user.token != null) {
      _apiClient.setToken(user.token!);
    }
  }

  // Get saved user data
  Future<User?> getSavedUser() async {
    print("🔑 [AUTH_SERVICE] Getting saved user from SharedPreferences");
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    final token = prefs.getString('token');
    print("🔑 [AUTH_SERVICE] userData exists: ${userData != null}, token exists: ${token != null}");

    if (userData != null) {
      final user = User.fromJson(json.decode(userData));
      print("🔑 [AUTH_SERVICE] Parsed user: ${user.email}, token: ${user.token != null ? 'present' : 'null'}");

      // Set the token in API client
      if (user.token != null) {
        _apiClient.setToken(user.token!);
        print("🔑 [AUTH_SERVICE] Token set in API client");
      }

      return user;
    }

    print("🔑 [AUTH_SERVICE] No saved user data found");
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    print("🔑 [AUTH_SERVICE] Checking if user is logged in");
    final user = await getSavedUser();
    final result = user != null && user.token != null;
    print("🔑 [AUTH_SERVICE] isLoggedIn result: $result");
    return result;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }
}
