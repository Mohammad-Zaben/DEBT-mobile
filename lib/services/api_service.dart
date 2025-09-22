import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'https://bumpy-papayas-nail.loca.lt';
  
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

  // Get public user info by ID (no authentication required)
  Future<ApiResponse<UserPublicInfo>> getUserPublicInfo(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/public'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }, // No auth token needed for public endpoint
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(UserPublicInfo.fromJson(data));
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في العثور على المستخدم');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Get my providers (for users)
  Future<ApiResponse<List<LinkedProvider>>> getMyProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/links/my-providers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final providers = data.map((json) => LinkedProvider.fromJson(json)).toList();
        return ApiResponse.success(providers);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب مزودي الخدمة');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Get my clients (for providers)
  Future<ApiResponse<List<LinkedClient>>> getMyClients() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/links/my-clients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final clients = data.map((json) => LinkedClient.fromJson(json)).toList();
        return ApiResponse.success(clients);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب العملاء');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Get transactions between user and provider
  Future<ApiResponse<List<Transaction>>> getTransactionsPair(int userId, int providerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/pair/$userId/$providerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final transactions = data.map((json) => Transaction.fromJson(json)).toList();
        return ApiResponse.success(transactions);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب المعاملات');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Get balance between user and provider
  Future<ApiResponse<BalanceSummary>> getBalance(int userId, int providerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/balance/$userId/$providerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(BalanceSummary.fromJson(data));
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب الرصيد');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Create transaction (for providers)
  Future<ApiResponse<Transaction>> createTransaction({
    required int userId,
    required String type, // 'debt' or 'payment'
    required String amount,
    String? otp,
  }) async {
    try {
      final body = {
        'user_id': userId,
        'type': type,
        'amount': amount,
      };
      
      if (otp != null) {
        body['otp'] = otp;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/transactions/'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(Transaction.fromJson(data));
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في إنشاء المعاملة');
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

  // Link provider to client
  Future<ApiResponse<UserProviderLink>> linkToClient(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/links/link'),
        headers: _headers,
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(UserProviderLink.fromJson(data));
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في ربط العميل');
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