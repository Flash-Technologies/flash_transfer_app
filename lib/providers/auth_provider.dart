import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../core/models/api_response.dart';
import '../core/models/auth_models.dart';
import '../core/models/user.dart';
import '../core/services/auth_service.dart';
import 'dart:async';
import 'dart:convert';
import 'user_provider.dart';

// API Client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: Endpoints.baseUrl);
});

// Authenticated API Client provider with detailed debugging
final authenticatedApiClientProvider = Provider<ApiClient>((ref) {
  print('🔐 [API_CLIENT_PROVIDER] ============ CREATING AUTHENTICATED API CLIENT ============');
  
  final authState = ref.watch(authProvider);
  
  print('🔐 [API_CLIENT_PROVIDER] Auth state:');
  print('🔐 [API_CLIENT_PROVIDER] - Status: ${authState.status}');
  print('🔐 [API_CLIENT_PROVIDER] - User exists: ${authState.user != null}');
  print('🔐 [API_CLIENT_PROVIDER] - User ID: ${authState.user?.id}');
  print('🔐 [API_CLIENT_PROVIDER] - User email: ${authState.user?.email}');
  print('🔐 [API_CLIENT_PROVIDER] - Token exists: ${authState.user?.token != null}');
  
  if (authState.user?.token != null) {
    print('🔐 [API_CLIENT_PROVIDER] - Token length: ${authState.user!.token!.length}');
    print('🔐 [API_CLIENT_PROVIDER] - Token preview: ${authState.user!.token!.substring(0, 20)}...');
  }
  
  // Create API client instance
  final apiClient = ApiClient(baseUrl: Endpoints.baseUrl);
  print('🔐 [API_CLIENT_PROVIDER] ✅ API client created');
  
  // Set token if available
  if (authState.user?.token != null && authState.user!.token!.isNotEmpty) {
    print('🔐 [API_CLIENT_PROVIDER] Setting auth token in API client...');
    apiClient.setToken(authState.user!.token!);
    print('🔐 [API_CLIENT_PROVIDER] ✅ Token set successfully');
  } else {
    print('⚠️ [API_CLIENT_PROVIDER] WARNING: No valid auth token available!');
    print('⚠️ [API_CLIENT_PROVIDER] - User: ${authState.user?.email ?? 'null'}');
    print('⚠️ [API_CLIENT_PROVIDER] - Status: ${authState.status}');
    print('⚠️ [API_CLIENT_PROVIDER] - Token null: ${authState.user?.token == null}');
    print('⚠️ [API_CLIENT_PROVIDER] - Token empty: ${authState.user?.token?.isEmpty ?? true}');
    
    // Clear any existing token if user is no longer authenticated
    if (authState.status == AuthStatus.unauthenticated) {
      print('🔐 [API_CLIENT_PROVIDER] Clearing token due to unauthenticated status');
      apiClient.clearToken();
    }
  }
  
  print('🔐 [API_CLIENT_PROVIDER] ============ API CLIENT READY ============');
  return apiClient;
});

// Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// Auth state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  registering,
  verifying,
  registration_failed,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? message;
  final bool isLoading;
  final Map<String, String>? fieldErrors;

  AuthState({
    required this.status,
    this.user,
    this.message,
    this.isLoading = false,
    this.fieldErrors,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? message,
    bool? isLoading,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;
  final _controller = StreamController<AuthState>.broadcast();

  // Expose a stream of auth state changes
  Stream<AuthState> get stream => _controller.stream;

  AuthNotifier(this._authService, this._ref)
      : super(AuthState(status: AuthStatus.initial, isLoading: true)) {
    _initialize();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _updateState(AuthState newState) {
    state = newState;
    _controller.add(newState);
  }

  Future<void> _initialize() async {
    print("🔑 [AUTH_PROVIDER] Starting authentication initialization");
    // Set to initial state with loading flag
    state = AuthState(status: AuthStatus.initial, isLoading: true);

    try {
      print("🔑 [AUTH_PROVIDER] Checking if user is logged in...");
      final isLoggedIn = await _authService.isLoggedIn();
      print("🔑 [AUTH_PROVIDER] isLoggedIn result: $isLoggedIn");
      
      if (isLoggedIn) {
        print("🔑 [AUTH_PROVIDER] Getting saved user data...");
        final user = await _authService.getSavedUser();
        print("🔑 [AUTH_PROVIDER] Saved user: ${user?.email}, token: ${user?.token != null ? 'present' : 'null'}");
        
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        );
        print("🔑 [AUTH_PROVIDER] Auth state set to AUTHENTICATED");
      } else {
        print("🔑 [AUTH_PROVIDER] No saved user found, setting to UNAUTHENTICATED");
        state = AuthState(status: AuthStatus.unauthenticated, isLoading: false);
      }
    } catch (e) {
      // Handle initialization errors
      print("🔑 [AUTH_PROVIDER] Initialization error: ${e.toString()}");
      state = AuthState(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        message: "Failed to initialize: ${e.toString()}",
      );
    }
    print("🔑 [AUTH_PROVIDER] Auth initialization completed. Final status: ${state.status}");
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(
      isLoading: true,
      fieldErrors: null,
      status: AuthStatus.registering,
    );

    try {
      final response = await _authService.register(request);

      if (response.success) {
        state = state.copyWith(
          message: response.message,
          isLoading: false,
          status: AuthStatus.registering,
        );
        return true;
      } else {
        Map<String, String>? fieldErrors;

        if (response.errors != null &&
            response.errors!.rawErrors != null &&
            response.errors!.rawErrors!.containsKey('FV')) {
          final fvErrors =
              response.errors!.rawErrors!['FV'] as Map<String, dynamic>;
          fieldErrors = {};

          fvErrors.forEach((field, errorList) {
            if (errorList is List && errorList.isNotEmpty) {
              fieldErrors![field] = errorList.first.toString();
            }
          });
        }

        state = state.copyWith(
          status: AuthStatus.registration_failed,
          message: response.message,
          isLoading: false,
          fieldErrors: fieldErrors,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.registration_failed,
        message: 'Registration error: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  String _extractErrorMessage(ApiResponse<dynamic> response) {
    String errorMessage = response.message ?? 'An error occurred';

    // Try to extract detailed error message from response data if available
    if (response.data != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;

      // Check for errors object
      if (data.containsKey('errors')) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          // Field validation errors - e.g. FV field
          if (errors.containsKey('FV') &&
              errors['FV'] is Map<String, dynamic>) {
            final fvErrors = errors['FV'] as Map<String, dynamic>;
            if (fvErrors.isNotEmpty) {
              // Get the first field error
              final firstFieldKey = fvErrors.keys.first;
              final fieldErrors = fvErrors[firstFieldKey];
              if (fieldErrors is List && fieldErrors.isNotEmpty) {
                return fieldErrors.first.toString();
              }
            }
          }
          // Try to extract code-specific errors (common pattern)
          else if (errors.containsKey('CD') &&
              errors['CD'] is Map<String, dynamic>) {
            final cdErrors = errors['CD'] as Map<String, dynamic>;
            // Get the first error code message
            if (cdErrors.isNotEmpty) {
              final firstErrorKey = cdErrors.keys.first;
              return cdErrors[firstErrorKey]?.toString() ?? errorMessage;
            }
          }
          // Check for code and details format
          else if (errors.containsKey('code') &&
              errors.containsKey('details')) {
            // Alternative error format with code and details
            return errors['details']?.toString() ?? errorMessage;
          }
          // If no specific pattern, just get the first error
          else if (errors.isNotEmpty) {
            final firstErrorKey = errors.keys.first;
            if (errors[firstErrorKey] is String) {
              return errors[firstErrorKey];
            } else if (errors[firstErrorKey] is Map<String, dynamic>) {
              final subErrors = errors[firstErrorKey] as Map<String, dynamic>;
              if (subErrors.isNotEmpty) {
                return subErrors.values.first?.toString() ?? errorMessage;
              }
            }
          }
        }
      }
    }

    return errorMessage;
  }

  Future<bool> login(LoginRequest request) async {
    // Set loading state
    state = state.copyWith(isLoading: true, message: null);

    try {
      final response = await _authService.login(request);

      if (response.success && response.data != null) {
        await _authService.saveUserData(response.data!);
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.data,
          message: response.message,
          isLoading: false,
        );

        // Update user provider
        _ref.read(userProvider.notifier).updateUser(response.data!);

        return true;
      } else {
        // Extract error message from the response
        String errorMessage = response.message ?? 'Login failed';
        if (response.data != null &&
            response.data is Map<String, dynamic> &&
            (response.data as Map<String, dynamic>)['errors']
                is Map<String, dynamic>) {
          final errors = (response.data as Map<String, dynamic>)['errors']
              as Map<String, dynamic>;
          if (errors['CD'] is Map<String, dynamic>) {
            final cdErrors = errors['CD'] as Map<String, dynamic>;
            errorMessage = cdErrors['CD02']?.toString() ?? errorMessage;
          }
        }

        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          message: errorMessage,
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      // Handle exceptions
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: "Authentication error: ${e.toString()}",
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle(String idToken, String countryName) async {
    _updateState(state.copyWith(isLoading: true));
    try {
      final response = await _authService.authenticateWithGoogle(
        SocialAuthRequest(token: idToken, countryName: countryName),
      );
      print("🔑 [AUTH_PROVIDER] Login with Google response: $response");
      if (response.success && response.data != null) {
        await _authService.saveUserData(response.data!);
        _updateState(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.data,
            message: response.message,
            isLoading: false,
          ),
        );

        // Update user provider
        _ref.read(userProvider.notifier).updateUser(response.data!);

        return true;
      } else {
        final errorMessage = _extractErrorMessage(response);
        _updateState(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: errorMessage,
            isLoading: false,
          ),
        );
        return false;
      }
    } catch (e) {
      _updateState(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Error: ${e.toString()}',
          isLoading: false,
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithFacebook(String accessToken, String countryName) async {
    _updateState(state.copyWith(isLoading: true));
    try {
      final response = await _authService.authenticateWithFacebook(
        SocialAuthRequest(token: accessToken, countryName: countryName),
      );

      if (response.success && response.data != null) {
        await _authService.saveUserData(response.data!);
        _updateState(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.data,
            message: response.message,
            isLoading: false,
          ),
        );
        return true;
      } else {
        final errorMessage = _extractErrorMessage(response);
        _updateState(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: errorMessage,
            isLoading: false,
          ),
        );
        return false;
      }
    } catch (e) {
      _updateState(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Error: ${e.toString()}',
          isLoading: false,
        ),
      );
      return false;
    }
  }

  // Enhanced Facebook Login using native SDK
  Future<bool> loginWithFacebookNative() async {
    _updateState(state.copyWith(isLoading: true));
    try {
      final response = await _authService.loginWithFacebookNative();

      if (response.success && response.data != null) {
        _updateState(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.data,
            message: response.message,
            isLoading: false,
          ),
        );
        return true;
      } else {
        final errorMessage = _extractErrorMessage(response);
        _updateState(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: errorMessage,
            isLoading: false,
          ),
        );
        return false;
      }
    } catch (e) {
      _updateState(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Enhanced Facebook login error: ${e.toString()}',
          isLoading: false,
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithApple(String idToken, String countryName) async {
    _updateState(state.copyWith(isLoading: true));
    try {
      final response = await _authService.authenticateWithApple(
        SocialAuthRequest(token: idToken, countryName: countryName),
      );

      if (response.success && response.data != null) {
        await _authService.saveUserData(response.data!);
        _updateState(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.data,
            message: response.message,
            isLoading: false,
          ),
        );
        return true;
      } else {
        final errorMessage = _extractErrorMessage(response);
        _updateState(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: errorMessage,
            isLoading: false,
          ),
        );
        return false;
      }
    } catch (e) {
      _updateState(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Error: ${e.toString()}',
          isLoading: false,
        ),
      );
      return false;
    }
  }

  Future<bool> loginWithWallet(String walletAddress, String signature, {String countryName = 'Unknown'}) async {
    _updateState(state.copyWith(isLoading: true));
    try {
      final response = await _authService.authenticateWithWallet(
        WalletAuthRequest(walletAddress: walletAddress, countryName: countryName),
      );

      if (response.success && response.data != null) {
        await _authService.saveUserData(response.data!);
        _updateState(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.data,
            message: response.message,
            isLoading: false,
          ),
        );
        return true;
      } else {
        _updateState(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: response.message,
            isLoading: false,
          ),
        );
        return false;
      }
    } catch (e) {
      _updateState(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Error: ${e.toString()}',
          isLoading: false,
        ),
      );
      return false;
    }
  }

  // For wallet login without signature (simplified version)
  Future<bool> loginWithWalletAddress(
    String walletAddress,
    String countryName,
  ) async {
    _updateState(state.copyWith(isLoading: true));
    try {
      // For this implementation, since we're just sending the wallet address
      // We'll use a placeholder for signature requirement
      final response = await _authService.authenticateWithWallet(
        WalletAuthRequest(walletAddress: walletAddress, countryName: countryName),
      );

      if (response.success && response.data != null) {
        await _authService.saveUserData(response.data!);
        _updateState(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.data,
            message: response.message,
            isLoading: false,
          ),
        );
        return true;
      } else {
        _updateState(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: response.message,
            isLoading: false,
          ),
        );
        return false;
      }
    } catch (e) {
      _updateState(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'Error: ${e.toString()}',
          isLoading: false,
        ),
      );
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    _updateState(state.copyWith(isLoading: true));

    final response = await _authService.resendVerification(email);

    _updateState(state.copyWith(message: response.message, isLoading: false));

    return response.success;
  }

  Future<void> logout() async {
    await _authService.logout();
    _updateState(
      state.copyWith(status: AuthStatus.unauthenticated, user: null),
    );
  }

  // Handle automatic logout for expired tokens
  void handleTokenExpiration() {
    print("🔐 [AUTH_PROVIDER] Handling token expiration - logging out user");
    _updateState(
      state.copyWith(
        status: AuthStatus.unauthenticated, 
        user: null,
        message: "Session expired. Please log in again."
      ),
    );
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

// Countries provider
final countriesProvider = FutureProvider<List<CountryModel>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.fetchCountries();
});
