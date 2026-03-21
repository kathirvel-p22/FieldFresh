import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'supabase_service.dart';

enum SessionState {
  unauthenticated,
  authenticated,
  loading,
  error,
}

class SessionData {
  final String userId;
  final String role;
  final DateTime lastActivity;
  final bool isActive;

  SessionData({
    required this.userId,
    required this.role,
    required this.lastActivity,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'role': role,
    'lastActivity': lastActivity.toIso8601String(),
    'isActive': isActive,
  };

  factory SessionData.fromJson(Map<String, dynamic> json) => SessionData(
    userId: json['userId'],
    role: json['role'],
    lastActivity: DateTime.parse(json['lastActivity']),
    isActive: json['isActive'],
  );
}

class AdvancedSessionService {
  static final AdvancedSessionService _instance = AdvancedSessionService._internal();
  factory AdvancedSessionService() => _instance;
  AdvancedSessionService._internal();

  static const String _tokenKey = 'secure_auth_token';
  static const String _deviceIdKey = 'device_identifier';
  static const String _sessionDataKey = 'session_data';
  static const Duration _tokenLifetime = Duration(hours: 24);
  static const Duration _sessionPersistence = Duration(days: 30);

  final SupabaseClient _supabase = Supabase.instance.client;
  final _sessionStateController = StreamController<SessionState>.broadcast();
  final _sessionDataController = StreamController<SessionData?>.broadcast();

  SessionState _currentState = SessionState.unauthenticated;
  SessionData? _currentSession;
  Timer? _tokenRotationTimer;
  Timer? _activityTimer;

  Stream<SessionState> get sessionStateStream => _sessionStateController.stream;
  Stream<SessionData?> get sessionDataStream => _sessionDataController.stream;
  SessionState get currentState => _currentState;
  SessionData? get currentSession => _currentSession;

  /// Initialize the session service and attempt auto-login
  Future<bool> initialize() async {
    try {
      _setState(SessionState.loading);
      
      final autoLoginSuccess = await _attemptAutoLogin();
      
      if (autoLoginSuccess) {
        _startTokenRotationTimer();
        _startActivityTimer();
        return true;
      } else {
        _setState(SessionState.unauthenticated);
        return false;
      }
    } catch (e) {
      print('Session initialization failed: $e');
      _setState(SessionState.error);
      return false;
    }
  }

  /// Attempt automatic login using stored credentials
  Future<bool> _attemptAutoLogin() async {
    try {
      final storedToken = await _getStoredToken();
      final deviceId = await _getOrCreateDeviceId();
      
      if (storedToken == null) {
        return false;
      }

      // Verify token with backend
      final tokenData = await _supabase
          .from('session_tokens')
          .select('user_id, expires_at, is_active, device_info')
          .eq('token_hash', _hashToken(storedToken))
          .eq('device_id', deviceId)
          .eq('is_active', true)
          .maybeSingle();

      if (tokenData == null) {
        await _clearStoredCredentials();
        return false;
      }

      final expiresAt = DateTime.parse(tokenData['expires_at']);
      if (expiresAt.isBefore(DateTime.now())) {
        await _invalidateToken(storedToken);
        return false;
      }

      // Get user data
      final userId = tokenData['user_id'] as String;
      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      // Update last used timestamp
      await _updateTokenUsage(storedToken);

      // Set session data
      _currentSession = SessionData(
        userId: userId,
        role: userData['role'],
        lastActivity: DateTime.now(),
        isActive: true,
      );

      // Set demo user ID for compatibility
      await SupabaseService.setDemoUserId(userId);

      _setState(SessionState.authenticated);
      _sessionDataController.add(_currentSession);

      return true;
    } catch (e) {
      print('Auto-login failed: $e');
      return false;
    }
  }

  /// Create a new session after successful authentication
  Future<void> createSession(String userId, String role) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final token = _generateSecureToken();

      // Store token securely
      await _storeSecureToken(token, deviceId);

      // Create session in database
      await _supabase.from('session_tokens').insert({
        'user_id': userId,
        'token_hash': _hashToken(token),
        'device_id': deviceId,
        'device_info': await _getDeviceInfo(),
        'expires_at': DateTime.now().add(_tokenLifetime).toIso8601String(),
        'is_active': true,
      });

      // Set session data
      _currentSession = SessionData(
        userId: userId,
        role: role,
        lastActivity: DateTime.now(),
        isActive: true,
      );

      // Store session data locally
      await _storeSessionData(_currentSession!);

      // Set demo user ID for compatibility
      await SupabaseService.setDemoUserId(userId);

      _setState(SessionState.authenticated);
      _sessionDataController.add(_currentSession);

