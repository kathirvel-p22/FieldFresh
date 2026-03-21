import 'dart:async';
import 'package:flutter/foundation.dart';
import 'advanced_session_service.dart';
import 'trust_service.dart';
import 'privacy_service.dart';
import 'verification_badge_service.dart';
import 'enhanced_admin_service.dart';
import 'supabase_service.dart';

/// Enterprise Service Manager
/// Coordinates all advanced enterprise services and provides a unified interface
class EnterpriseServiceManager {
  static final EnterpriseServiceManager _instance =
      EnterpriseServiceManager._internal();
  factory EnterpriseServiceManager() => _instance;
  EnterpriseServiceManager._internal();

  // Service instances
  late final AdvancedSessionService _sessionService;
  late final TrustService _trustService;
  late final PrivacyService _privacyService;
  late final VerificationBadgeService _badgeService;
  late final EnhancedAdminService _adminService;

  bool _isInitialized = false;
  final _initializationCompleter = Completer<void>();

  // Getters for services
  AdvancedSessionService get sessionService => _sessionService;
  TrustService get trustService => _trustService;
  PrivacyService get privacyService => _privacyService;
  VerificationBadgeService get badgeService => _badgeService;
  EnhancedAdminService get adminService => _adminService;

  /// Initialize all enterprise services
  Future<void> initialize() async {
    if (_isInitialized) {
      return _initializationCompleter.future;
    }

    try {
      debugPrint('🚀 Initializing Enterprise Services...');

      // Initialize services
      _sessionService = AdvancedSessionService();
      _trustService = TrustService();
      _privacyService = PrivacyService();
      _badgeService = VerificationBadgeService();
      _adminService = EnhancedAdminService();

      // Initialize session service first (handles authentication)
      final autoLoginSuccess = await _sessionService.initialize();
      debugPrint(
          '📱 Session Service initialized - Auto-login: $autoLoginSuccess');

      // Initialize badge service (starts periodic evaluation)
      _badgeService.initialize();
      debugPrint('🏆 Badge Service initialized');

      // Set up cross-service integrations
      await _setupServiceIntegrations();

      _isInitialized = true;
      _initializationCompleter.complete();

      debugPrint('✅ All Enterprise Services initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Enterprise Services: $e');
      _initializationCompleter.completeError(e);
      rethrow;
    }
  }

  /// Set up integrations between services
  Future<void> _setupServiceIntegrations() async {
    try {
      // Listen to session changes and update user activity
      _sessionService.sessionStateStream.listen((state) {
        if (state == SessionState.authenticated) {
          _onUserAuthenticated();
        }
      });

      // Listen to trust score updates and award badges
      _trustService.trustScoreStream.listen((trustScore) {
        _onTrustScoreUpdated(trustScore);
      });

      debugPrint('🔗 Service integrations set up');
    } catch (e) {
      debugPrint('Failed to set up service integrations: $e');
    }
  }

  /// Handle user authentication
  Future<void> _onUserAuthenticated() async {
    try {
      final session = _sessionService.currentSession;
      if (session == null) return;

      // Log authentication activity
      await _badgeService.updateUserActivity(
        session.userId,
        'user_login',
        {
          'timestamp': DateTime.now().toIso8601String(),
          'role': session.role,
        },
      );

      // Auto-verify phone if not already verified
      final user =
          await SupabaseService.getUser(_sessionService.currentSession!.userId);
      if (user != null) {
        await _trustService.autoVerifyPhone(session.userId, user.phone);
      }

      // Auto-verify profile if complete
      if (user != null) {
        await _trustService.autoVerifyProfile(session.userId, user.toJson());
      }

      debugPrint('👤 User authenticated and verifications updated');
    } catch (e) {
      debugPrint('Failed to handle user authentication: $e');
    }
  }

  /// Handle trust score updates
  Future<void> _onTrustScoreUpdated(TrustScore trustScore) async {
    try {
      // Award badges based on trust score milestones
      if (trustScore.score >= 90) {
        await _badgeService.awardBadge(
          trustScore.userId,
          BadgeType.topRated,
          {'trust_score': trustScore.score},
        );
      }

      debugPrint('📊 Trust score updated: ${trustScore.displayText}');
    } catch (e) {
      debugPrint('Failed to handle trust score update: $e');
    }
  }

