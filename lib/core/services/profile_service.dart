import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flash_transfer_app/core/api/api_client.dart';
import 'package:flash_transfer_app/core/api/endpoints.dart';
import 'package:flash_transfer_app/core/models/user.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient(baseUrl: Endpoints.baseUrl);

  // Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _apiClient.get('/user/preferences');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load preferences: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error loading preferences: ${e.message}');
    } catch (error) {
      throw Exception('Failed to load preferences: $error');
    }
  }

  // Update user avatar
  Future<bool> updateAvatar(String imagePath) async {
    try {
      final file = File(imagePath);

      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _apiClient.post(
        '/user/avatar',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Network error updating avatar: ${e.message}');
    } catch (error) {
      throw Exception('Failed to update avatar: $error');
    }
  }

  // Update user preference
  Future<void> updatePreference(String key, dynamic value) async {
    try {
      final response = await _apiClient.put(
        '/user/preferences',
        data: {key: value},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update preference: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error updating preference: ${e.message}');
    } catch (error) {
      throw Exception('Failed to update preference: $error');
    }
  }

  // Update profile information
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiClient.put('/user/profile', data: profileData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception('Network error updating profile: ${e.message}');
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  // Get user profile
  Future<User> getUserProfile() async {
    try {
      final response = await _apiClient.get('/user/profile');

      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      } else {
        throw Exception('Failed to load profile: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error loading profile: ${e.message}');
    } catch (error) {
      throw Exception('Failed to load profile: $error');
    }
  }

  // Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.put(
        '/user/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Current password is incorrect');
      }
      throw Exception('Network error updating password: ${e.message}');
    } catch (error) {
      throw Exception('Failed to update password: $error');
    }
  }

  // Enable/disable two-factor authentication
  Future<Map<String, dynamic>> toggleTwoFactorAuth(bool enable) async {
    try {
      final response = await _apiClient.post(
        '/user/2fa/toggle',
        data: {'enabled': enable},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to toggle 2FA: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error toggling 2FA: ${e.message}');
    } catch (error) {
      throw Exception('Failed to toggle 2FA: $error');
    }
  }

  // Delete user account
  Future<bool> deleteAccount({required String password}) async {
    try {
      final response = await _apiClient.delete(
        '/user/account',
        data: {'password': password},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Password is incorrect');
      }
      throw Exception('Network error deleting account: ${e.message}');
    } catch (error) {
      throw Exception('Failed to delete account: $error');
    }
  }

  // Get user statistics (transactions, etc.)
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _apiClient.get('/user/stats');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load stats: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error loading stats: ${e.message}');
    } catch (error) {
      throw Exception('Failed to load stats: $error');
    }
  }

  // Upload profile image from camera/gallery
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _apiClient.post(
        '/user/profile-image',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        return response.data['imageUrl'] as String?;
      } else {
        throw Exception('Failed to upload image: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error uploading image: ${e.message}');
    } catch (error) {
      throw Exception('Failed to upload image: $error');
    }
  }

  // Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final response = await _apiClient.get('/user/notification-settings');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(key, value as bool));
      } else {
        throw Exception(
          'Failed to load notification settings: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        'Network error loading notification settings: ${e.message}',
      );
    } catch (error) {
      throw Exception('Failed to load notification settings: $error');
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final response = await _apiClient.put(
        '/user/notification-settings',
        data: settings,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update notification settings: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception(
        'Network error updating notification settings: ${e.message}',
      );
    } catch (error) {
      throw Exception('Failed to update notification settings: $error');
    }
  }

  // Get privacy settings
  Future<Map<String, dynamic>> getPrivacySettings() async {
    try {
      final response = await _apiClient.get('/user/privacy-settings');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to load privacy settings: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error loading privacy settings: ${e.message}');
    } catch (error) {
      throw Exception('Failed to load privacy settings: $error');
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    try {
      final response = await _apiClient.put(
        '/user/privacy-settings',
        data: settings,
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update privacy settings: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw Exception('Network error updating privacy settings: ${e.message}');
    } catch (error) {
      throw Exception('Failed to update privacy settings: $error');
    }
  }
}
