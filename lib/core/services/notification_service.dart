

// import 'package:dio/dio.dart';
// import 'package:flash_transfer_app/core/api/api_client.dart';
// import 'package:flash_transfer_app/core/models/notification.dart';

// class NotificationService {
//   final ApiClient _apiClient;

//   NotificationService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

//   // Get all notifications
//   Future<List<AppNotification>> getNotifications({
//     int page = 1,
//     int limit = 20,
//   }) async {
//     try {
//       final response = await _apiClient.get('/notifications', queryParameters: {
//         'page': page,
//         'limit': limit,
//       });
      
//       if (response.statusCode == 200) {
//         final List<dynamic> data = response.data['notifications'] as List<dynamic>;
//         return data.map((item) => AppNotification.fromJson(item)).toList();
//       } else {
//         throw Exception('Failed to load notifications: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error loading notifications: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to load notifications: $error');
//     }
//   }

//   // Mark notification as read
//   Future<void> markAsRead(String notificationId) async {
//     try {
//       final response = await _apiClient.put('/notifications/$notificationId/read');
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to mark notification as read: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error marking notification as read: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to mark notification as read: $error');
//     }
//   }

//   // Mark all notifications as read
//   Future<void> markAllAsRead() async {
//     try {
//       final response = await _apiClient.put('/notifications/read-all');
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to mark all notifications as read: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error marking all notifications as read: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to mark all notifications as read: $error');
//     }
//   }

//   // Delete notification
//   Future<void> deleteNotification(String notificationId) async {
//     try {
//       final response = await _apiClient.delete('/notifications/$notificationId');
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to delete notification: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error deleting notification: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to delete notification: $error');
//     }
//   }

//   // Delete all notifications
//   Future<void> deleteAllNotifications() async {
//     try {
//       final response = await _apiClient.delete('/notifications/all');
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to delete all notifications: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error deleting all notifications: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to delete all notifications: $error');
//     }
//   }

//   // Get unread notification count
//   Future<int> getUnreadCount() async {
//     try {
//       final response = await _apiClient.get('/notifications/unread-count');
      
//       if (response.statusCode == 200) {
//         return response.data['count'] as int;
//       } else {
//         throw Exception('Failed to get unread count: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error getting unread count: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to get unread count: $error');
//     }
//   }

//   // Send push notification token to server
//   Future<void> updatePushToken(String token) async {
//     try {
//       final response = await _apiClient.post('/notifications/push-token', data: {
//         'token': token,
//       });
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to update push token: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error updating push token: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to update push token: $error');
//     }
//   }

//   // Get notification preferences
//   Future<Map<String, bool>> getNotificationPreferences() async {
//     try {
//       final response = await _apiClient.get('/notifications/preferences');
      
//       if (response.statusCode == 200) {
//         final data = response.data as Map<String, dynamic>;
//         return data.map((key, value) => MapEntry(key, value as bool));
//       } else {
//         throw Exception('Failed to load notification preferences: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error loading notification preferences: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to load notification preferences: $error');
//     }
//   }

//   // Update notification preferences
//   Future<void> updateNotificationPreferences(Map<String, bool> preferences) async {
//     try {
//       final response = await _apiClient.put('/notifications/preferences', data: preferences);
      
//       if (response.statusCode != 200) {
//         throw Exception('Failed to update notification preferences: ${response.statusMessage}');
//       }
//     } on DioException catch (e) {
//       throw Exception('Network error updating notification preferences: ${e.message}');
//     } catch (error) {
//       throw Exception('Failed to update notification preferences: $error');
//     }
//   }
// }