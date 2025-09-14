class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String type;
  final DateTime createdAt;
  final int userId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    required this.createdAt,
    required this.userId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userId: json['userId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'isRead': isRead,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    bool? isRead,
    String? type,
    DateTime? createdAt,
    int? userId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'NotificationModel{id: $id, title: $title, message: $message, isRead: $isRead, type: $type, createdAt: $createdAt, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.isRead == isRead &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        message.hashCode ^
        isRead.hashCode ^
        type.hashCode ^
        createdAt.hashCode ^
        userId.hashCode;
  }
}

class NotificationsPaginationModel {
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  NotificationsPaginationModel({
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory NotificationsPaginationModel.fromJson(Map<String, dynamic> json) {
    return NotificationsPaginationModel(
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalCount: json['totalCount'] as int,
      totalPages: json['totalPages'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPrevPage: json['hasPrevPage'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'totalCount': totalCount,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPrevPage': hasPrevPage,
    };
  }
}

class NotificationsResponseModel {
  final bool success;
  final List<NotificationModel> notifications;
  final NotificationsPaginationModel pagination;
  final String message;

  NotificationsResponseModel({
    required this.success,
    required this.notifications,
    required this.pagination,
    required this.message,
  });

  factory NotificationsResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationsResponseModel(
      success: json['success'] as bool,
      notifications: (data['notifications'] as List<dynamic>)
          .map((notification) => NotificationModel.fromJson(notification as Map<String, dynamic>))
          .toList(),
      pagination: NotificationsPaginationModel.fromJson(data['pagination'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': {
        'notifications': notifications.map((notification) => notification.toJson()).toList(),
        'pagination': pagination.toJson(),
      },
      'message': message,
    };
  }
}