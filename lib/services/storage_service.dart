import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _userKey = 'cached_user';
  static const String _authTokenKey = 'auth_token';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _transactionsKey = 'cached_transactions';
  static const String _providersKey = 'cached_providers';
  static const String _clientsKey = 'cached_clients';
  static const String _balancesKey = 'cached_balances';
  static const String _invitationsKey = 'cached_invitations';
  
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Auth Token Management
  Future<void> saveAuthToken(String token) async {
    await initialize();
    await _prefs!.setString(_authTokenKey, token);
  }

  String? getAuthToken() {
    return _prefs?.getString(_authTokenKey);
  }

  Future<void> clearAuthToken() async {
    await initialize();
    await _prefs!.remove(_authTokenKey);
  }

  // User Data Caching
  Future<void> cacheUser(User user) async {
    await initialize();
    final userJson = jsonEncode(user.toJson());
    await _prefs!.setString(_userKey, userJson);
    await _updateLastSync();
  }

  User? getCachedUser() {
    final userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        return User.fromJson(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Transaction Caching
  Future<void> cacheTransactions(String key, List<Transaction> transactions) async {
    await initialize();
    final transactionsJson = jsonEncode(
      transactions.map((t) => t.toJson()).toList()
    );
    await _prefs!.setString('${_transactionsKey}_$key', transactionsJson);
  }

  List<Transaction>? getCachedTransactions(String key) {
    final transactionsJson = _prefs?.getString('${_transactionsKey}_$key');
    if (transactionsJson != null) {
      try {
        final List<dynamic> data = jsonDecode(transactionsJson);
        return data.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Providers Caching
  Future<void> cacheProviders(List<LinkedProvider> providers) async {
    await initialize();
    final providersJson = jsonEncode(
      providers.map((p) => p.toJson()).toList()
    );
    await _prefs!.setString(_providersKey, providersJson);
  }

  List<LinkedProvider>? getCachedProviders() {
    final providersJson = _prefs?.getString(_providersKey);
    if (providersJson != null) {
      try {
        final List<dynamic> data = jsonDecode(providersJson);
        return data.map((json) => LinkedProvider.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Clients Caching
  Future<void> cacheClients(List<LinkedClient> clients) async {
    await initialize();
    final clientsJson = jsonEncode(
      clients.map((c) => c.toJson()).toList()
    );
    await _prefs!.setString(_clientsKey, clientsJson);
  }

  List<LinkedClient>? getCachedClients() {
    final clientsJson = _prefs?.getString(_clientsKey);
    if (clientsJson != null) {
      try {
        final List<dynamic> data = jsonDecode(clientsJson);
        return data.map((json) => LinkedClient.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Balance Caching
  Future<void> cacheBalance(String key, BalanceSummary balance) async {
    await initialize();
    final balanceJson = jsonEncode(balance.toJson());
    await _prefs!.setString('${_balancesKey}_$key', balanceJson);
  }

  BalanceSummary? getCachedBalance(String key) {
    final balanceJson = _prefs?.getString('${_balancesKey}_$key');
    if (balanceJson != null) {
      try {
        final data = jsonDecode(balanceJson);
        return BalanceSummary.fromJson(data as Map<String, dynamic>);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Invitations Caching
  Future<void> cacheInvitations(List<UserProviderInvitation> invitations) async {
    await initialize();
    final invitationsJson = jsonEncode(
      invitations.map((i) => i.toJson()).toList()
    );
    await _prefs!.setString(_invitationsKey, invitationsJson);
  }

  List<UserProviderInvitation>? getCachedInvitations() {
    final invitationsJson = _prefs?.getString(_invitationsKey);
    if (invitationsJson != null) {
      try {
        final List<dynamic> data = jsonDecode(invitationsJson);
        return data.map((json) => UserProviderInvitation.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Sync Management
  Future<void> _updateLastSync() async {
    await _prefs!.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  DateTime? getLastSyncTime() {
    final timestamp = _prefs?.getInt(_lastSyncKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // Clear all cached data
  Future<void> clearAllCache() async {
    await initialize();
    final keys = _prefs!.getKeys().where((key) => 
      key.startsWith(_userKey) || 
      key.startsWith(_transactionsKey) ||
      key.startsWith(_providersKey) ||
      key.startsWith(_clientsKey) ||
      key.startsWith(_balancesKey) ||
      key.startsWith(_invitationsKey) ||
      key == _lastSyncKey
    ).toList();
    
    for (String key in keys) {
      await _prefs!.remove(key);
    }
  }

  // Check if data is stale (older than 24 hours)
  bool isDataStale() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inHours > 24;
  }
}