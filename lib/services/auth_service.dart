import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'supabase_service.dart';
import '../core/constants.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Session state
  bool _isAuthenticated = false;
  String? _currentUserId;
  String? _currentUserRole;
  Map<String, dynamic>? _currentUser;
  bool _isLoggingOut = false;
  bool _isInitialized = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggingOut => _isLoggingOut;
  bool get isInitialized => _isInitialized;

  /// Initialize authentication service - CRITICAL for proper app startup
  static Future<void> initialize() async {
    await _instance._loadSession();
    _instance._isInitialized = true;
  }

  /// Load session from storage - handles app restart behavior
  Future<void> _loadSession() async {
    try {
      final box = await Hive.openBox('auth_session');
      
      _currentUserId = box.get('user_id');
      _currentUserRole = box.get('user_role');
      final userData = box.get('user_data');
      final loginTimestamp = box.get('login_timestamp');
      
      if (_currentUserId != null && _currentUserRole != null) {
        // Check if session is still valid (not expired)
        if (loginTimestamp != null) {
          final loginTime = DateTime.fromMillisecondsSinceEpoch(loginTimestamp);
          final now = DateTime.now();
          final daysSinceLogin = now.difference(loginTime).inDays;
          
          // Session expires after 30 days of inactivity
          if (daysSinceLogin > 30) {
            await clearSession();
            return;
          }
        }
        
        _currentUser = userData != null ? Map<String, dynamic>.from(userData) : null;
        _isAuthenticated = true;
        
        // Verify session is still valid with database
        await _verifySession();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading session: $e');
      await clearSession();
    }
  }

  /// Verify current session is still valid
  Future<void> _verifySession() async {
    if (_currentUserId == null) return;
    
    try {
      final user = await SupabaseService.getUser(_currentUserId!);
      if (user == null) {
        // User no longer exists, clear session
        await clearSession();
      } else {
        // Update user data and refresh session timestamp
        _currentUser = user.toJson();
        await _saveSession();
      }
    } catch (e) {
      print('Session verification failed: $e');
      // Don't clear session on network errors, just continue
    }
  }

  /// Complete login flow - handles both new and existing users
  Future<LoginResult> completeLogin(String phone, String role, {String? otp, bool isNewUser = false}) async {
    try {
      if (isNewUser && otp != null) {
        // New user - verify OTP first
        final response = await SupabaseService.verifyOTP(phone, otp);
        if (response.user == null) {
          return LoginResult.failure('Invalid OTP');
        }
      }
      
      // Check if user exists
      final userData = await SupabaseService.getUserByPhone(phone);
      
      if (userData == null) {
        if (isNewUser) {
          // Create new user account
          final newUserId = await SupabaseService.createBasicUser(phone, role);
          return LoginResult.needsKyc(newUserId, phone, role);
        } else {
          return LoginResult.failure('Account not found. Please sign up first.');
        }
      }
      
      // Existing user found
      final userRole = userData['role'] as String;
      final isKycDone = userData['is_kyc_done'] as bool? ?? false;
      
      if (userRole != role) {
        return LoginResult.failure('This number is registered as a $userRole. Please use the correct login.');
      }
      
      if (!isKycDone) {
        return LoginResult.needsKyc(userData['id'], phone, userRole);
      }
      
      // Complete login - set session
      await _setSession(userData['id'], userRole, userData);
      
      return LoginResult.success(await getPostLoginRoute());
      
    } catch (e) {
      print('Login error: $e');
      return LoginResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Set authenticated session
  Future<void> _setSession(String userId, String role, Map<String, dynamic> userData) async {
    _currentUserId = userId;
    _currentUserRole = role;
    _currentUser = userData;
    _isAuthenticated = true;
    
    // Set demo user ID for SupabaseService
    await SupabaseService.setDemoUserId(userId);
    
    // Save session
    await _saveSession();
    notifyListeners();
  }

  /// Save session to storage with timestamp
  Future<void> _saveSession() async {
    try {
      final box = await Hive.openBox('auth_session');
      
      await box.put('user_id', _currentUserId);
      await box.put('user_role', _currentUserRole);
      await box.put('user_data', _currentUser);
      await box.put('login_timestamp', DateTime.now().millisecondsSinceEpoch);
      
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  /// Professional logout with proper cleanup
  Future<void> logout({BuildContext? context}) async {
    if (_isLoggingOut) return; // Prevent multiple logout calls
    
    _isLoggingOut = true;
    notifyListeners();
    
    try {
      // Sign out from Supabase
      await SupabaseService.signOut();
      
      // Clear local session
      await clearSession();
      
      // Navigate to role select and clear history
      if (context != null && context.mounted) {
        context.go(AppRoutes.roleSelect);
      }
      
    } catch (e) {
      print('Logout error: $e');
      // Still clear local session even if Supabase logout fails
      await clearSession();
      
      if (context != null && context.mounted) {
        context.go(AppRoutes.roleSelect);
      }
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  /// Clear session data
  Future<void> clearSession() async {
    try {
      final box = await Hive.openBox('auth_session');
      await box.clear();
      
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserRole = null;
      _currentUser = null;
      
      notifyListeners();
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  /// Get redirect route based on user role
  String getHomeRoute() {
    switch (_currentUserRole) {
      case 'farmer':
        return AppRoutes.farmerHome;
      case 'customer':
        return AppRoutes.customerHome;
      case 'admin':
        return AppRoutes.adminDashboard;
      default:
        return AppRoutes.roleSelect;
    }
  }

  /// Navigate to appropriate screen after login
  Future<String> getPostLoginRoute() async {
    if (!_isAuthenticated) return AppRoutes.roleSelect;
    
    // Check if user needs verification
    final needsVerify = await needsVerification();
    if (needsVerify) {
      return '/verification-flow';
    }
    
    // Navigate to role-specific home
    return getHomeRoute();
  }

  /// Check if user needs verification
  Future<bool> needsVerification() async {
    if (_currentUserId == null) return false;
    
    try {
      // Check verification status from database
      final verificationStatus = await SupabaseService.getUserVerificationStatus(_currentUserId!);
      
      // If any verification is pending or missing, user needs verification
      return verificationStatus.values.any((status) => 
        status == 'pending' || status == 'rejected' || status == null
      );
    } catch (e) {
      print('Error checking verification status: $e');
      return false; // Don't block user if verification check fails
    }
  }

  /// Check if user has specific role
  bool hasRole(String role) => _currentUserRole == role;

  /// Role getters
  bool get isAdmin => hasRole('admin');
  bool get isFarmer => hasRole('farmer');
  bool get isCustomer => hasRole('customer');

  /// Force refresh user data
  Future<void> refreshUserData() async {
    if (_currentUserId != null) {
      try {
        final user = await SupabaseService.getUser(_currentUserId!);
        if (user != null) {
          _currentUser = user.toJson();
          await _saveSession();
          notifyListeners();
        }
      } catch (e) {
        print('Error refreshing user data: $e');
      }
    }
  }
}

/// Login result class for better error handling
class LoginResult {
  final bool success;
  final String? message;
  final String? route;
  final String? userId;
  final String? phone;
  final String? role;
  final bool needsKyc;

  LoginResult._({
    required this.success,
    this.message,
    this.route,
    this.userId,
    this.phone,
    this.role,
    this.needsKyc = false,
  });

  factory LoginResult.success(String route) => LoginResult._(
    success: true,
    route: route,
  );

  factory LoginResult.failure(String message) => LoginResult._(
    success: false,
    message: message,
  );

  factory LoginResult.needsKyc(String userId, String phone, String role) => LoginResult._(
    success: true,
    needsKyc: true,
    userId: userId,
    phone: phone,
    role: role,
  );
}