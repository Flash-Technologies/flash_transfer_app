// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio = Dio();
  final String baseUrl;

  ApiClient({required this.baseUrl}) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.responseType = ResponseType.json;

    // Add auth interceptor to handle token issues
    _dio.interceptors.add(_createAuthInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure token is always loaded from storage for each request
        await _ensureTokenFromStorage(options);
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized errors
        if (error.response?.statusCode == 401) {
          print('🔐 Received 401 error - token may be expired or invalid');
          print('🔐 Request path: ${error.requestOptions.path}');
          print('🔐 Response: ${error.response?.data}');
          
          // Clear the invalid token
          clearToken();
          await _clearStoredToken();
          
          // You can add a callback here to notify auth provider about token expiration
          // This will be handled by the services that catch this error
        }
        handler.next(error);
      },
    );
  }

  Future<void> _ensureTokenFromStorage(RequestOptions options) async {
    print('🔐 [API_CLIENT] Checking token for request: ${options.path}');
    print('🔐 [API_CLIENT] Current Authorization header: ${options.headers['Authorization']}');
    
    // Only add token if it's not already in the headers
    if (options.headers['Authorization'] == null) {
      print('🔐 [API_CLIENT] No Authorization header found, loading from storage...');
      
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        print('🔐 [API_CLIENT] Token in storage: ${token != null}');
        if (token != null) {
          print('🔐 [API_CLIENT] Token length: ${token.length}');
          print('🔐 [API_CLIENT] Token preview: ${token.substring(0, 20)}...');
        }
        
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 [API_CLIENT] ✅ Auto-loaded token from storage for request: ${options.path}');
        } else {
          print('⚠️ [API_CLIENT] WARNING: No token found in storage for request: ${options.path}');
        }
      } catch (e) {
        print('❌ [API_CLIENT] ERROR loading token from storage: $e');
      }
    } else {
      print('🔐 [API_CLIENT] ✅ Authorization header already present for request: ${options.path}');
    }
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    print('🔐 Cleared stored token due to 401 error');
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('🔐 Token set in ApiClient: Bearer ${token.substring(0, 10)}...');
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
    print('🔐 Token cleared from ApiClient');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out');
      case DioExceptionType.connectionError:
        return Exception('No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        // For API responses with structured error data, don't throw exception
        // Let the service layer handle the response structure
        if (responseData is Map<String, dynamic> && 
            responseData.containsKey('success') && 
            responseData['success'] == false) {
          // This is a proper API error response, re-throw as DioException 
          // so the auth service can parse it properly
          throw e;
        }

        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? 'An error occurred';
          final errorDetails =
              responseData['errors'] is Map<String, dynamic>
                  ? responseData['errors']['details']
                  : null;

          return Exception(errorDetails ?? message);
        }

        if (statusCode == 401) {
          return Exception('Unauthorized. Please log in again.');
        } else if (statusCode == 404) {
          return Exception('Resource not found');
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later.');
        }

        return Exception('Request failed with status: $statusCode');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
      default:
        if (e.message?.contains('SocketException') ?? false) {
          return Exception('No internet connection');
        }
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }
}
