class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, List<String>>? fieldErrors;
  final ApiErrorData? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    this.fieldErrors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json)? dataFromJson,
  ) {
    // Extract field validation errors if present
    Map<String, List<String>>? fieldErrors;
    
    if (json['errors'] != null && 
        json['errors'] is Map<String, dynamic> &&
        json['errors']['FV'] != null) {
      
      fieldErrors = {};
      final fvErrors = json['errors']['FV'] as Map<String, dynamic>;
      
      fvErrors.forEach((field, errorsList) {
        if (errorsList is List) {
          fieldErrors![field] = List<String>.from(errorsList.map((e) => e.toString()));
        }
      });
    }
    
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null && dataFromJson != null
          ? dataFromJson(json['data'])
          : null,
      message: json['message'],
      errors: json['errors'] != null ? ApiErrorData.fromJson(json['errors']) : null,
      fieldErrors: fieldErrors,
    );
  }
}

class ApiErrorData {
  final String? code;
  final String? details;
  final Map<String, dynamic>? rawErrors; // Store the raw errors for access if needed

  ApiErrorData({
    this.code, 
    this.details,
    this.rawErrors,
  });

  factory ApiErrorData.fromJson(Map<String, dynamic> json) {
    return ApiErrorData(
      code: json['code'],
      details: json['details'],
      rawErrors: json, // Store the entire errors object
    );
  }
}