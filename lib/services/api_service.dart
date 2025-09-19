import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'https://free-seas-shine.loca.lt';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  // Headers for requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Initialize token from storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to storage
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Clear token from storage
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if user is logged in
  bool get isLoggedIn => _token != null;

  // Login
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['access_token']);
        
        // Get user info after login
        final userResponse = await getCurrentUser();
        return userResponse;
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في تسجيل الدخول');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Register User
  Future<ApiResponse<User>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(User.fromJson(data));
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في إنشاء الحساب');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Create Provider (Admin only)
  Future<ApiResponse<User>> createProvider({
    required String name,
    required String email,
    required String password,
    required String providerType, // 'lender' or 'payer'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/provider'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'provider_type': providerType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(User.fromJson(data));
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في إنشاء حساب المزود');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Get current user info
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(User.fromJson(data));
      } else {
        return ApiResponse.error('خطأ في جلب بيانات المستخدم');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Initialize OTP
  Future<ApiResponse<String>> initOtp() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/init'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success('تم إرسال رمز التحقق');
      } else {
        return ApiResponse.error('خطأ في إرسال رمز التحقق');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }
}

// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse._({required this.success, this.data, this.error});

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(success: false, error: error);
  }
}

// User model
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? providerType;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.providerType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      providerType: json['provider_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUser => role == 'User';
  bool get isProvider => role == 'Provider';
  bool get isAdmin => role == 'Admin';
  bool get isLender => providerType == 'lender';
  bool get isPayer => providerType == 'payer';
}