  /// Get current user ID
  String? get currentUserId => _sessionService.currentSession?.userId;

  /// Get filtered user profile
  Future<FilteredUserProfile> getFilteredUserProfile(
    String userId,
    PaymentStatus paymentStatus, {
    String? requesterId,
  }) async {
    return await _privacyService.getFilteredProfile(
      userId,
      paymentStatus,
      requesterId: requesterId,
    );
  }

  /// Get user trust score
  Future<TrustScore> getUserTrustScore(String userId) async {
    return await _trustService.calculateTrustScore(userId);
  }

  /// Get user badges
  Future<List<VerificationBadge>> getUserBadges(String userId) async {
    return await _badgeService.getUserBadges(userId);
  }

  Future<Map<String, dynamic>> getEnterpriseUserProfile(String userId,
      {PaymentStatus paymentStatus = PaymentStatus.none}) async {
    try {
      // Get filtered profile based on privacy settings
      final filteredProfile = await _privacyService.getFilteredProfile(
        userId,
        paymentStatus,
      );

      // Get trust score
      final trustScore = await _trustService.calculateTrustScore(userId);

      // Get verification badges
      final badges = await _badgeService.getUserBadges(userId);

      // Get completed verifications
      final verifications =
          await _trustService.getCompletedVerifications(userId);

      return {
        'profile': filteredProfile.visibleData,
        'trust_score': trustScore.toJson(),
        'badges': badges.map((b) => b.toJson()).toList(),
        'verifications': verifications.map((v) => v.name).toList(),
        'disclosure_level': filteredProfile.appliedLevel.name,
        'upgrade_message': filteredProfile.upgradeMessage,
      };
    } catch (e) {
      debugPrint('Failed to get enterprise user profile: $e');
      rethrow;
    }
  }

  /// Handle payment status change and update privacy
  Future<void> handlePaymentStatusChange(
    String customerId,
    String farmerId,
    String orderId,
    PaymentStatus oldStatus,
    PaymentStatus newStatus,
  ) async {
    try {
      // Update privacy disclosure
      await _privacyService.handlePaymentStatusChange(
        customerId,
        farmerId,
        orderId,
        oldStatus,
        newStatus,
      );

      // Update farmer reputation if order is completed
      if (newStatus == PaymentStatus.confirmed) {
        await _trustService.updateReputation(farmerId);
      }

      debugPrint('💳 Payment status updated: $oldStatus -> $newStatus');
    } catch (e) {
      debugPrint('Failed to handle payment status change: $e');
    }
  }

  /// Submit farm verification request
  Future<void> submitFarmVerification(
    String userId,
    double latitude,
    double longitude,
    List<String> farmImageUrls,
    List<String> cropTypes,
  ) async {
    try {
      await _trustService.submitFarmVerification(
        userId,
        latitude,
        longitude,
        farmImageUrls,
        cropTypes,
      );

      // Log activity
      await _badgeService.updateUserActivity(
        userId,
        'farm_verification_submitted',
        {
          'latitude': latitude,
          'longitude': longitude,
          'images_count': farmImageUrls.length,
          'crop_types': cropTypes,
        },
      );

      debugPrint('🚜 Farm verification submitted');
    } catch (e) {
      debugPrint('Failed to submit farm verification: $e');
      rethrow;
    }
  }

  /// Award verification badge (admin action)
  Future<void> awardVerificationBadge(
    String userId,
    BadgeType badgeType,
    String reason,
  ) async {
    try {
      final adminId = _sessionService.currentSession?.userId;
      if (adminId == null) {
        throw Exception('Admin not authenticated');
      }

      await _badgeService.awardBadge(
        userId,
        badgeType,
        {
          'awarded_by': adminId,
          'reason': reason,
          'awarded_at': DateTime.now().toIso8601String(),
        },
      );

      // Log admin action
      await _adminService.approveUser(
          userId, 'Badge awarded: ${badgeType.name}');

      debugPrint('🏆 Badge awarded: ${badgeType.name}');
    } catch (e) {
      debugPrint('Failed to award verification badge: $e');
      rethrow;
    }
  }

