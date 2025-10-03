import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://99e221185e21.ngrok-free.app';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storage = StorageService();
  
  String? _token;
  bool _isInitialized = false;
  bool _isConnected = true;

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

  // Simple connectivity check
  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      
      _isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  // Initialize token from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _storage.initialize();
    _token = _storage.getAuthToken();
    _isInitialized = true;
  }

  // Save token to storage
  Future<void> _saveToken(String token) async {
    _token = token;
    await _storage.saveAuthToken(token);
  }

  // Clear token from storage
  Future<void> clearToken() async {
    _token = null;
    await _storage.clearAuthToken();
    await _storage.clearAllCache();
  }

  // Check if user is logged in
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // Validate current token - works offline with cached data
  Future<bool> validateToken() async {
    if (!isLoggedIn) return false;
    
    // Try to get cached user first (offline support)
    final cachedUser = _storage.getCachedUser();
    if (cachedUser != null) {
      // If we have cached user data, consider token valid for offline use
      return true;
    }
    
    // If no cached data, check connectivity and try to validate online
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      // No internet and no cached data - token is invalid
      return false;
    }
    
    try {
      final response = await getCurrentUser();
      return response.success;
    } catch (e) {
      // Network error - if we had cached data, we'd return true above
      await clearToken();
      return false;
    }
  }

  // Enhanced login with caching
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    // Check connectivity
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت. يرجى المحاولة لاحقاً');
    }

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
        
        // Extract and cache user data
        final userData = data['user'];
        final user = User.fromJson(userData);
        await _storage.cacheUser(user);
        
        return ApiResponse.success(user);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في تسجيل الدخول');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Logout
  Future<void> logout() async {
    await clearToken();
  }

  // Register User
  Future<ApiResponse<User>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت. يرجى المحاولة لاحقاً');
    }

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
        final user = User.fromJson(data);
        return ApiResponse.success(user);
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
    required String providerType,
  }) async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('لا يوجد اتصال بالإنترنت. يرجى المحاولة لاحقاً');
    }

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
        final user = User.fromJson(data);
        return ApiResponse.success(user);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في إنشاء حساب المزود');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Enhanced getCurrentUser with offline support
  Future<ApiResponse<User>> getCurrentUser() async {
    // First try to get cached user data
    final cachedUser = _storage.getCachedUser();
    
    // Check connectivity
    final hasConnection = await _checkConnectivity();
    
    if (!hasConnection) {
      // Offline mode - return cached data if available
      if (cachedUser != null) {
        return ApiResponse.success(cachedUser);
      } else {
        return ApiResponse.error('لا يوجد اتصال بالإنترنت وقاعدة البيانات فارغة');
      }
    }

    // Online mode - try to fetch fresh data
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data);
        
        // Cache the fresh data
        await _storage.cacheUser(user);
        
        return ApiResponse.success(user);
      } else {
        // If unauthorized, clear token
        if (response.statusCode == 401) {
          await clearToken();
        }
        
        // If we have cached data, return it as fallback
        if (cachedUser != null) {
          return ApiResponse.success(cachedUser);
        }
        
        return ApiResponse.error('خطأ في جلب بيانات المستخدم');
      }
    } catch (e) {
      // Network error - return cached data if available
      if (cachedUser != null) {
        return ApiResponse.success(cachedUser);
      }
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Get public user info by ID (no authentication required)
  Future<ApiResponse<UserPublicInfo>> getUserPublicInfo(int userId) async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('يتطلب هذا الإجراء اتصال بالإنترنت');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/public'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userInfo = UserPublicInfo.fromJson(data);
        return ApiResponse.success(userInfo);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في العثور على المستخدم');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Enhanced getMyProviders with caching
  Future<ApiResponse<List<LinkedProvider>>> getMyProviders() async {
    final cachedProviders = _storage.getCachedProviders();
    final hasConnection = await _checkConnectivity();
    
    if (!hasConnection) {
      if (cachedProviders != null) {
        return ApiResponse.success(cachedProviders);
      } else {
        return ApiResponse.error('لا يوجد اتصال بالإنترنت وقاعدة البيانات فارغة');
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/links/my-providers'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<LinkedProvider> providers = data.map((json) => LinkedProvider.fromJson(json)).toList();
        
        await _storage.cacheProviders(providers);
        return ApiResponse.success(providers);
      } else {
        if (cachedProviders != null) {
          return ApiResponse.success(cachedProviders);
        }
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب مزودي الخدمة');
      }
    } catch (e) {
      if (cachedProviders != null) {
        return ApiResponse.success(cachedProviders);
      }
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Enhanced getMyClients with caching
  Future<ApiResponse<List<LinkedClient>>> getMyClients() async {
    final cachedClients = _storage.getCachedClients();
    final hasConnection = await _checkConnectivity();
    
    if (!hasConnection) {
      if (cachedClients != null) {
        return ApiResponse.success(cachedClients);
      } else {
        return ApiResponse.error('لا يوجد اتصال بالإنترنت وقاعدة البيانات فارغة');
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/links/my-clients'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<LinkedClient> clients = data.map((json) => LinkedClient.fromJson(json)).toList();
        
        await _storage.cacheClients(clients);
        return ApiResponse.success(clients);
      } else {
        if (cachedClients != null) {
          return ApiResponse.success(cachedClients);
        }
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب العملاء');
      }
    } catch (e) {
      if (cachedClients != null) {
        return ApiResponse.success(cachedClients);
      }
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Enhanced getTransactionsPair with caching
  Future<ApiResponse<List<Transaction>>> getTransactionsPair(int userId, int providerId) async {
    final cacheKey = '${userId}_$providerId';
    final cachedTransactions = _storage.getCachedTransactions(cacheKey);
    final hasConnection = await _checkConnectivity();
    
    if (!hasConnection) {
      if (cachedTransactions != null) {
        return ApiResponse.success(cachedTransactions);
      } else {
        return ApiResponse.error('لا يوجد اتصال بالإنترنت وقاعدة البيانات فارغة');
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/pair/$userId/$providerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Transaction> transactions = data.map((json) => Transaction.fromJson(json)).toList();
        
        await _storage.cacheTransactions(cacheKey, transactions);
        return ApiResponse.success(transactions);
      } else {
        if (cachedTransactions != null) {
          return ApiResponse.success(cachedTransactions);
        }
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب المعاملات');
      }
    } catch (e) {
      if (cachedTransactions != null) {
        return ApiResponse.success(cachedTransactions);
      }
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Enhanced getBalance with caching
  Future<ApiResponse<BalanceSummary>> getBalance(int userId, int providerId) async {
    final cacheKey = '${userId}_$providerId';
    final cachedBalance = _storage.getCachedBalance(cacheKey);
    final hasConnection = await _checkConnectivity();
    
    if (!hasConnection) {
      if (cachedBalance != null) {
        return ApiResponse.success(cachedBalance);
      } else {
        return ApiResponse.error('لا يوجد اتصال بالإنترنت وقاعدة البيانات فارغة');
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/balance/$userId/$providerId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balance = BalanceSummary.fromJson(data);
        
        await _storage.cacheBalance(cacheKey, balance);
        return ApiResponse.success(balance);
      } else {
        if (cachedBalance != null) {
          return ApiResponse.success(cachedBalance);
        }
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب الرصيد');
      }
    } catch (e) {
      if (cachedBalance != null) {
        return ApiResponse.success(cachedBalance);
      }
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Create transaction (requires internet)
  Future<ApiResponse<Transaction>> createTransaction({
    required int userId,
    required String type,
    required String amount,
    String? otp,
  }) async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('يتطلب إنشاء المعاملات اتصال بالإنترنت');
    }

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
        final transaction = Transaction.fromJson(data);
        return ApiResponse.success(transaction);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في إنشاء المعاملة');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Initialize OTP (requires internet)
  Future<ApiResponse<String>> initOtp() async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('يتطلب تهيئة OTP اتصال بالإنترنت');
    }

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

  // Link provider to client (requires internet)
  Future<ApiResponse<UserProviderLink>> linkToClient(int userId) async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('يتطلب ربط العملاء اتصال بالإنترنت');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/links/link'),
        headers: _headers,
        body: jsonEncode({'user_id': userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final link = UserProviderLink.fromJson(data);
        return ApiResponse.success(link);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في ربط العميل');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Enhanced getUserInvitations with caching
  Future<ApiResponse<List<UserProviderInvitation>>> getUserInvitations() async {
    final cachedInvitations = _storage.getCachedInvitations();
    final hasConnection = await _checkConnectivity();
    
    if (!hasConnection) {
      if (cachedInvitations != null) {
        return ApiResponse.success(cachedInvitations);
      } else {
        return ApiResponse.error('لا يوجد اتصال بالإنترنت وقاعدة البيانات فارغة');
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/links/invitations'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<UserProviderInvitation> invitations = data.map((json) => UserProviderInvitation.fromJson(json)).toList();
        
        await _storage.cacheInvitations(invitations);
        return ApiResponse.success(invitations);
      } else {
        if (cachedInvitations != null) {
          return ApiResponse.success(cachedInvitations);
        }
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في جلب الدعوات');
      }
    } catch (e) {
      if (cachedInvitations != null) {
        return ApiResponse.success(cachedInvitations);
      }
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Update invitation status (requires internet)
  Future<ApiResponse<UserProviderLink>> updateInvitationStatus(int invitationId, LinkStatus status) async {
    final hasConnection = await _checkConnectivity();
    if (!hasConnection) {
      return ApiResponse.error('يتطلب تحديث حالة الدعوة اتصال بالإنترنت');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/links/invitations/$invitationId/status'),
        headers: _headers,
        body: jsonEncode({
          'status': status.toString().split('.').last,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final link = UserProviderLink.fromJson(data);
        return ApiResponse.success(link);
      } else {
        final error = jsonDecode(response.body);
        return ApiResponse.error(error['detail'] ?? 'خطأ في تحديث حالة الدعوة');
      }
    } catch (e) {
      return ApiResponse.error('خطأ في الاتصال بالخادم');
    }
  }

  // Check if data should be refreshed
  bool shouldRefreshData() {
    return _storage.isDataStale();
  }

  // Force sync when connection is available
  Future<void> syncWhenOnline() async {
    final hasConnection = await _checkConnectivity();
    if (hasConnection && isLoggedIn) {
      // Refresh user data
      await getCurrentUser();
      
      // Get current user to determine what to sync
      final user = _storage.getCachedUser();
      if (user != null) {
        if (user.isUser) {
          // Sync user-specific data
          await getMyProviders();
          await getUserInvitations();
        } else if (user.isProvider) {
          // Sync provider-specific data
          await getMyClients();
        }
      }
    }
  }

  // Get connectivity status
  bool get isConnected => _isConnected;
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