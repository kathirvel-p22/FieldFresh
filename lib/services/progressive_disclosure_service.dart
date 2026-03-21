import 'verification_service.dart';

enum DisclosureLevel {
  basic,    // Only name and rating
  partial,  // + masked phone, approximate location
  full,     // + exact location, full contact details
}

class ProgressiveDisclosureService {
  /// Determine what information customer can see about farmer based on order status and verification
  static Future<DisclosureLevel> getCustomerDisclosureLevel(
    String orderStatus, 
    String farmerId,
  ) async {
    // Check farmer's verification status
    final isVerified = await VerificationService().isUserFullyVerified(farmerId);
    
    // Base disclosure level from order status
    DisclosureLevel baseLevel;
    switch (orderStatus) {
      case 'pending':
      case 'confirmed':
        baseLevel = DisclosureLevel.basic; // Only name and rating
        break;
      case 'packed':
        baseLevel = DisclosureLevel.partial; // + masked phone, city
        break;
      case 'dispatched':
      case 'delivered':
        baseLevel = DisclosureLevel.full; // + exact location, full contact
        break;
      default:
        baseLevel = DisclosureLevel.basic;
    }
    
    // Reduce disclosure level if farmer is not verified
    if (!isVerified && baseLevel == DisclosureLevel.full) {
      return DisclosureLevel.partial;
    }
    
    return baseLevel;
  }

  /// Determine what information farmer can see about customer based on order status and verification
  static Future<DisclosureLevel> getFarmerDisclosureLevel(
    String orderStatus,
    String customerId,
  ) async {
    // Check customer's verification status
    final isVerified = await VerificationService().isUserFullyVerified(customerId);
    
    // Base disclosure level from order status
    DisclosureLevel baseLevel;
    switch (orderStatus) {
      case 'pending':
        baseLevel = DisclosureLevel.basic; // Only name
        break;
      case 'confirmed':
      case 'packed':
      case 'dispatched':
      case 'delivered':
        baseLevel = DisclosureLevel.full; // Full contact details after confirmation
        break;
      default:
        baseLevel = DisclosureLevel.basic;
    }
    
    // Reduce disclosure level if customer is not verified
    if (!isVerified && baseLevel == DisclosureLevel.full) {
      return DisclosureLevel.partial;
    }
    
    return baseLevel;
  }

  /// Filter farmer information based on disclosure level and verification status
  static Future<Map<String, dynamic>> filterFarmerInfo(
    Map<String, dynamic> farmerData,
    String orderStatus,
  ) async {
    final level = await getCustomerDisclosureLevel(orderStatus, farmerData['id']);
    final isVerified = await VerificationService().isUserFullyVerified(farmerData['id']);
    
    final filtered = <String, dynamic>{
      'id': farmerData['id'],
      'name': farmerData['name'],
      'rating': farmerData['rating'],
      'profile_image': farmerData['profile_image'],
      'is_verified': isVerified,
    };

    switch (level) {
      case DisclosureLevel.basic:
        // Only basic info (name, rating, image, verification status)
        break;
        
      case DisclosureLevel.partial:
        // Add masked phone and city
        if (farmerData['phone'] != null) {
          filtered['phone'] = _maskPhone(farmerData['phone']);
        }
        if (farmerData['address'] != null) {
          filtered['city'] = _extractCity(farmerData['address']);
        }
        break;
        
      case DisclosureLevel.full:
        // Add all information
        filtered['phone'] = farmerData['phone'];
        filtered['address'] = farmerData['address'];
        filtered['latitude'] = farmerData['latitude'];
        filtered['longitude'] = farmerData['longitude'];
        break;
    }

    return filtered;
  }

  /// Filter customer information based on disclosure level and verification status
  static Future<Map<String, dynamic>> filterCustomerInfo(
    Map<String, dynamic> customerData,
    String orderStatus,
  ) async {
    final level = await getFarmerDisclosureLevel(orderStatus, customerData['id']);
    final isVerified = await VerificationService().isUserFullyVerified(customerData['id']);
    
    final filtered = <String, dynamic>{
      'id': customerData['id'],
      'name': customerData['name'],
      'profile_image': customerData['profile_image'],
      'is_verified': isVerified,
    };

    switch (level) {
      case DisclosureLevel.basic:
        // Only basic info (name, image, verification status)
        break;
        
      case DisclosureLevel.partial:
        // Add masked phone
        if (customerData['phone'] != null) {
          filtered['phone'] = _maskPhone(customerData['phone']);
        }
        break;
        
      case DisclosureLevel.full:
        // Add all information
        filtered['phone'] = customerData['phone'];
        filtered['address'] = customerData['address'];
        break;
    }

    return filtered;
  }

