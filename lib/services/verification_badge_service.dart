import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum BadgeType {
  liveFarmProof,     // Video/harvest clip uploads
  recentlyActive,    // Active within 5 minutes
  fastResponse,      // Responds to messages within 10 minutes
  deliverySuccess,   // 98%+ successful deliveries
  repeatBuyer,       // 80%+ customer reorder rate
  topRated,          // 4.5+ average rating
  verified,          // Admin verified
  newbie,            // New user (first 30 days)
  experienced,       // 1+ year on platform
  reliable,          // 95%+ order completion rate
}

class VerificationBadge {
  final String id;
  final String userId;
  final BadgeType type;
  final Map<String, dynamic> badgeData;
  final DateTime earnedAt;
  final DateTime? expiresAt;
  final bool isActive;

  VerificationBadge({
    required this.id,
    required this.userId,
    required this.type,
    required this.badgeData,
    required this.earnedAt,
    this.expiresAt,
    required this.isActive,
  });

  factory VerificationBadge.fromJson(Map<String, dynamic> json) {
    return VerificationBadge(
      id: json['id'],
      userId: json['user_id'],
      type: BadgeType.values.firstWhere(
        (t) => t.name == json['badge_type'],
      ),
      badgeData: json['badge_data'] ?? {},
      earnedAt: DateTime.parse(json['earned_at']),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_type': type.name,
      'badge_data': badgeData,
      'earned_at': earnedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  String get displayName {
    switch (type) {
      case BadgeType.liveFarmProof:
        return 'Live Farm Proof';
      case BadgeType.recentlyActive:
        return 'Recently Active';
      case BadgeType.fastResponse:
        return 'Fast Response';
      case BadgeType.deliverySuccess:
        return 'Delivery Expert';
      case BadgeType.repeatBuyer:
        return 'Customer Favorite';
      case BadgeType.topRated:
        return 'Top Rated';
      case BadgeType.verified:
        return 'Verified';
      case BadgeType.newbie:
        return 'New Member';
      case BadgeType.experienced:
        return 'Experienced';
      case BadgeType.reliable:
        return 'Reliable';
    }
  }

  String get description {
    switch (type) {
      case BadgeType.liveFarmProof:
        return 'Shares live farm videos and harvest updates';
      case BadgeType.recentlyActive:
        return 'Active within the last 5 minutes';
      case BadgeType.fastResponse:
        return 'Responds to messages within 10 minutes';
      case BadgeType.deliverySuccess:
        return '98%+ successful delivery rate';
      case BadgeType.repeatBuyer:
        return '80%+ customers reorder from this farmer';
      case BadgeType.topRated:
        return '4.5+ star average rating';
      case BadgeType.verified:
        return 'Verified by admin';
      case BadgeType.newbie:
        return 'New to the platform';
      case BadgeType.experienced:
        return '1+ year on the platform';
      case BadgeType.reliable:
        return '95%+ order completion rate';
    }
  }

  String get iconName {
    switch (type) {
      case BadgeType.liveFarmProof:
        return 'videocam';
      case BadgeType.recentlyActive:
        return 'radio_button_checked';
      case BadgeType.fastResponse:
        return 'flash_on';
      case BadgeType.deliverySuccess:
        return 'local_shipping';
      case BadgeType.repeatBuyer:
        return 'favorite';
      case BadgeType.topRated:
        return 'star';
      case BadgeType.verified:
        return 'verified';
      case BadgeType.newbie:
        return 'new_releases';
      case BadgeType.experienced:
        return 'workspace_premium';
      case BadgeType.reliable:
        return 'shield';
    }
  }

  String get color {
    switch (type) {
      case BadgeType.liveFarmProof:
        return '#FF6B6B'; // Red
      case BadgeType.recentlyActive:
        return '#4ECDC4'; // Teal
      case BadgeType.fastResponse:
        return '#FFE66D'; // Yellow
      case BadgeType.deliverySuccess:
        return '#95E1D3'; // Mint
      case BadgeType.repeatBuyer:
        return '#F38BA8'; // Pink
      case BadgeType.topRated:
        return '#FFD93D'; // Gold
      case BadgeType.verified:
        return '#6BCF7F'; // Green
      case BadgeType.newbie:
        return '#A8DADC'; // Light Blue
      case BadgeType.experienced:
        return '#457B9D'; // Blue
      case BadgeType.reliable:
        return '#1D3557'; // Dark Blue
    }
  }
}

class ActivityData {
  final String userId;
  final DateTime lastActivity;
  final int messageResponseTime;
  final double deliverySuccessRate;
  final double repeatCustomerRate;
  final double averageRating;
  final int totalOrders;
  final int completedOrders;
  final DateTime joinDate;
  final int recentVideoUploads;

  ActivityData({
    required this.userId,
    required this.lastActivity,
    required this.messageResponseTime,
    required this.deliverySuccessRate,
    required this.repeatCustomerRate,
    required this.averageRating,
    required this.totalOrders,
    required this.completedOrders,
    required this.joinDate,
    required this.recentVideoUploads,
  });
}

class VerificationBadgeService {
  static final VerificationBadgeService _instance = VerificationBadgeService._internal();
  factory VerificationBadgeService() => _instance;
  VerificationBadgeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final _badgeUpdateController = StreamController<List<VerificationBadge>>.broadcast();
  final Map<String, List<VerificationBadge>> _badgeCache = {};
  Timer? _evaluationTimer;

  Stream<List<VerificationBadge>> get badgeUpdateStream => _badgeUpdateController.stream;

  /// Initialize the badge service
  void initialize() {
    _startPeriodicEvaluation();
  }

  /// Get all badges for a user
  Future<List<VerificationBadge>> getUserBadges(String userId) async {
    try {
      // Check cache first
      if (_badgeCache.containsKey(userId)) {
        final cached = _badgeCache[userId]!;
        if (cached.isNotEmpty) {
          return cached.where((badge) => badge.isActive).toList();
        }
      }

      final badges = await _supabase
          .from('verification_badges')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('earned_at', ascending: false);

      final badgeList = badges
          .map((b) => VerificationBadge.fromJson(b))
          .toList();

      // Cache the result
      _badgeCache[userId] = badgeList;

      return badgeList;
    } catch (e) {
      debugPrint('Failed to get user badges: $e');
      return [];
    }
  }

  /// Award a badge to a user
  Future<void> awardBadge(
    String userId, 
    BadgeType type, 
    Map<String, dynamic> data,
    {Duration? expiresIn}
  ) async {
    try {
      final expiresAt = expiresIn != null 
          ? DateTime.now().add(expiresIn)
          : null;

      await _supabase.from('verification_badges').upsert({
        'user_id': userId,
        'badge_type': type.name,
        'badge_data': data,
        'earned_at': DateTime.now().toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': true,
      });

      // Clear cache and notify
      _badgeCache.remove(userId);
      await _notifyBadgeAwarded(userId, type);
    } catch (e) {
      debugPrint('Failed to award badge: $e');
      rethrow;
    }
  }

  /// Remove a badge from a user
  Future<void> removeBadge(String userId, BadgeType type) async {
    try {
      await _supabase
          .from('verification_badges')
          .update({'is_active': false})
          .eq('user_id', userId)
          .eq('badge_type', type.name);

      // Clear cache
      _badgeCache.remove(userId);
    } catch (e) {
      debugPrint('Failed to remove badge: $e');
      rethrow;
    }
  }

  /// Update user activity and evaluate badges
  Future<void> updateUserActivity(
    String userId, 
    String activityType, 
    Map<String, dynamic> activityData
  ) async {
    try {
      // Log the activity
      await _supabase.from('user_activity').insert({
        'user_id': userId,
        'activity_type': activityType,
        'activity_data': activityData,
      });

      // Evaluate badges based on activity
      await _evaluateUserBadges(userId);
    } catch (e) {
      debugPrint('Failed to update user activity: $e');
    }
  }

  /// Evaluate and award badges for a user
  Future<void> _evaluateUserBadges(String userId) async {
    try {
      final activityData = await _getUserActivityData(userId);
      final currentBadges = await getUserBadges(userId);
      final currentBadgeTypes = currentBadges.map((b) => b.type).toSet();

      // Evaluate each badge type
      for (final badgeType in BadgeType.values) {
        final shouldHaveBadge = _shouldAwardBadge(badgeType, activityData);
        final currentlyHasBadge = currentBadgeTypes.contains(badgeType);

        if (shouldHaveBadge && !currentlyHasBadge) {
          // Award new badge
          final badgeData = _getBadgeData(badgeType, activityData);
          final expiresIn = _getBadgeExpiration(badgeType);
          await awardBadge(userId, badgeType, badgeData, expiresIn: expiresIn);
        } else if (!shouldHaveBadge && currentlyHasBadge) {
          // Remove badge if criteria no longer met
          await removeBadge(userId, badgeType);
        }
      }
    } catch (e) {
      debugPrint('Failed to evaluate user badges: $e');
    }
  }

  /// Get user activity data for badge evaluation
  Future<ActivityData> _getUserActivityData(String userId) async {
    try {
      // Get user basic info
      final user = await _supabase
          .from('users')
          .select('created_at')
          .eq('id', userId)
          .single();

      // Get last activity
      final lastActivityResult = await _supabase
          .from('user_activity')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final lastActivity = lastActivityResult != null
          ? DateTime.parse(lastActivityResult['created_at'])
          : DateTime.now().subtract(const Duration(days: 1));

      // Get message response time (mock data for now)
      const messageResponseTime = 8; // minutes

      // Get delivery success rate
      final orders = await _supabase
          .from('orders')
          .select('status')
          .eq('farmer_id', userId);

      double deliverySuccessRate = 1.0;
      if (orders.isNotEmpty) {
        final deliveredOrders = orders.where((o) => o['status'] == 'delivered').length;
        deliverySuccessRate = deliveredOrders / orders.length;
      }

      // Get repeat customer rate
      final uniqueCustomers = await _supabase
          .from('orders')
          .select('customer_id')
          .eq('farmer_id', userId);

      final repeatCustomers = await _supabase
          .from('orders')
          .select('customer_id')
          .eq('farmer_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 90)).toIso8601String());

      double repeatCustomerRate = 0.0;
      if (uniqueCustomers.isNotEmpty && repeatCustomers.isNotEmpty) {
        final uniqueCount = uniqueCustomers.map((o) => o['customer_id']).toSet().length;
        final repeatCount = repeatCustomers.map((o) => o['customer_id']).toSet().length;
        repeatCustomerRate = repeatCount / uniqueCount;
      }

      // Get average rating
      final reviews = await _supabase
          .from('reviews')
          .select('rating')
          .eq('farmer_id', userId);

      double averageRating = 0.0;
      if (reviews.isNotEmpty) {
        final ratings = reviews.map((r) => r['rating'] as int).toList();
        averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }

      // Get recent video uploads
      final videoUploads = await _supabase
          .from('user_activity')
          .select('id')
          .eq('user_id', userId)
          .eq('activity_type', 'video_upload')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      return ActivityData(
        userId: userId,
        lastActivity: lastActivity,
        messageResponseTime: messageResponseTime,
        deliverySuccessRate: deliverySuccessRate,
        repeatCustomerRate: repeatCustomerRate,
        averageRating: averageRating,
        totalOrders: orders.length,
        completedOrders: orders.where((o) => o['status'] == 'delivered').length,
        joinDate: DateTime.parse(user['created_at']),
        recentVideoUploads: videoUploads.length,
      );
    } catch (e) {
      debugPrint('Failed to get user activity data: $e');
      return ActivityData(
        userId: userId,
        lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
        messageResponseTime: 15,
        deliverySuccessRate: 0.0,
        repeatCustomerRate: 0.0,
        averageRating: 0.0,
        totalOrders: 0,
        completedOrders: 0,
        joinDate: DateTime.now(),
        recentVideoUploads: 0,
      );
    }
  }

  /// Check if user should be awarded a specific badge
  bool _shouldAwardBadge(BadgeType type, ActivityData data) {
    switch (type) {
      case BadgeType.liveFarmProof:
        return data.recentVideoUploads > 0;
      
      case BadgeType.recentlyActive:
        return DateTime.now().difference(data.lastActivity).inMinutes <= 5;
      
      case BadgeType.fastResponse:
        return data.messageResponseTime <= 10;
      
      case BadgeType.deliverySuccess:
        return data.deliverySuccessRate >= 0.98 && data.totalOrders >= 10;
      
      case BadgeType.repeatBuyer:
        return data.repeatCustomerRate >= 0.80 && data.totalOrders >= 5;
      
      case BadgeType.topRated:
        return data.averageRating >= 4.5 && data.totalOrders >= 5;
      
      case BadgeType.verified:
        // This should be awarded by admin, not automatically
        return false;
      
      case BadgeType.newbie:
        return DateTime.now().difference(data.joinDate).inDays <= 30;
      
      case BadgeType.experienced:
        return DateTime.now().difference(data.joinDate).inDays >= 365;
      
      case BadgeType.reliable:
        final completionRate = data.totalOrders > 0 
            ? data.completedOrders / data.totalOrders 
            : 0.0;
        return completionRate >= 0.95 && data.totalOrders >= 10;
    }
  }

  /// Get badge-specific data
  Map<String, dynamic> _getBadgeData(BadgeType type, ActivityData data) {
    switch (type) {
      case BadgeType.liveFarmProof:
        return {
          'recent_uploads': data.recentVideoUploads,
          'last_upload': DateTime.now().toIso8601String(),
        };
      
      case BadgeType.recentlyActive:
        return {
          'last_activity': data.lastActivity.toIso8601String(),
          'minutes_ago': DateTime.now().difference(data.lastActivity).inMinutes,
        };
      
      case BadgeType.fastResponse:
        return {
          'avg_response_time_minutes': data.messageResponseTime,
        };
      
      case BadgeType.deliverySuccess:
        return {
          'success_rate': data.deliverySuccessRate,
          'total_orders': data.totalOrders,
        };
      
      case BadgeType.repeatBuyer:
        return {
          'repeat_rate': data.repeatCustomerRate,
          'total_orders': data.totalOrders,
        };
      
      case BadgeType.topRated:
        return {
          'average_rating': data.averageRating,
          'total_orders': data.totalOrders,
        };
      
      case BadgeType.newbie:
        return {
          'join_date': data.joinDate.toIso8601String(),
          'days_on_platform': DateTime.now().difference(data.joinDate).inDays,
        };
      
      case BadgeType.experienced:
        return {
          'join_date': data.joinDate.toIso8601String(),
          'years_on_platform': DateTime.now().difference(data.joinDate).inDays / 365,
        };
      
      case BadgeType.reliable:
        return {
          'completion_rate': data.totalOrders > 0 ? data.completedOrders / data.totalOrders : 0.0,
          'total_orders': data.totalOrders,
          'completed_orders': data.completedOrders,
        };
      
      default:
        return {};
    }
  }

  /// Get badge expiration duration
  Duration? _getBadgeExpiration(BadgeType type) {
    switch (type) {
      case BadgeType.recentlyActive:
        return const Duration(minutes: 10); // Expires after 10 minutes
      case BadgeType.liveFarmProof:
        return const Duration(days: 7); // Expires after 1 week
      case BadgeType.newbie:
        return const Duration(days: 30); // Expires after 30 days
      default:
        return null; // No expiration
    }
  }

  /// Watch badges for a user
  Stream<List<VerificationBadge>> watchUserBadges(String userId) {
    return _supabase
        .from('verification_badges')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((b) => b['user_id'] == userId && b['is_active'] == true)
            .map((b) => VerificationBadge.fromJson(b))
            .toList());
  }

  /// Get users with specific badge
  Future<List<String>> getUsersWithBadge(BadgeType type) async {
    try {
      final users = await _supabase
          .from('verification_badges')
          .select('user_id')
          .eq('badge_type', type.name)
          .eq('is_active', true);

      return users.map((u) => u['user_id'] as String).toList();
    } catch (e) {
      debugPrint('Failed to get users with badge: $e');
      return [];
    }
  }

  /// Bulk evaluate badges for all users
  Future<void> bulkEvaluateAllUsers() async {
    try {
      final users = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'farmer'); // Only evaluate farmers for now

      for (final user in users) {
        await _evaluateUserBadges(user['id']);
        // Add small delay to avoid overwhelming the database
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('Failed to bulk evaluate badges: $e');
    }
  }

  /// Start periodic badge evaluation
  void _startPeriodicEvaluation() {
    _evaluationTimer?.cancel();
    _evaluationTimer = Timer.periodic(
      const Duration(minutes: 5), // Evaluate every 5 minutes
      (_) => bulkEvaluateAllUsers(),
    );
  }

  /// Notify user about new badge
  Future<void> _notifyBadgeAwarded(String userId, BadgeType type) async {
    try {
      final badge = VerificationBadge(
        id: '',
        userId: userId,
        type: type,
        badgeData: {},
        earnedAt: DateTime.now(),
        isActive: true,
      );

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'New Badge Earned!',
        'message': 'You earned the "${badge.displayName}" badge! ${badge.description}',
        'type': 'badge_awarded',
        'data': {
          'badge_type': type.name,
          'badge_name': badge.displayName,
        },
      });
    } catch (e) {
      debugPrint('Failed to notify badge awarded: $e');
    }
  }

  /// Clear cache for user
  void clearCache(String userId) {
    _badgeCache.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _badgeCache.clear();
  }

  void dispose() {
    _evaluationTimer?.cancel();
    _badgeUpdateController.close();
  }
}