      // Start timers
      _startTokenRotationTimer();
      _startActivityTimer();

    } catch (e) {
      print('Failed to create session: $e');
      _setState(SessionState.error);
      rethrow;
    }
  }

  /// Rotate authentication tokens
  Future<void> rotateTokens() async {
    try {
      if (_currentSession == null) return;

      final currentToken = await _getStoredToken();
      if (currentToken == null) return;

      final deviceId = await _getOrCreateDeviceId();
      final newToken = _generateSecureToken();

      // Invalidate old token
      await _invalidateToken(currentToken);

      // Store new token
      await _storeSecureToken(newToken, deviceId);

      // Create new session token in database
      await _supabase.from('session_tokens').insert({
        'user_id': _currentSession!.userId,
        'token_hash': _hashToken(newToken),
        'device_id': deviceId,
        'device_info': await _getDeviceInfo(),
        'expires_at': DateTime.now().add(_tokenLifetime).toIso8601String(),
        'is_active': true,
      });

      print('Token rotation completed successfully');
    } catch (e) {
      print('Token rotation failed: $e');
    }
  }

  /// Invalidate all sessions for a user
  Future<void> invalidateAllSessions(String userId) async {
    try {
      await _supabase
          .from('session_tokens')
          .update({'is_active': false})
          .eq('user_id', userId);

      if (_currentSession?.userId == userId) {
        await _clearStoredCredentials();
        _setState(SessionState.unauthenticated);
        _sessionDataController.add(null);
      }
    } catch (e) {
      print('Failed to invalidate sessions: $e');
    }
  }

  /// Secure logout
  Future<void> logout() async {
    try {
      final token = await _getStoredToken();
      if (token != null) {
        await _invalidateToken(token);
      }

      await _clearStoredCredentials();
      await SupabaseService.signOut();

      _currentSession = null;
      _setState(SessionState.unauthenticated);
      _sessionDataController.add(null);

      _stopTimers();
    } catch (e) {
      print('Logout failed: $e');
    }
  }

  /// Update user activity
  Future<void> updateActivity() async {
    if (_currentSession == null) return;

    try {
      _currentSession = SessionData(
        userId: _currentSession!.userId,
        role: _currentSession!.role,
        lastActivity: DateTime.now(),
        isActive: true,
      );

      await _storeSessionData(_currentSession!);
      _sessionDataController.add(_currentSession);

      // Log activity in database
      await _supabase.from('user_activity').insert({
        'user_id': _currentSession!.userId,
        'activity_type': 'app_interaction',
        'activity_data': {'timestamp': DateTime.now().toIso8601String()},
      });
    } catch (e) {
      print('Failed to update activity: $e');
    }
  }

  /// Check if session is valid
  bool isSessionValid() {
    if (_currentSession == null) return false;
    
    final timeSinceActivity = DateTime.now().difference(_currentSession!.lastActivity);
    return timeSinceActivity < _sessionPersistence;
  }

  /// Get user role for routing
  String? getUserRole() {
    return _currentSession?.role;
  }

  // Private helper methods

  void _setState(SessionState state) {
    _currentState = state;
    _sessionStateController.add(state);
  }

  Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedToken = prefs.getString(_tokenKey);
      if (encryptedToken == null) return null;
      
      return _decryptToken(encryptedToken);
    } catch (e) {
      return null;
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  Future<void> _storeSecureToken(String token, String deviceId) async {
    try {
      final encryptedToken = _encryptToken(token, deviceId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, encryptedToken);
    } catch (e) {
      print('Failed to store secure token: $e');
      rethrow;
    }
  }

  Future<void> _storeSessionData(SessionData sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionDataKey, jsonEncode(sessionData.toJson()));
    } catch (e) {
      print('Failed to store session data: $e');
    }
  }

  Future<void> _clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_sessionDataKey);
    } catch (e) {
      print('Failed to clear credentials: $e');
    }
  }

  String _generateSecureToken() {
    final bytes = List<int>.generate(32, (i) => Random.secure().nextInt(256));
    return base64Encode(bytes);
  }

  String _generateDeviceId() {
    final bytes = List<int>.generate(16, (i) => Random.secure().nextInt(256));
    return base64Encode(bytes);
  }

  String _hashToken(String token) {
    final bytes = utf8.encode(token);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _encryptToken(String token, String deviceId) {
    // Simple XOR encryption with device ID as key
    final tokenBytes = utf8.encode(token);
    final keyBytes = utf8.encode(deviceId);
    final encryptedBytes = <int>[];
    
    for (int i = 0; i < tokenBytes.length; i++) {
      encryptedBytes.add(tokenBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64Encode(encryptedBytes);
  }

  String _decryptToken(String encryptedToken) {
    try {
      final encryptedBytes = base64Decode(encryptedToken);
      // For now, return the token as-is (simplified decryption)
      return utf8.decode(encryptedBytes);
    } catch (e) {
      return '';
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browser': webInfo.browserName.name,
          'user_agent': webInfo.userAgent,
        };
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
        };
      }
      
      return {'platform': 'unknown'};
    } catch (e) {
      return {'platform': 'error', 'error': e.toString()};
    }
  }

  Future<void> _updateTokenUsage(String token) async {
    try {
      await _supabase
          .from('session_tokens')
          .update({'last_used': DateTime.now().toIso8601String()})
          .eq('token_hash', _hashToken(token));
    } catch (e) {
      print('Failed to update token usage: $e');
    }
  }

  Future<void> _invalidateToken(String token) async {
    try {
      await _supabase
          .from('session_tokens')
          .update({'is_active': false})
          .eq('token_hash', _hashToken(token));
    } catch (e) {
      print('Failed to invalidate token: $e');
    }
  }

  void _startTokenRotationTimer() {
    _tokenRotationTimer?.cancel();
    _tokenRotationTimer = Timer.periodic(
      const Duration(hours: 12), // Rotate every 12 hours
      (_) => rotateTokens(),
    );
  }

  void _startActivityTimer() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(
      const Duration(minutes: 5), // Update activity every 5 minutes
      (_) => updateActivity(),
    );
  }

  void _stopTimers() {
    _tokenRotationTimer?.cancel();
    _activityTimer?.cancel();
  }

  void dispose() {
    _stopTimers();
    _sessionStateController.close();
    _sessionDataController.close();
  }
}