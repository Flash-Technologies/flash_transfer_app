import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  // Register a new user
  Future<ApiResponse<RegistrationResponse>> register(
    RegisterRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        Endpoints.register,
        data: request.toJson(),
      );

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
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData != null) {
      final user = User.fromJson(json.decode(userData));

      // Set the token in API client
      if (user.token != null) {
        _apiClient.setToken(user.token!);
      }

      return user;
    }

    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getSavedUser();
    return user != null && user.token != null;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }
}