  /// Mask phone number for privacy
  static String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    
    // For +91XXXXXXXXXX format, show +91XXXX***XXX
    if (phone.startsWith('+91') && phone.length >= 13) {
      return '${phone.substring(0, 6)}***${phone.substring(phone.length - 3)}';
    }
    
    // For 10-digit numbers, show XXXX***XXX
    if (phone.length == 10) {
      return '${phone.substring(0, 4)}***${phone.substring(7)}';
    }
    
    // Generic masking
    final visibleStart = (phone.length * 0.3).round();
    final visibleEnd = (phone.length * 0.2).round();
    final masked = '*' * (phone.length - visibleStart - visibleEnd);
    
    return '${phone.substring(0, visibleStart)}$masked${phone.substring(phone.length - visibleEnd)}';
  }

  /// Extract city from full address
  static String _extractCity(String address) {
    // Simple city extraction - you can make this more sophisticated
    final parts = address.split(',');
    if (parts.length >= 2) {
      // Usually city is the second-to-last part
      return parts[parts.length - 2].trim();
    }
    return address.split(' ').first; // Fallback to first word
  }

  /// Get disclosure message for customers with verification context
  static Future<String> getCustomerDisclosureMessage(String orderStatus, String farmerId) async {
    final level = await getCustomerDisclosureLevel(orderStatus, farmerId);
    final isVerified = await VerificationService().isUserFullyVerified(farmerId);
    
    switch (level) {
      case DisclosureLevel.basic:
        return isVerified 
          ? '🔒 Full farmer details will be revealed when order is packed'
          : '⚠️ Farmer verification pending. Limited details available.';
      case DisclosureLevel.partial:
        return isVerified
          ? '📦 Order is being packed! More details available when dispatched'
          : '⚠️ Farmer not fully verified. Limited contact available.';
      case DisclosureLevel.full:
        return isVerified
          ? '✅ Full farmer contact details available'
          : '⚠️ Farmer verification incomplete. Contact with caution.';
    }
  }

  /// Get disclosure message for farmers with verification context
  static Future<String> getFarmerDisclosureMessage(String orderStatus, String customerId) async {
    final level = await getFarmerDisclosureLevel(orderStatus, customerId);
    final isVerified = await VerificationService().isUserFullyVerified(customerId);
    
    switch (level) {
      case DisclosureLevel.basic:
        return isVerified
          ? '🔒 Customer contact details will be revealed when you confirm the order'
          : '⚠️ Customer verification pending. Limited details available.';
      case DisclosureLevel.partial:
        return isVerified
          ? '📞 Partial customer details available'
          : '⚠️ Customer not fully verified. Limited contact available.';
      case DisclosureLevel.full:
        return isVerified
          ? '✅ Full customer contact details available'
          : '⚠️ Customer verification incomplete. Contact with caution.';
    }
  }

  /// Check if location should be shown to customer with verification check
  static Future<bool> shouldShowFarmerLocation(String orderStatus, String farmerId) async {
    final level = await getCustomerDisclosureLevel(orderStatus, farmerId);
    final isVerified = await VerificationService().isUserFullyVerified(farmerId);
    return level == DisclosureLevel.full && isVerified;
  }

  /// Check if phone should be clickable with verification check
  static Future<bool> shouldAllowPhoneCall(
    String orderStatus, 
    String userId, {
    bool isCustomer = true
  }) async {
    if (isCustomer) {
      final level = await getCustomerDisclosureLevel(orderStatus, userId);
      final isVerified = await VerificationService().isUserFullyVerified(userId);
      return level == DisclosureLevel.full && isVerified;
    } else {
      final level = await getFarmerDisclosureLevel(orderStatus, userId);
      final isVerified = await VerificationService().isUserFullyVerified(userId);
      return level == DisclosureLevel.full && isVerified;
    }
  }

  /// Get appropriate contact button text with verification context
  static Future<String> getContactButtonText(
    String orderStatus, 
    String userId, {
    bool isCustomer = true
  }) async {
    final isVerified = await VerificationService().isUserFullyVerified(userId);
    
    if (isCustomer) {
      final level = await getCustomerDisclosureLevel(orderStatus, userId);
      switch (level) {
        case DisclosureLevel.basic:
          return 'Contact Available After Packing';
        case DisclosureLevel.partial:
          return isVerified ? 'Limited Contact Available' : 'Verification Required';
        case DisclosureLevel.full:
          return isVerified ? 'Call Farmer' : 'Farmer Not Verified';
      }
    } else {
      final level = await getFarmerDisclosureLevel(orderStatus, userId);
      switch (level) {
        case DisclosureLevel.basic:
          return 'Contact Available After Confirmation';
        case DisclosureLevel.partial:
          return isVerified ? 'Limited Contact Available' : 'Verification Required';
        case DisclosureLevel.full:
          return isVerified ? 'Call Customer' : 'Customer Not Verified';
      }
    }
  }
}