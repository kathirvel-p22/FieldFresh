import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'realtime_service.dart';

enum VerificationLevel {
  phone,
  profile,
  farm,
  admin,
  reputation,
  government,
}

enum VerificationStatus {
  pending,
  inProgress,
  completed,
  rejected,
}

class TrustVerification {
  final String id;
  final String userId;
  final VerificationLevel level;
  final Map<String, dynamic> verificationData;
  final VerificationStatus status;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;

  TrustVerification({
    required this.id,
    required this.userId,
    required this.level,
    required this.verificationData,
    required this.status,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
  });

  factory TrustVerification.fromJson(Map<String, dynamic> json) {
    return TrustVerification(
      id: json['id'],
      userId: json['user_id'],
      level: VerificationLevel.values.firstWhere(
        (l) => l.name == json['verification_type'],
      ),
      verificationData: json['verification_data'] ?? {},
      status: VerificationStatus.values.firstWhere(
        (s) => s.name == json['status'],
      ),
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      verifiedBy: json['verified_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'verification_type': level.name,
      'verification_data': verificationData,
      'status': status.name,
      'verified_at': verifiedAt?.toIso8601String(),
      'verified_by': verifiedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TrustScore {
  final String userId;
  final double score;
  final Map<VerificationLevel, bool> completedLevels;
  final DateTime lastUpdated;

  TrustScore({
    required this.userId,
    required this.score,
    required this.completedLevels,
    required this.lastUpdated,
  });

  String get displayText => "Trust Score: ${score.toInt()}%";

  String get trustLevel {
    if (score >= 90) return "Excellent";
    if (score >= 75) return "Very Good";
    if (score >= 60) return "Good";
    if (score >= 40) return "Fair";
    return "Building Trust";
  }

  factory TrustScore.fromJson(Map<String, dynamic> json) {
    final completedLevels = <VerificationLevel, bool>{};
    for (final level in VerificationLevel.values) {
      completedLevels[level] = json['completed_levels']?[level.name] ?? false;
    }

    return TrustScore(
      userId: json['user_id'],
      score: (json['trust_score'] ?? 0.0).toDouble(),
      completedLevels: completedLevels,
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    final completedLevelsJson = <String, bool>{};
    for (final entry in completedLevels.entries) {
      completedLevelsJson[entry.key.name] = entry.value;
    }

    return {
      'user_id': userId,
      'trust_score': score,
      'completed_levels': completedLevelsJson,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class TrustService {
  static final TrustService _instance = TrustService._internal();
  factory TrustService() => _instance;
  TrustService._internal();

  static const Map<VerificationLevel, double> weights = {
    VerificationLevel.phone: 0.10, // 10%
    VerificationLevel.profile: 0.15, // 15%
    VerificationLevel.farm: 0.20, // 20%
    VerificationLevel.admin: 0.25, // 25%
    VerificationLevel.reputation: 0.25, // 25%
    VerificationLevel.government: 0.05, // 5%
  };

  static const Map<VerificationLevel, double> WEIGHTS = weights;

  final SupabaseClient _supabase = Supabase.instance.client;
  final _trustScoreController = StreamController<TrustScore>.broadcast();
  final Map<String, TrustScore> _trustScoreCache = {};

  Stream<TrustScore> get trustScoreStream => _trustScoreController.stream;

  /// Calculate trust score for a user
  Future<TrustScore> calculateTrustScore(String userId) async {
    try {
      // Check cache first
      if (_trustScoreCache.containsKey(userId)) {
        final cached = _trustScoreCache[userId]!;
        if (DateTime.now().difference(cached.lastUpdated).inMinutes < 5) {
          return cached;
        }
      }

      // Get all verifications for user
      final verifications = await _supabase
          .from('trust_verifications')
          .select('*')
          .eq('user_id', userId);

      final completedLevels = <VerificationLevel, bool>{};
      double totalScore = 0.0;

      // Initialize all levels as false
      for (final level in VerificationLevel.values) {
        completedLevels[level] = false;
      }

      // Calculate score based on completed verifications
      for (final verification in verifications) {
        final level = VerificationLevel.values.firstWhere(
          (l) => l.name == verification['verification_type'],
        );

        final isCompleted = verification['status'] == 'completed';
        completedLevels[level] = isCompleted;

        if (isCompleted) {
          totalScore += WEIGHTS[level]! * 100;
        }
      }

      // Add reputation score based on ratings and orders
      if (completedLevels[VerificationLevel.reputation] == true) {
        final reputationScore = await _calculateReputationScore(userId);
        totalScore =
            (totalScore - (WEIGHTS[VerificationLevel.reputation]! * 100)) +
                (WEIGHTS[VerificationLevel.reputation]! * reputationScore);
      }

      final trustScore = TrustScore(
        userId: userId,
        score: totalScore.clamp(0.0, 100.0),
        completedLevels: completedLevels,
        lastUpdated: DateTime.now(),
      );

      // Cache the result
      _trustScoreCache[userId] = trustScore;

      return trustScore;
    } catch (e) {
      debugPrint('Failed to calculate trust score: $e');

      // Return default score on error
      return TrustScore(
        userId: userId,
        score: 0.0,
        completedLevels: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Calculate reputation score based on ratings and order history
  Future<double> _calculateReputationScore(String userId) async {
    try {
      // Get user ratings
      final ratingsResult = await _supabase
          .from('reviews')
          .select('rating')
          .eq('farmer_id', userId);

      if (ratingsResult.isEmpty) return 0.0;

      // Calculate average rating
      final ratings = ratingsResult.map((r) => r['rating'] as int).toList();
      final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

      // Get order completion rate
      final ordersResult = await _supabase
          .from('orders')
          .select('status')
          .eq('farmer_id', userId);

      double completionRate = 1.0;
      if (ordersResult.isNotEmpty) {
        final completedOrders =
            ordersResult.where((o) => o['status'] == 'delivered').length;
        completionRate = completedOrders / ordersResult.length;
      }

      // Calculate reputation score (0-100)
      final ratingScore = (avgRating / 5.0) * 60; // Max 60 points for rating
      final completionScore =
          completionRate * 40; // Max 40 points for completion

      return (ratingScore + completionScore).clamp(0.0, 100.0);
    } catch (e) {
      debugPrint('Failed to calculate reputation score: $e');
      return 0.0;
    }
  }

  /// Update verification level for a user
  Future<void> updateVerificationLevel(String userId, VerificationLevel level,
      Map<String, dynamic> verificationData,
      {String? verifiedBy}) async {
    try {
      await _supabase.from('trust_verifications').upsert({
        'user_id': userId,
        'verification_type': level.name,
        'verification_data': verificationData,
        'status': VerificationStatus.completed.name,
        'verified_at': DateTime.now().toIso8601String(),
        'verified_by': verifiedBy ?? SupabaseService.currentUserId,
      });

      // Clear cache and broadcast update
      _trustScoreCache.remove(userId);
      await broadcastTrustUpdate(userId);
    } catch (e) {
      debugPrint('Failed to update verification level: $e');
      rethrow;
    }
  }

  /// Start verification process
  Future<void> startVerification(
    String userId,
    VerificationLevel level,
    Map<String, dynamic> verificationData,
  ) async {
    try {
      await _supabase.from('trust_verifications').upsert({
        'user_id': userId,
        'verification_type': level.name,
        'verification_data': verificationData,
        'status': VerificationStatus.pending.name,
      });

      // Clear cache
      _trustScoreCache.remove(userId);
    } catch (e) {
      debugPrint('Failed to start verification: $e');
      rethrow;
    }
  }

  /// Get user verifications
  Future<List<TrustVerification>> getUserVerifications(String userId) async {
    try {
      final verifications = await _supabase
          .from('trust_verifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at');

      return verifications.map((v) => TrustVerification.fromJson(v)).toList();
    } catch (e) {
      debugPrint('Failed to get user verifications: $e');
      return [];
    }
  }

  /// Get completed verification levels
  Future<List<VerificationLevel>> getCompletedVerifications(
      String userId) async {
    try {
      final verifications = await _supabase
          .from('trust_verifications')
          .select('verification_type')
          .eq('user_id', userId)
          .eq('status', 'completed');

      return verifications
          .map((v) => VerificationLevel.values.firstWhere(
                (l) => l.name == v['verification_type'],
              ))
          .toList();
    } catch (e) {
      debugPrint('Failed to get completed verifications: $e');
      return [];
    }
  }

  /// Watch trust score changes
  Stream<TrustScore> watchTrustScore(String userId) {
    return _supabase
        .from('trust_verifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((_) => calculateTrustScore(userId));
  }

  /// Broadcast trust score update
  Future<void> broadcastTrustUpdate(String userId) async {
    try {
      final trustScore = await calculateTrustScore(userId);

      // Use realtime service for broadcasting
      await RealtimeService.broadcastTrustScoreUpdate(userId, trustScore.score);

      _trustScoreController.add(trustScore);
    } catch (e) {
      debugPrint('Failed to broadcast trust update: $e');
    }
  }

  /// Auto-verify phone verification
  Future<void> autoVerifyPhone(String userId, String phoneNumber) async {
    await updateVerificationLevel(
      userId,
      VerificationLevel.phone,
      {
        'phone_number': phoneNumber,
        'verified_at': DateTime.now().toIso8601String(),
        'method': 'otp',
      },
    );
  }

  /// Auto-verify profile completion
  Future<void> autoVerifyProfile(
      String userId, Map<String, dynamic> profileData) async {
    // Check if profile is complete
    final requiredFields = ['name', 'profile_image', 'address'];
    final hasAllFields = requiredFields.every((field) =>
        profileData[field] != null && profileData[field].toString().isNotEmpty);

    if (hasAllFields) {
      await updateVerificationLevel(
        userId,
        VerificationLevel.profile,
        {
          'profile_completeness': 100,
          'verified_fields': requiredFields,
          'auto_verified': true,
        },
      );
    }
  }

  /// Submit farm verification
  Future<void> submitFarmVerification(
    String userId,
    double latitude,
    double longitude,
    List<String> farmImageUrls,
    List<String> cropTypes,
  ) async {
    await startVerification(
      userId,
      VerificationLevel.farm,
      {
        'latitude': latitude,
        'longitude': longitude,
        'farm_images': farmImageUrls,
        'crop_types': cropTypes,
        'submitted_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Auto-update reputation based on new reviews/orders
  Future<void> updateReputation(String userId) async {
    try {
      final reputationScore = await _calculateReputationScore(userId);

      if (reputationScore > 0) {
        await updateVerificationLevel(
          userId,
          VerificationLevel.reputation,
          {
            'reputation_score': reputationScore,
            'last_calculated': DateTime.now().toIso8601String(),
            'auto_updated': true,
          },
        );
      }
    } catch (e) {
      debugPrint('Failed to update reputation: $e');
    }
  }

  /// Get pending verifications for admin review
  Future<List<TrustVerification>> getPendingVerifications() async {
    try {
      final verifications = await _supabase
          .from('trust_verifications')
          .select('*, users!inner(name, role)')
          .eq('status', 'pending')
          .order('created_at');

      return verifications.map((v) => TrustVerification.fromJson(v)).toList();
    } catch (e) {
      debugPrint('Failed to get pending verifications: $e');
      return [];
    }
  }

  /// Admin approve verification
  Future<void> adminApproveVerification(
    String verificationId,
    String adminId,
    String reason,
  ) async {
    try {
      await _supabase.from('trust_verifications').update({
        'status': VerificationStatus.completed.name,
        'verified_at': DateTime.now().toIso8601String(),
        'verified_by': adminId,
      }).eq('id', verificationId);

      // Log admin action
      await _supabase.from('admin_actions').insert({
        'admin_id': adminId,
        'target_user_id': null, // Will be filled by trigger
        'action_type': 'approve_verification',
        'action_data': {
          'verification_id': verificationId,
          'reason': reason,
        },
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Failed to approve verification: $e');
      rethrow;
    }
  }

  /// Admin reject verification
  Future<void> adminRejectVerification(
    String verificationId,
    String adminId,
    String reason,
  ) async {
    try {
      await _supabase.from('trust_verifications').update({
        'status': VerificationStatus.rejected.name,
        'verified_by': adminId,
      }).eq('id', verificationId);

      // Log admin action
      await _supabase.from('admin_actions').insert({
        'admin_id': adminId,
        'target_user_id': null, // Will be filled by trigger
        'action_type': 'reject_verification',
        'action_data': {
          'verification_id': verificationId,
          'reason': reason,
        },
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Failed to reject verification: $e');
      rethrow;
    }
  }

  /// Clear cache for user
  void clearCache(String userId) {
    _trustScoreCache.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _trustScoreCache.clear();
  }

  void dispose() {
    _trustScoreController.close();
  }
}
