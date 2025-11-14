import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
      print('🔥 [AUTH_SERVICE] Making login request to: ${Endpoints.login}');
      print('🔥 [AUTH_SERVICE] Request data: ${request.toJson()}');
      final response = await _apiClient.post(
        Endpoints.login,
        data: request.toJson(),
      );
      print('🔥 [AUTH_SERVICE] Login response received: ${response.statusCode}');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } on DioException catch (e) {
      print('❌ [AUTH_SERVICE] DioException caught: ${e.type}');
      print('❌ [AUTH_SERVICE] DioException message: ${e.message}');
      print('❌ [AUTH_SERVICE] DioException response: ${e.response?.data}');
      
      // Handle structured API error responses (like wrong password)
      if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        if (responseData.containsKey('success') && responseData['success'] == false) {
          // This is a proper API error response, parse it
          return ApiResponse<User>.fromJson(
            responseData,
            (json) => User.fromJson(json),
          );
        }
      }
      // For other DioExceptions, return generic error
      return ApiResponse<User>(success: false, message: e.toString());
    } catch (e) {
      print('❌ [AUTH_SERVICE] General exception caught: $e');
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

  // Forgot password - Request OTP
  Future<ApiResponse<dynamic>> forgotPassword(String email) async {
    try {
      print('🔑 [AUTH_SERVICE] Requesting password reset OTP for: $email');
      final response = await _apiClient.post(
        Endpoints.forgotPassword,
        data: {'email': email},
      );
      print('✅ [AUTH_SERVICE] Forgot password response: ${response.data}');

      return ApiResponse<dynamic>.fromJson(response.data, (json) => json);
    } on DioException catch (e) {
      print('❌ [AUTH_SERVICE] Forgot password error: ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        return ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (json) => json,
        );
      }
      return ApiResponse<dynamic>(success: false, message: e.toString());
    } catch (e) {
      print('❌ [AUTH_SERVICE] Forgot password exception: $e');
      return ApiResponse<dynamic>(success: false, message: e.toString());
    }
  }

  // Reset password with OTP
  Future<ApiResponse<dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      print('🔑 [AUTH_SERVICE] Resetting password for: $email');
      final response = await _apiClient.post(
        Endpoints.resetPassword,
        data: {
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPassword,
        },
      );
      print('✅ [AUTH_SERVICE] Reset password response: ${response.data}');

      return ApiResponse<dynamic>.fromJson(response.data, (json) => json);
    } on DioException catch (e) {
      print('❌ [AUTH_SERVICE] Reset password error: ${e.response?.data}');
      if (e.response?.data is Map<String, dynamic>) {
        return ApiResponse<dynamic>.fromJson(
          e.response!.data as Map<String, dynamic>,
          (json) => json,
        );
      }
      return ApiResponse<dynamic>(success: false, message: e.toString());
    } catch (e) {
      print('❌ [AUTH_SERVICE] Reset password exception: $e');
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
    AppleAuthRequest request,
  ) async {
    try {
      print("🔥 [AUTH_SERVICE] Apple Auth - Request data: ${request.toJson()}");

      final response = await _apiClient.post(
        Endpoints.appleAuth,
        data: request.toJson(),
      );

      print("🔥 [AUTH_SERVICE] Apple Auth - Response: ${response.data}");

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } catch (e) {
      print("❌ [AUTH_SERVICE] Apple Auth error: $e");
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

  // Save user data to SharedPreferences with improved error handling and debugging
  Future<void> saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ensure we have a valid token
      if (user.token == null || user.token!.isEmpty) {
        print("⚠️ [AUTH_SERVICE] ERROR: Attempting to save user without token!");
        print("⚠️ [AUTH_SERVICE] User details: email=${user.email}, id=${user.id}");
        throw Exception('Cannot save user without valid token');
      }

      // Debug: Show what we're about to save
      print("🔑 [AUTH_SERVICE] Saving user data:");
      print("🔑 [AUTH_SERVICE] - User ID: ${user.id}");
      print("🔑 [AUTH_SERVICE] - Email: ${user.email}");
      print("🔑 [AUTH_SERVICE] - Token present: ${user.token != null}");
      print("🔑 [AUTH_SERVICE] - Token length: ${user.token?.length}");
      print("🔑 [AUTH_SERVICE] - Token preview: ${user.token?.substring(0, 20)}...");

      // Save user object as JSON (includes token)
      final userJson = json.encode(user.toJson());
      await prefs.setString('user', userJson);
      print("🔑 [AUTH_SERVICE] ✅ User JSON saved");

      // Save token separately as backup
      await prefs.setString('token', user.token!);
      print("🔑 [AUTH_SERVICE] ✅ Token saved separately");
      
      // Store timestamp for token validation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('tokenTimestamp', timestamp);
      print("🔑 [AUTH_SERVICE] ✅ Token timestamp saved: $timestamp");

      // Set the token in API client for immediate use
      _apiClient.setToken(user.token!);
      print("🔑 [AUTH_SERVICE] ✅ Token set in API client");

      // Verify the save worked by reading it back
      final savedUser = prefs.getString('user');
      final savedToken = prefs.getString('token');
      print("🔑 [AUTH_SERVICE] ✅ Verification - Saved user: ${savedUser != null}");
      print("🔑 [AUTH_SERVICE] ✅ Verification - Saved token: ${savedToken != null}");
      print("🔑 [AUTH_SERVICE] ✅ All user data saved and verified successfully!");
      
    } catch (e) {
      print("❌ [AUTH_SERVICE] CRITICAL ERROR saving user data: $e");
      print("❌ [AUTH_SERVICE] Stack trace: ${StackTrace.current}");
      throw Exception('Failed to save user data: $e');
    }
  }

  // Get saved user data with improved validation and detailed debugging
  Future<User?> getSavedUser() async {
    print("🔑 [AUTH_SERVICE] ==================== GETTING SAVED USER ====================");
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all saved data
      final userData = prefs.getString('user');
      final storedToken = prefs.getString('token');
      final tokenTimestamp = prefs.getInt('tokenTimestamp');
      
      print("🔑 [AUTH_SERVICE] Raw storage check:");
      print("🔑 [AUTH_SERVICE] - User data exists: ${userData != null}");
      print("🔑 [AUTH_SERVICE] - Token exists: ${storedToken != null}");
      print("🔑 [AUTH_SERVICE] - Token timestamp exists: ${tokenTimestamp != null}");
      
      if (userData != null) {
        print("🔑 [AUTH_SERVICE] - User data length: ${userData.length} chars");
        print("🔑 [AUTH_SERVICE] - User data preview: ${userData.substring(0, 100)}...");
      }
      
      if (storedToken != null) {
        print("🔑 [AUTH_SERVICE] - Token length: ${storedToken.length}");
        print("🔑 [AUTH_SERVICE] - Token preview: ${storedToken.substring(0, 20)}...");
      }

      if (userData == null) {
        print("❌ [AUTH_SERVICE] No user data found in storage");
        return null;
      }

      if (storedToken == null || storedToken.isEmpty) {
        print("❌ [AUTH_SERVICE] No token found in storage");
        return null;
      }

      // Check token age
      if (tokenTimestamp != null) {
        final tokenAge = DateTime.now().millisecondsSinceEpoch - tokenTimestamp;
        final tokenAgeDays = tokenAge / (1000 * 60 * 60 * 24);
        print("🔑 [AUTH_SERVICE] Token age: ${tokenAgeDays.toStringAsFixed(2)} days");
      } else {
        print("⚠️ [AUTH_SERVICE] No timestamp found for token");
      }

      // Parse user data
      print("🔑 [AUTH_SERVICE] Parsing user JSON data...");
      final userJson = json.decode(userData) as Map<String, dynamic>;
      
      // Debug the token in the JSON
      print("🔑 [AUTH_SERVICE] Token in user JSON: ${userJson['token'] != null}");
      if (userJson['token'] != null) {
        print("🔑 [AUTH_SERVICE] JSON token preview: ${userJson['token'].toString().substring(0, 20)}...");
      }
      
      // Ensure token from separate storage takes precedence (more reliable)
      userJson['token'] = storedToken;
      print("🔑 [AUTH_SERVICE] ✅ Token injected from separate storage");
      
      final user = User.fromJson(userJson);
      print("🔑 [AUTH_SERVICE] ✅ User parsed successfully:");
      print("🔑 [AUTH_SERVICE] - Email: ${user.email}");
      print("🔑 [AUTH_SERVICE] - ID: ${user.id}");
      print("🔑 [AUTH_SERVICE] - Token present: ${user.token != null}");
      print("🔑 [AUTH_SERVICE] - Token length: ${user.token?.length}");

      // CRITICAL: Always set the token in API client when loading user
      if (user.token != null) {
        _apiClient.setToken(user.token!);
        print("🔑 [AUTH_SERVICE] ✅ Token set in API client");
      } else {
        print("❌ [AUTH_SERVICE] CRITICAL ERROR: User loaded but no token!");
        return null;
      }

      print("🔑 [AUTH_SERVICE] ================ USER LOADED SUCCESSFULLY ================");
      return user;
      
    } catch (e) {
      print("❌ [AUTH_SERVICE] CRITICAL ERROR loading saved user: $e");
      print("❌ [AUTH_SERVICE] Stack trace: ${StackTrace.current}");
      // Clear potentially corrupted data
      await logout();
      return null;
    }
  }

  // Connect wallet address to existing user
  Future<ApiResponse<User>> connectWallet(String walletAddress, String walletType) async {
    try {
      print('🔗 [AUTH_SERVICE] Connecting wallet: $walletAddress, type: $walletType');
      final response = await _apiClient.post(
        Endpoints.walletConnect,
        data: {
          'walletAddress': walletAddress,
          'walletType': walletType,
        },
      );
      print('✅ [AUTH_SERVICE] Wallet connection response: ${response.data}');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json),
      );
    } on DioException catch (e) {
      print('❌ [AUTH_SERVICE] DioException during wallet connection: ${e.type}');
      print('❌ [AUTH_SERVICE] DioException message: ${e.message}');
      print('❌ [AUTH_SERVICE] DioException response: ${e.response?.data}');

      if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        if (responseData.containsKey('success')) {
          // Return the error response from API (e.g., "wallet already connected")
          return ApiResponse<User>(
            success: responseData['success'] ?? false,
            message: responseData['message'] ?? 'Failed to connect wallet',
            data: null,
          );
        }
      }
      return ApiResponse<User>(success: false, message: e.toString());
    } catch (e) {
      print('❌ [AUTH_SERVICE] General exception during wallet connection: $e');
      return ApiResponse<User>(success: false, message: e.toString());
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    print("🔑 [AUTH_SERVICE] Checking if user is logged in");
    final user = await getSavedUser();
    final result = user != null && user.token != null;
    print("🔑 [AUTH_SERVICE] isLoggedIn result: $result");
    return result;
  }

  // Logout user with thorough cleanup
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
      await prefs.remove('tokenTimestamp');
      
      // Clear token from API client
      _apiClient.clearToken();
      
      print("🔑 [AUTH_SERVICE] Logout completed - all data cleared");
    } catch (e) {
      print("❌ [AUTH_SERVICE] Error during logout: $e");
    }
  }
}
