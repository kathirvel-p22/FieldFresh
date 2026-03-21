import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'trust_service.dart';
import 'verification_badge_service.dart';
import 'advanced_session_service.dart';

enum AdminActionType {
  approve,
  reject,
  suspend,
  unsuspend,
  flag,
  unflag,
  delete,
  verifyFarm,
  rejectFarm,
  awardBadge,
  removeBadge,
  updateTrust,
}

enum UserStatus {
  active,
  suspended,
  flagged,
  deleted,
  pending,
}

class AdminAction {
  final String id;
  final String adminId;
  final String targetUserId;
  final AdminActionType actionType;
  final Map<String, dynamic> actionData;
  final String reason;
  final int? durationHours;
  final DateTime createdAt;

  AdminAction({
    required this.id,
    required this.adminId,
    required this.targetUserId,
    required this.actionType,
    required this.actionData,
    required this.reason,
    this.durationHours,
    required this.createdAt,
  });

  factory AdminAction.fromJson(Map<String, dynamic> json) {
    return AdminAction(
      id: json['id'],
      adminId: json['admin_id'],
      targetUserId: json['target_user_id'],
      actionType: AdminActionType.values.firstWhere(
        (t) => t.name == json['action_type'],
      ),
      actionData: json['action_data'] ?? {},
      reason: json['reason'],
      durationHours: json['duration_hours'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'target_user_id': targetUserId,
      'action_type': actionType.name,
      'action_data': actionData,
      'reason': reason,
      'duration_hours': durationHours,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FraudScore {
  final String userId;
  final double riskScore;
  final String riskLevel;
  final List<String> reasons;
  final DateTime calculatedAt;

  FraudScore({
    required this.userId,
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
    required this.calculatedAt,
  });

  factory FraudScore.fromJson(Map<String, dynamic> json) {
    return FraudScore(
      userId: json['user_id'],
      riskScore: (json['risk_score'] ?? 0.0).toDouble(),
      riskLevel: json['risk_level'] ?? 'low',
      reasons: List<String>.from(json['reasons'] ?? []),
      calculatedAt: DateTime.parse(json['calculated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'reasons': reasons,
      'calculated_at': calculatedAt.toIso8601String(),
    };
  }
}

class AdminStats {
  final int totalUsers;
  final int totalFarmers;
  final int totalCustomers;
  final int totalOrders;
  final double totalRevenue;
  final int pendingVerifications;
  final int flaggedUsers;
  final int suspendedUsers;
  final Map<String, int> ordersByStatus;
  final Map<String, double> revenueByMonth;

  AdminStats({
    required this.totalUsers,
    required this.totalFarmers,
    required this.totalCustomers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingVerifications,
    required this.flaggedUsers,
    required this.suspendedUsers,
    required this.ordersByStatus,
    required this.revenueByMonth,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      totalFarmers: json['total_farmers'] ?? 0,
      totalCustomers: json['total_customers'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0.0).toDouble(),
      pendingVerifications: json['pending_verifications'] ?? 0,
      flaggedUsers: json['flagged_users'] ?? 0,
      suspendedUsers: json['suspended_users'] ?? 0,
      ordersByStatus: Map<String, int>.from(json['orders_by_status'] ?? {}),
      revenueByMonth: Map<String, double>.from(json['revenue_by_month'] ?? {}),
    );
  }
}

class AdminAlert {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? userId;
  final Map<String, dynamic> data;
  final String priority;
  final bool isRead;
  final DateTime createdAt;

  AdminAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.userId,
    required this.data,
    required this.priority,
    required this.isRead,
    required this.createdAt,
  });

  factory AdminAlert.fromJson(Map<String, dynamic> json) {
    return AdminAlert(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      userId: json['user_id'],
      data: json['data'] ?? {},
      priority: json['priority'] ?? 'medium',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class EnhancedAdminService {
  static final EnhancedAdminService _instance = EnhancedAdminService._internal();
  factory EnhancedAdminService() => _instance;
  EnhancedAdminService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final _alertController = StreamController<List<AdminAlert>>.broadcast();
  final _statsController = StreamController<AdminStats>.broadcast();

  Stream<List<AdminAlert>> get alertStream => _alertController.stream;
  Stream<AdminStats> get statsStream => _statsController.stream;

  /// Get platform statistics
  Future<AdminStats> getPlatformStats() async {
    try {
      // Get user counts
      final userCounts = await _supabase
          .from('users')
          .select('role')
          .neq('role', 'admin');

      final totalUsers = userCounts.length;
      final totalFarmers = userCounts.where((u) => u['role'] == 'farmer').length;
      final totalCustomers = userCounts.where((u) => u['role'] == 'customer').length;

      // Get order statistics
      final orders = await _supabase
          .from('orders')
          .select('status, total_amount, created_at');

      final totalOrders = orders.length;
      final totalRevenue = orders
          .map((o) => (o['total_amount'] ?? 0.0) as double)
          .fold(0.0, (sum, amount) => sum + amount);

      // Get orders by status
      final ordersByStatus = <String, int>{};
      for (final order in orders) {
        final status = order['status'] as String;
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
      }

      // Get revenue by month (last 12 months)
      final revenueByMonth = <String, double>{};
      final now = DateTime.now();
      for (int i = 0; i < 12; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        
        final monthlyRevenue = orders
            .where((o) {
              final orderDate = DateTime.parse(o['created_at']);
              return orderDate.year == month.year && orderDate.month == month.month;
            })
            .map((o) => (o['total_amount'] ?? 0.0) as double)
            .fold(0.0, (sum, amount) => sum + amount);
        
        revenueByMonth[monthKey] = monthlyRevenue;
      }

      // Get pending verifications
      final pendingVerifications = await _supabase
          .from('trust_verifications')
          .select('id')
          .eq('status', 'pending');

      // Get flagged and suspended users
      final flaggedUsers = await _supabase
          .from('users')
          .select('id')
          .eq('status', 'flagged');

      final suspendedUsers = await _supabase
          .from('users')
          .select('id')
          .eq('status', 'suspended');

      return AdminStats(
        totalUsers: totalUsers,
        totalFarmers: totalFarmers,
        totalCustomers: totalCustomers,
        totalOrders: totalOrders,
        totalRevenue: totalRevenue,
        pendingVerifications: pendingVerifications.length,
        flaggedUsers: flaggedUsers.length,
        suspendedUsers: suspendedUsers.length,
        ordersByStatus: ordersByStatus,
        revenueByMonth: revenueByMonth,
      );
    } catch (e) {
      debugPrint('Failed to get platform stats: $e');
      return AdminStats(
        totalUsers: 0,
        totalFarmers: 0,
        totalCustomers: 0,
        totalOrders: 0,
        totalRevenue: 0.0,
        pendingVerifications: 0,
        flaggedUsers: 0,
        suspendedUsers: 0,
        ordersByStatus: {},
        revenueByMonth: {},
      );
    }
  }

  /// Get flagged users for review
  Future<List<Map<String, dynamic>>> getFlaggedUsers() async {
    try {
      final users = await _supabase
          .from('users')
          .select('*, fraud_scores(*)')
          .eq('status', 'flagged')
          .order('updated_at', ascending: false);

      return users;
    } catch (e) {
      debugPrint('Failed to get flagged users: $e');
      return [];
    }
  }

  /// Approve a user
  Future<void> approveUser(String userId, String reason) async {
    try {
      final adminId = SupabaseService.currentUserId ?? '';
      if (adminId.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      // Update user status
      await _supabase
          .from('users')
          .update({'status': 'active'})
          .eq('id', userId);

      // Log admin action
      await _logAdminAction(
        adminId,
        userId,
        AdminActionType.approve,
        {'reason': reason},
        reason,
      );

      // Send notification to user
      await _notifyUser(
        userId,
        'Account Approved',
        'Your account has been approved and is now active.',
        'account_approved',
      );

      // Auto-verify admin verification level
      final trustService = TrustService();
      await trustService.updateVerificationLevel(
        userId,
        VerificationLevel.admin,
        {
          'approved_by': adminId,
          'approved_at': DateTime.now().toIso8601String(),
          'reason': reason,
        },
        verifiedBy: adminId,
      );
    } catch (e) {
      debugPrint('Failed to approve user: $e');
      rethrow;
    }
  }

  /// Suspend a user
  Future<void> suspendUser(String userId, Duration duration, String reason) async {
    try {
      final adminId = SupabaseService.currentUserId ?? '';
      if (adminId.isEmpty) {
        throw Exception('Admin not authenticated');
      }
      final suspendUntil = DateTime.now().add(duration);

      // Update user status
      await _supabase
          .from('users')
          .update({
            'status': 'suspended',
            'suspended_until': suspendUntil.toIso8601String(),
          })
          .eq('id', userId);

      // Log admin action
      await _logAdminAction(
        adminId,
        userId,
        AdminActionType.suspend,
        {
          'duration_hours': duration.inHours,
          'suspended_until': suspendUntil.toIso8601String(),
        },
        reason,
        durationHours: duration.inHours,
      );

      // Send notification to user
      await _notifyUser(
        userId,
        'Account Suspended',
        'Your account has been suspended until ${suspendUntil.toString()}. Reason: $reason',
        'account_suspended',
      );

      // Invalidate all user sessions
      final sessionService = AdvancedSessionService();
      await sessionService.invalidateAllSessions(userId);
    } catch (e) {
      debugPrint('Failed to suspend user: $e');
      rethrow;
    }
  }

  /// Flag a user for review
  Future<void> flagUser(String userId, String reason, {double? riskScore}) async {
    try {
      final adminId = SupabaseService.currentUserId ?? '';
      if (adminId.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      // Update user status
      await _supabase
          .from('users')
          .update({'status': 'flagged'})
          .eq('id', userId);

      // Create fraud score record if provided
      if (riskScore != null) {
        await _supabase.from('fraud_scores').insert({
          'user_id': userId,
          'risk_score': riskScore,
          'risk_level': _getRiskLevel(riskScore),
          'reasons': [reason],
          'flagged_by': adminId,
        });
      }

      // Log admin action
      await _logAdminAction(
        adminId,
        userId,
        AdminActionType.flag,
        {'risk_score': riskScore, 'reason': reason},
        reason,
      );

      // Create admin alert
      await _createAdminAlert(
        'user_flagged',
        'User Flagged for Review',
        'User has been flagged and requires admin review.',
        userId,
        {'reason': reason, 'risk_score': riskScore},
        'high',
      );
    } catch (e) {
      debugPrint('Failed to flag user: $e');
      rethrow;
    }
  }

  /// Analyze fraud risk for a user
  Future<FraudScore> analyzeFraudRisk(String userId) async {
    try {
      final user = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      double riskScore = 0.0;
      final reasons = <String>[];

      // Check profile completeness
      if (user['profile_image'] == null) {
        riskScore += 0.2;
        reasons.add('No profile image');
      }
      if (user['address'] == null || user['address'].toString().isEmpty) {
        riskScore += 0.15;
        reasons.add('Incomplete address');
      }

      // Check activity patterns
      final orders = await _supabase
          .from('orders')
          .select('*')
          .eq('farmer_id', userId);

      final userAge = DateTime.now().difference(DateTime.parse(user['created_at'])).inDays;
      if (orders.isEmpty && userAge > 30) {
        riskScore += 0.3;
        reasons.add('No orders after 30 days');
      }

      // Check verification status
      final verifications = await _supabase
          .from('trust_verifications')
          .select('*')
          .eq('user_id', userId)
          .eq('status', 'completed');

      if (verifications.length < 2) {
        riskScore += 0.25;
        reasons.add('Low verification level');
      }

      // Check for suspicious patterns
      final recentActivity = await _supabase
          .from('user_activity')
          .select('*')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      if (recentActivity.isEmpty && userAge < 7) {
        riskScore += 0.1;
        reasons.add('No recent activity');
      }

      final riskLevel = _getRiskLevel(riskScore);

      final fraudScore = FraudScore(
        userId: userId,
        riskScore: riskScore.clamp(0.0, 1.0),
        riskLevel: riskLevel,
        reasons: reasons,
        calculatedAt: DateTime.now(),
      );

      // Store fraud score
      await _supabase.from('fraud_scores').upsert({
        'user_id': userId,
        'risk_score': fraudScore.riskScore,
        'risk_level': fraudScore.riskLevel,
        'reasons': fraudScore.reasons,
        'calculated_at': fraudScore.calculatedAt.toIso8601String(),
      });

      // Auto-flag high-risk users
      if (riskScore >= 0.7) {
        await flagUser(userId, 'High fraud risk detected automatically', riskScore: riskScore);
      }

      return fraudScore;
    } catch (e) {
      debugPrint('Failed to analyze fraud risk: $e');
      return FraudScore(
        userId: userId,
        riskScore: 0.0,
        riskLevel: 'low',
        reasons: [],
        calculatedAt: DateTime.now(),
      );
    }
  }

  /// Get pending farm verifications
  Future<List<TrustVerification>> getPendingFarmVerifications() async {
    try {
      final trustService = TrustService();
      final verifications = await trustService.getPendingVerifications();
      
      return verifications
          .where((v) => v.level == VerificationLevel.farm)
          .toList();
    } catch (e) {
      debugPrint('Failed to get pending farm verifications: $e');
      return [];
    }
  }

  /// Approve farm verification
  Future<void> approveFarmVerification(String verificationId, String reason) async {
    try {
      final adminId = SupabaseService.currentUserId ?? '';
      if (adminId.isEmpty) {
        throw Exception('Admin not authenticated');
      }
      final trustService = TrustService();

      await trustService.adminApproveVerification(verificationId, adminId, reason);

      // Award farm verification badge
      final verification = await _supabase
          .from('trust_verifications')
          .select('user_id')
          .eq('id', verificationId)
          .single();

      final badgeService = VerificationBadgeService();
      await badgeService.awardBadge(
        verification['user_id'],
        BadgeType.verified,
        {'verified_by': adminId, 'verification_type': 'farm'},
      );
    } catch (e) {
      debugPrint('Failed to approve farm verification: $e');
      rethrow;
    }
  }

  /// Reject farm verification
  Future<void> rejectFarmVerification(String verificationId, String reason) async {
    try {
      final adminId = SupabaseService.currentUserId ?? '';
      if (adminId.isEmpty) {
        throw Exception('Admin not authenticated');
      }
      final trustService = TrustService();

      await trustService.adminRejectVerification(verificationId, adminId, reason);
    } catch (e) {
      debugPrint('Failed to reject farm verification: $e');
      rethrow;
    }
  }

  /// Get admin alerts
  Future<List<AdminAlert>> getAdminAlerts({int limit = 50}) async {
    try {
      final alerts = await _supabase
          .from('admin_alerts')
          .select('*')
          .order('created_at', ascending: false)
          .limit(limit);

      return alerts.map((a) => AdminAlert.fromJson(a)).toList();
    } catch (e) {
      debugPrint('Failed to get admin alerts: $e');
      return [];
    }
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      await _supabase
          .from('admin_alerts')
          .update({'is_read': true})
          .eq('id', alertId);
    } catch (e) {
      debugPrint('Failed to mark alert as read: $e');
    }
  }

  /// Get admin action history
  Future<List<AdminAction>> getAdminActionHistory({
    String? adminId,
    String? targetUserId,
    int limit = 100,
  }) async {
    try {
      var queryBuilder = _supabase
          .from('admin_actions')
          .select('*');

      if (adminId != null) {
        queryBuilder = queryBuilder.eq('admin_id', adminId);
      }
      if (targetUserId != null) {
        queryBuilder = queryBuilder.eq('target_user_id', targetUserId);
      }

      final actions = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);
          
      return actions.map((a) => AdminAction.fromJson(a)).toList();
    } catch (e) {
      debugPrint('Failed to get admin action history: $e');
      return [];
    }
  }

  /// Bulk approve users
  Future<void> bulkApproveUsers(List<String> userIds, String reason) async {
    try {
      for (final userId in userIds) {
        await approveUser(userId, reason);
        // Add small delay to avoid overwhelming the database
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('Failed to bulk approve users: $e');
      rethrow;
    }
  }

  /// Monitor order disputes
  Future<List<Map<String, dynamic>>> getOrderDisputes() async {
    try {
      final disputes = await _supabase
          .from('orders')
          .select('*, customers(*), farmers(*)')
          .eq('status', 'disputed')
          .order('updated_at', ascending: false);

      return disputes;
    } catch (e) {
      debugPrint('Failed to get order disputes: $e');
      return [];
    }
  }

  /// Resolve order dispute
  Future<void> resolveOrderDispute(
    String orderId,
    String resolution,
    String reason,
    {String? refundAmount}
  ) async {
    try {
      final adminId = SupabaseService.currentUserId ?? '';
      if (adminId.isEmpty) {
        throw Exception('Admin not authenticated');
      }

      // Update order status
      await _supabase
          .from('orders')
          .update({
            'status': resolution,
            'admin_notes': reason,
            'resolved_by': adminId,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Log admin action
      await _logAdminAction(
        adminId,
        null, // No specific target user
        AdminActionType.approve, // Using approve for resolution
        {
          'order_id': orderId,
          'resolution': resolution,
          'refund_amount': refundAmount,
        },
        reason,
      );

      // Notify involved parties
      final order = await _supabase
          .from('orders')
          .select('customer_id, farmer_id')
          .eq('id', orderId)
          .single();

      await _notifyUser(
        order['customer_id'],
        'Order Dispute Resolved',
        'Your order dispute has been resolved. Resolution: $resolution',
        'dispute_resolved',
      );

      await _notifyUser(
        order['farmer_id'],
        'Order Dispute Resolved',
        'The order dispute has been resolved. Resolution: $resolution',
        'dispute_resolved',
      );
    } catch (e) {
      debugPrint('Failed to resolve order dispute: $e');
      rethrow;
    }
  }

  // Private helper methods

  Future<void> _logAdminAction(
    String adminId,
    String? targetUserId,
    AdminActionType actionType,
    Map<String, dynamic> actionData,
    String reason,
    {int? durationHours}
  ) async {
    try {
      await _supabase.from('admin_actions').insert({
        'admin_id': adminId,
        'target_user_id': targetUserId,
        'action_type': actionType.name,
        'action_data': actionData,
        'reason': reason,
        'duration_hours': durationHours,
      });
    } catch (e) {
      debugPrint('Failed to log admin action: $e');
    }
  }

  Future<void> _notifyUser(
    String userId,
    String title,
    String message,
    String type,
  ) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
      });
    } catch (e) {
      debugPrint('Failed to notify user: $e');
    }
  }

  Future<void> _createAdminAlert(
    String type,
    String title,
    String message,
    String? userId,
    Map<String, dynamic> data,
    String priority,
  ) async {
    try {
      await _supabase.from('admin_alerts').insert({
        'type': type,
        'title': title,
        'message': message,
        'user_id': userId,
        'data': data,
        'priority': priority,
        'is_read': false,
      });
    } catch (e) {
      debugPrint('Failed to create admin alert: $e');
    }
  }

  String _getRiskLevel(double riskScore) {
    if (riskScore >= 0.7) return 'high';
    if (riskScore >= 0.4) return 'medium';
    return 'low';
  }

  void dispose() {
    _alertController.close();
    _statsController.close();
  }
}

