import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';

class ApiClient {
  static const String baseUrl = 'https://demohrm.n2nhostings.com/api';
  
  final String? _token;
  final http.Client _httpClient;

  ApiClient({String? token, http.Client? httpClient})
      : _token = token,
        _httpClient = httpClient ?? http.Client();

  // Set or update token
  void setToken(String token) {
    // Note: In a real app, you'd store this in a variable
    // For now, we'll use it as constructor parameter
  }

  // Build headers
  Map<String, String> _getHeaders({
    bool includeAuth = true,
    String? overrideContentType,
  }) {
    final headers = <String, String>{
      'Content-Type': overrideContentType ?? 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // GET Request
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    required T Function(dynamic) fromJson,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient.get(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error',
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  // POST Request
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    required dynamic body,
    required T Function(dynamic) fromJson,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient.post(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error',
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  // PUT Request
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    required dynamic body,
    required T Function(dynamic) fromJson,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient.put(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error',
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  // DELETE Request
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    required T Function(dynamic) fromJson,
    bool includeAuth = true,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await _httpClient.delete(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
      );

      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse.error(
        message: 'Network error',
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  // Handle Response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) {
    try {
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response
        final data = fromJson(jsonResponse['data'] ?? jsonResponse);
        return ApiResponse.success(
          message: jsonResponse['message'] ?? 'Success',
          data: data,
        );
      } else if (response.statusCode == 401) {
        return ApiResponse.error(
          message: 'Unauthorized',
          error: jsonResponse['message'] ?? 'Authentication failed',
          statusCode: 401,
        );
      } else if (response.statusCode == 422) {
        // Validation error
        final errors = jsonResponse['errors'] ?? {};
        final errorMessage = errors.entries.isNotEmpty
            ? errors.entries.first.value.first
            : jsonResponse['message'] ?? 'Validation error';
        return ApiResponse.error(
          message: errorMessage,
          error: jsonEncode(errors),
          statusCode: 422,
        );
      } else {
        return ApiResponse.error(
          message: jsonResponse['message'] ?? 'An error occurred',
          error: response.body,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        message: 'Error parsing response',
        error: e.toString(),
        statusCode: response.statusCode,
      );
    }
  }
}
