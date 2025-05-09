class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final ApiErrorData? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json)? dataFromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && dataFromJson != null
          ? dataFromJson(json['data'])
          : null,
      message: json['message'],
      errors: json['errors'] != null
          ? ApiErrorData.fromJson(json['errors'])
          : null,
    );
  }
}

class ApiErrorData {
  final String? code;
  final String? details;

  ApiErrorData({
    this.code,
    this.details,
  });

  factory ApiErrorData.fromJson(Map<String, dynamic> json) {
    return ApiErrorData(
      code: json['code'],
      details: json['details'],
    );
  }
}