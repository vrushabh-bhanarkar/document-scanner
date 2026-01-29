class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success({
    required String message,
    required T data,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: 200,
    );
  }

  factory ApiResponse.error({
    required String message,
    String? error,
    int? statusCode,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode ?? 500,
    );
  }

  @override
  String toString() =>
      'ApiResponse(success: $success, message: $message, statusCode: $statusCode)';
}
