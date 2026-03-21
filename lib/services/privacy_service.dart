import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'trust_service.dart';

enum DisclosureLevel {
  basic,    // Name, district, ratings, trust score
  partial,  // + Phone number, approximate location (5km radius)
  full,     // + Complete farm details, exact location, all contact info
}

enum PaymentStatus {
  none,
  advance,
  confirmed,
}

class PrivacySettings {
  final String userId;
  final DisclosureLevel disclosureLevel;
  final List<String> visibleFields;
  final bool autoUpgradeOnPayment;
  final DateTime updatedAt;

  PrivacySettings({
    required this.userId,
    required this.disclosureLevel,
    required this.visibleFields,
    required this.autoUpgradeOnPayment,
    required this.updatedAt,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      userId: json['user_id'],
      disclosureLevel: DisclosureLevel.values.firstWhere(
        (l) => l.name == json['disclosure_level'],
      ),
      visibleFields: List<String>.from(json['visible_fields'] ?? []),
      autoUpgradeOnPayment: json['auto_upgrade_on_payment'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'disclosure_level': disclosureLevel.name,
      'visible_fields': visibleFields,
      'auto_upgrade_on_payment': autoUpgradeOnPayment,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class FilteredUserProfile {
  final String userId;
  final Map<String, dynamic> visibleData;
  final DisclosureLevel appliedLevel;
  final List<String> hiddenFields;
  final String? upgradeMessage;

  FilteredUserProfile({
    required this.userId,
    required this.visibleData,
    required this.appliedLevel,
    required this.hiddenFields,
    this.upgradeMessage,
  });

  factory FilteredUserProfile.fromJson(Map<String, dynamic> json) {
    return FilteredUserProfile(
      userId: json['user_id'],
      visibleData: json['visible_data'] ?? {},
      appliedLevel: DisclosureLevel.values.firstWhere(
        (l) => l.name == json['applied_level'],
      ),
      hiddenFields: List<String>.from(json['hidden_fields'] ?? []),
      upgradeMessage: json['upgrade_message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'visible_data': visibleData,
      'applied_level': appliedLevel.name,
      'hidden_fields': hiddenFields,
      'upgrade_message': upgradeMessage,
    };
  }
}

class PrivacyService {
  static final PrivacyService _instance = PrivacyService._internal();
  factory PrivacyService() => _instance;
  PrivacyService._internal();

  static const Map<DisclosureLevel, List<String>> VISIBLE_FIELDS = {
    DisclosureLevel.basic: [
      'name', 
      'district', 
      'rating', 
      'trust_score',
      'profile_image',
      'role',
      'created_at',
    ],
    DisclosureLevel.partial: [
      'name', 
      'district', 
      'rating', 
      'trust_score',
      'profile_image',
      'role',
      'created_at',
      'phone', 
      'approximate_location',
      'city',
      'state',
    ],
    DisclosureLevel.full: [
      'name', 
      'district', 
      'rating', 
      'trust_score',
      'profile_image',
      'role',
      'created_at',
      'phone', 
      'exact_location',
      'address',
      'village',
      'city',
      'state',
      'email',
      'farm_details',
      'contact_info',
      'latitude',
      'longitude',
    ],
  };

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, PrivacySettings> _settingsCache = {};

  /// Get filtered user profile based on payment status
  Future<FilteredUserProfile> getFilteredProfile(
    String userId, 
    PaymentStatus paymentStatus,
    {String? requesterId}
  ) async {
    try {
      // Get user data
      final userData = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      // Determine disclosure level based on payment status
      final disclosureLevel = _getDisclosureLevelForPayment(paymentStatus);

      // Apply privacy filter
      final filteredData = await applyPrivacyFilter(userData, disclosureLevel);

      // Generate upgrade message if applicable
      final upgradeMessage = _getUpgradeMessage(paymentStatus, disclosureLevel);

      // Get hidden fields
      final allFields = userData.keys.toList();
      final visibleFields = VISIBLE_FIELDS[disclosureLevel]!;
      final hiddenFields = allFields.where((field) => !visibleFields.contains(field)).toList();

      // Log privacy access for audit
      if (requesterId != null) {
        await _logPrivacyAccess(requesterId, userId, disclosureLevel);
      }

      return FilteredUserProfile(
        userId: userId,
        visibleData: filteredData,
        appliedLevel: disclosureLevel,
        hiddenFields: hiddenFields,
        upgradeMessage: upgradeMessage,
      );
    } catch (e) {
      debugPrint('Failed to get filtered profile: $e');
      rethrow;
    }
  }

  /// Apply privacy filter to user data
  Future<Map<String, dynamic>> applyPrivacyFilter(
    Map<String, dynamic> userData, 
    DisclosureLevel level
  ) async {
    final visibleFields = VISIBLE_FIELDS[level]!;
    final filteredData = <String, dynamic>{};

    for (final field in visibleFields) {
      switch (field) {
        case 'name':
          filteredData['name'] = userData['name'];
          break;
        case 'district':
          filteredData['district'] = userData['district'];
          break;
        case 'rating':
          filteredData['rating'] = userData['rating'] ?? 0.0;
          break;
        case 'trust_score':
          // Get trust score from TrustService
          try {
            final trustService = TrustService();
            final trustScore = await trustService.calculateTrustScore(userData['id']);
            filteredData['trust_score'] = trustScore.score;
            filteredData['trust_level'] = trustScore.trustLevel;
          } catch (e) {
            filteredData['trust_score'] = 0.0;
            filteredData['trust_level'] = 'Building Trust';
          }
          break;
        case 'profile_image':
          filteredData['profile_image'] = userData['profile_image'];
          break;
        case 'role':
          filteredData['role'] = userData['role'];
          break;
        case 'created_at':
          filteredData['created_at'] = userData['created_at'];
          break;
        case 'phone':
          filteredData['phone'] = _maskPhoneNumber(userData['phone']);
          break;
        case 'approximate_location':
          filteredData['approximate_location'] = _getApproximateLocation(
            userData['latitude'], 
            userData['longitude']
          );
          break;
        case 'city':
          filteredData['city'] = userData['city'];
          break;
        case 'state':
          filteredData['state'] = userData['state'];
          break;
        case 'exact_location':
          filteredData['latitude'] = userData['latitude'];
          filteredData['longitude'] = userData['longitude'];
          break;
        case 'address':
          filteredData['address'] = userData['address'];
          break;
        case 'village':
          filteredData['village'] = userData['village'];
          break;
        case 'email':
          filteredData['email'] = userData['email'];
          break;
        case 'farm_details':
          filteredData['farm_name'] = userData['farm_name'];
          filteredData['farm_size'] = userData['farm_size'];
          filteredData['crop_types'] = userData['crop_types'];
          break;
        case 'contact_info':
          filteredData['whatsapp'] = userData['whatsapp'];
          filteredData['telegram'] = userData['telegram'];
          break;
      }
    }

    return filteredData;
  }

  /// Update disclosure level for user
  Future<void> updateDisclosureLevel(String userId, DisclosureLevel level) async {
    try {
      await _supabase.from('privacy_settings').upsert({
        'user_id': userId,
        'disclosure_level': level.name,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Clear cache
      _settingsCache.remove(userId);
    } catch (e) {
      debugPrint('Failed to update disclosure level: $e');
      rethrow;
    }
  }

  /// Get privacy settings for user
  Future<PrivacySettings> getPrivacySettings(String userId) async {
    try {
      // Check cache first
      if (_settingsCache.containsKey(userId)) {
        return _settingsCache[userId]!;
      }

      final settings = await _supabase
          .from('privacy_settings')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      PrivacySettings privacySettings;
      if (settings == null) {
        // Create default settings
        privacySettings = PrivacySettings(
          userId: userId,
          disclosureLevel: DisclosureLevel.basic,
          visibleFields: VISIBLE_FIELDS[DisclosureLevel.basic]!,
          autoUpgradeOnPayment: true,
          updatedAt: DateTime.now(),
        );

        await _supabase.from('privacy_settings').insert(privacySettings.toJson());
      } else {
        privacySettings = PrivacySettings.fromJson(settings);
      }

      // Cache the result
      _settingsCache[userId] = privacySettings;
      return privacySettings;
    } catch (e) {
      debugPrint('Failed to get privacy settings: $e');
      
      // Return default settings on error
      return PrivacySettings(
        userId: userId,
        disclosureLevel: DisclosureLevel.basic,
        visibleFields: VISIBLE_FIELDS[DisclosureLevel.basic]!,
        autoUpgradeOnPayment: true,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Handle payment status change and update disclosure
  Future<void> handlePaymentStatusChange(
    String customerId,
    String farmerId,
    String orderId,
    PaymentStatus oldStatus,
    PaymentStatus newStatus,
  ) async {
    try {
      final newDisclosureLevel = _getDisclosureLevelForPayment(newStatus);

      // Log the payment status change
      await _supabase.from('payment_status_log').insert({
        'order_id': orderId,
        'customer_id': customerId,
        'farmer_id': farmerId,
        'old_status': oldStatus.name,
        'new_status': newStatus.name,
        'disclosure_level_granted': newDisclosureLevel.name,
      });

      // Notify customer about new access level
      if (newStatus != PaymentStatus.none) {
        await _notifyDisclosureUpgrade(customerId, farmerId, newDisclosureLevel);
      }
    } catch (e) {
      debugPrint('Failed to handle payment status change: $e');
    }
  }

  /// Check if user can access specific field
  Future<bool> canAccessField(
    String requesterId,
    String targetUserId,
    String fieldName,
    PaymentStatus paymentStatus,
  ) async {
    try {
      final disclosureLevel = _getDisclosureLevelForPayment(paymentStatus);
      final visibleFields = VISIBLE_FIELDS[disclosureLevel]!;
      
      return visibleFields.contains(fieldName);
    } catch (e) {
      debugPrint('Failed to check field access: $e');
      return false;
    }
  }

  /// Get users with specific disclosure level
  Future<List<String>> getUsersWithDisclosureLevel(DisclosureLevel level) async {
    try {
      final users = await _supabase
          .from('privacy_settings')
          .select('user_id')
          .eq('disclosure_level', level.name);

      return users.map((u) => u['user_id'] as String).toList();
    } catch (e) {
      debugPrint('Failed to get users with disclosure level: $e');
      return [];
    }
  }

  /// Bulk update disclosure levels
  Future<void> bulkUpdateDisclosureLevel(
    List<String> userIds,
    DisclosureLevel level,
    String reason,
  ) async {
    try {
      for (final userId in userIds) {
        await updateDisclosureLevel(userId, level);
      }

      // Log bulk action
      await _supabase.from('admin_actions').insert({
        'admin_id': SupabaseService.currentUserId,
        'action_type': 'bulk_privacy_update',
        'action_data': {
          'user_ids': userIds,
          'new_level': level.name,
          'count': userIds.length,
        },
        'reason': reason,
      });
    } catch (e) {
      debugPrint('Failed to bulk update disclosure levels: $e');
      rethrow;
    }
  }

  // Private helper methods

  DisclosureLevel _getDisclosureLevelForPayment(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.none:
        return DisclosureLevel.basic;
      case PaymentStatus.advance:
        return DisclosureLevel.partial;
      case PaymentStatus.confirmed:
        return DisclosureLevel.full;
    }
  }

  String? _getUpgradeMessage(PaymentStatus paymentStatus, DisclosureLevel level) {
    switch (level) {
      case DisclosureLevel.basic:
        return "Make an advance payment to unlock phone number and location details.";
      case DisclosureLevel.partial:
        return "Confirm your order to unlock complete farm details and contact information.";
      case DisclosureLevel.full:
        return null; // No upgrade message for full access
    }
  }

  String _maskPhoneNumber(String? phone) {
    if (phone == null || phone.length < 6) return phone ?? '';
    
    final start = phone.substring(0, 3);
    final end = phone.substring(phone.length - 2);
    final middle = '*' * (phone.length - 5);
    
    return '$start$middle$end';
  }

  Map<String, dynamic> _getApproximateLocation(double? lat, double? lng) {
    if (lat == null || lng == null) {
      return {
        'message': 'Location not available',
        'radius_km': 0,
      };
    }

    // Add random offset within 5km radius
    final random = Random();
    final offsetLat = (random.nextDouble() - 0.5) * 0.09; // ~5km
    final offsetLng = (random.nextDouble() - 0.5) * 0.09;

    return {
      'approximate_latitude': lat + offsetLat,
      'approximate_longitude': lng + offsetLng,
      'radius_km': 5.0,
      'message': 'Location shown within 5km radius for privacy',
    };
  }

  Future<void> _logPrivacyAccess(
    String requesterId,
    String targetUserId,
    DisclosureLevel level,
  ) async {
    try {
      await _supabase.from('user_activity').insert({
        'user_id': requesterId,
        'activity_type': 'privacy_access',
        'activity_data': {
          'target_user_id': targetUserId,
          'disclosure_level': level.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (e) {
      debugPrint('Failed to log privacy access: $e');
    }
  }

  Future<void> _notifyDisclosureUpgrade(
    String customerId,
    String farmerId,
    DisclosureLevel newLevel,
  ) async {
    try {
      String message;
      switch (newLevel) {
        case DisclosureLevel.partial:
          message = "You can now view the farmer's phone number and approximate location.";
          break;
        case DisclosureLevel.full:
          message = "You now have access to complete farm details and contact information.";
          break;
        default:
          return;
      }

      await _supabase.from('notifications').insert({
        'user_id': customerId,
        'title': 'New Information Unlocked',
        'message': message,
        'type': 'privacy_upgrade',
        'data': {
          'farmer_id': farmerId,
          'disclosure_level': newLevel.name,
        },
      });
    } catch (e) {
      debugPrint('Failed to notify disclosure upgrade: $e');
    }
  }

  /// Clear cache for user
  void clearCache(String userId) {
    _settingsCache.remove(userId);
  }

  /// Clear all cache
  void clearAllCache() {
    _settingsCache.clear();
  }
}