  /// Get admin dashboard data
  Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      // Get platform stats
      final stats = await _adminService.getPlatformStats();

      // Get pending verifications
      final pendingVerifications =
          await _trustService.getPendingVerifications();

      // Get flagged users
      final flaggedUsers = await _adminService.getFlaggedUsers();

      // Get admin alerts
      final alerts = await _adminService.getAdminAlerts(limit: 20);

      return {
        'stats': stats,
        'pending_verifications':
            pendingVerifications.map((v) => v.toJson()).toList(),
        'flagged_users': flaggedUsers,
        'alerts': alerts
            .map((a) => {
                  'id': a.id,
                  'type': a.type,
                  'title': a.title,
                  'message': a.message,
                  'priority': a.priority,
                  'isRead': a.isRead,
                  'createdAt': a.createdAt.toIso8601String(),
                })
            .toList(),
      };
    } catch (e) {
      debugPrint('Failed to get admin dashboard data: $e');
      rethrow;
    }
  }

  /// Perform fraud analysis on user
  Future<FraudScore> performFraudAnalysis(String userId) async {
    try {
      final fraudScore = await _adminService.analyzeFraudRisk(userId);

      // If high risk, automatically flag the user
      if (fraudScore.riskLevel == 'high') {
        await _adminService.flagUser(
          userId,
          'High fraud risk detected: ${fraudScore.reasons.join(', ')}',
          riskScore: fraudScore.riskScore,
        );
      }

      return fraudScore;
    } catch (e) {
      debugPrint('Failed to perform fraud analysis: $e');
      rethrow;
    }
  }

  /// Update user activity (called from UI interactions)
  Future<void> updateUserActivity(String activityType,
      [Map<String, dynamic>? data]) async {
    try {
      final session = _sessionService.currentSession;
      if (session == null) return;

      await _badgeService.updateUserActivity(
        session.userId,
        activityType,
        data ?? {},
      );

      // Update session activity
      await _sessionService.updateActivity();
    } catch (e) {
      debugPrint('Failed to update user activity: $e');
    }
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    try {
      final session = _sessionService.currentSession;
      if (session == null) return false;

      // Admin has all permissions
      if (session.role == 'admin') return true;

      // Define role-based permissions
      final permissions = {
        'farmer': ['post_products', 'manage_orders', 'view_analytics'],
        'customer': ['place_orders', 'view_farmers', 'leave_reviews'],
      };

      return permissions[session.role]?.contains(permission) ?? false;
    } catch (e) {
      debugPrint('Failed to check permission: $e');
      return false;
    }
  }

  /// Get user's current trust level
  Future<String> getUserTrustLevel(String userId) async {
    try {
      final trustScore = await _trustService.calculateTrustScore(userId);
      return trustScore.trustLevel;
    } catch (e) {
      debugPrint('Failed to get user trust level: $e');
      return 'Building Trust';
    }
  }

  /// Get admin stats
  Future<AdminStats> getAdminStats() async {
    return await _adminService.getPlatformStats();
  }

  /// Get flagged users
  Future<List<Map<String, dynamic>>> getFlaggedUsers() async {
    return await _adminService.getFlaggedUsers();
  }

  /// Approve user
  Future<void> approveUser(String userId, String reason) async {
    return await _adminService.approveUser(userId, reason);
  }

  /// Suspend user
  Future<void> suspendUser(
      String userId, Duration duration, String reason) async {
    return await _adminService.suspendUser(userId, duration, reason);
  }

  /// Clear all caches (useful for logout or data refresh)
  void clearAllCaches() {
    _trustService.clearAllCache();
    _privacyService.clearAllCache();
    _badgeService.clearAllCache();
    debugPrint('🧹 All caches cleared');
  }

  /// Dispose all services
  void dispose() {
    _sessionService.dispose();
    _trustService.dispose();
    _badgeService.dispose();
    _adminService.dispose();
    debugPrint('🛑 Enterprise Services disposed');
  }
}
