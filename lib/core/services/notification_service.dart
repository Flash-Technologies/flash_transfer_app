
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/notification_model.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  /// Fetch notifications with pagination
  Future<NotificationsResponseModel> fetchNotifications({
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      print('🌐 Fetching notifications - Page: $page, Limit: $limit');

      final response = await _apiClient.get(
        Endpoints.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sortBy': sortBy,
          'sortOrder': sortOrder,
        },
      );

      print('📡 Notifications Response: ${response.data}');

      return NotificationsResponseModel.fromJson(response.data);
    } catch (e) {
      print('❌ Notification Service Error: $e');
      if (e.toString().contains('401')) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (e.toString().contains('403')) {
        throw Exception('Access forbidden. Please check your permissions.');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error. Please try again later.');
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      throw Exception('Failed to load notifications. Please try again.');
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      print('📝 Marking notification as read - ID: $notificationId');

      await _apiClient.put('/api/notifications/$notificationId/read');

      print('✅ Notification marked as read successfully');
      return true;
    } catch (e) {
      print('❌ Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      print('📝 Marking all notifications as read');

      await _apiClient.put('/api/notifications/read-all');

      print('✅ All notifications marked as read successfully');
      return true;
    } catch (e) {
      print('❌ Failed to mark all notifications as read: $e');
      return false;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get('/api/notifications/unread-count');
      return response.data['count'] ?? 0;
    } catch (e) {
      print('❌ Failed to get unread notification count: $e');
      return 0;
    }
  }
}