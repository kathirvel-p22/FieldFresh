import 'package:flutter/material.dart';
import '../generated/l10n.dart';

/// Helper class to safely access localization strings with fallbacks
class LocalizationHelper {
  static String getText(BuildContext context, String key) {
    try {
      final s = S.of(context);
      if (s == null) return _getEnglishFallback(key);
      
      switch (key) {
        // Auth & General
        case 'phoneVerified':
          return s.phoneVerified;
        case 'verificationSuccessful':
          return s.verificationSuccessful;
        case 'invalidOtp':
          return s.invalidOtp;
        case 'verificationFailed':
          return s.verificationFailed;
        case 'otpResentSuccessfully':
          return s.otpResentSuccessfully;
        case 'failedToResendOtp':
          return s.failedToResendOtp;
        case 'createAccount':
          return s.createAccount;
        case 'verifyCreateAccount':
          return s.verifyCreateAccount;
        case 'weSentVerificationCode':
          return s.weSentVerificationCode;
        case 'verifyingYourCode':
          return s.verifyingYourCode;
        case 'didntReceiveCode':
          return s.didntReceiveCode;
        case 'resendOtp':
          return s.resendOtp;
        case 'changePhoneNumber':
          return s.changePhoneNumber;
        case 'afterVerificationComplete':
          return s.afterVerificationComplete;
        
        // Navigation
        case 'dashboard':
          return s.dashboard;
        case 'post':
          return s.post;
        case 'orders':
          return s.orders;
        case 'wallet':
          return s.wallet;
        case 'community':
          return s.community;
        case 'profile':
          return s.profile;
        case 'market':
          return s.market;
        case 'farmers':
          return s.farmers;
        case 'groupBuy':
          return s.groupBuy;
        case 'alerts':
          return s.alerts;
        
        // App Control
        case 'exitApp':
          return s.exitApp;
        case 'exitAppMessage':
          return s.exitAppMessage;
        case 'cancel':
          return s.cancel;
        case 'exit':
          return s.exit;
        
        // Dashboard
        case 'goodMorning':
          return s.goodMorning;
        case 'farmerDashboard':
          return s.farmerDashboard;
        case 'marketIsLive':
          return s.marketIsLive;
        case 'goLive':
          return s.goLive;
        case 'activeListings':
          return s.activeListings;
        case 'totalOrders':
          return s.totalOrders;
        case 'pendingOrders':
          return s.pendingOrders;
        case 'revenue':
          return s.revenue;
        case 'quickActions':
          return s.quickActions;
        case 'postHarvest':
          return s.postHarvest;
        case 'analytics':
          return s.analytics;
        case 'liveOrders':
          return s.liveOrders;
        case 'noOrdersYet':
          return s.noOrdersYet;
        
        // Product Posting
        case 'addProductPhoto':
          return s.addProductPhoto;
        case 'takePhoto':
          return s.takePhoto;
        case 'captureFreshProductImage':
          return s.captureFreshProductImage;
        case 'chooseFromGallery':
          return s.chooseFromGallery;
        case 'selectExistingPhotos':
          return s.selectExistingPhotos;
        case 'productName':
          return s.productName;
        case 'price':
          return s.price;
        case 'validPrice':
          return s.validPrice;
        case 'availableQuantity':
          return s.availableQuantity;
        case 'validQuantity':
          return s.validQuantity;
        case 'productPhoto':
          return s.productPhoto;
        case 'userLogin':
          return s.userLogin;
        case 'farmLocation':
          return s.farmLocation;
        case 'missingRequiredFields':
          return s.missingRequiredFields;
        case 'gettingLocation':
          return s.gettingLocation;
        case 'locationRequired':
          return s.locationRequired;
        case 'harvestPosted':
          return s.harvestPosted;
        case 'errorPostingProduct':
          return s.errorPostingProduct;
        case 'dismiss':
          return s.dismiss;
        case 'postTodaysHarvest':
          return s.postTodaysHarvest;
        case 'addProductPhotos':
          return s.addProductPhotos;
        case 'cameraOrGallery':
          return s.cameraOrGallery;
        case 'category':
          return s.category;
        case 'searchCategories':
          return s.searchCategories;
        case 'egFreshTomatoes':
          return s.egFreshTomatoes;
        case 'required':
          return s.required;
        case 'enterValidPrice':
          return s.enterValidPrice;
        case 'mustBeGreaterThanZero':
          return s.mustBeGreaterThanZero;
        case 'unit':
          return s.unit;
        case 'enterValidNumber':
          return s.enterValidNumber;
        case 'descriptionOptional':
          return s.descriptionOptional;
        case 'tellCustomersAboutProduce':
          return s.tellCustomersAboutProduce;
        case 'farmLocationDetected':
          return s.farmLocationDetected;
        case 'detectingFarmLocation':
          return s.detectingFarmLocation;
        case 'retry':
          return s.retry;
        case 'priceRupees':
          return s.priceRupees;
        
        // Orders & Status
        case 'all':
          return s.all;
        case 'pending':
          return s.pending;
        case 'confirmed':
          return s.confirmed;
        case 'packed':
          return s.packed;
        case 'dispatched':
          return s.dispatched;
        case 'delivered':
          return s.delivered;
        case 'cancelled':
          return s.cancelled;
        case 'customerOrders':
          return s.customerOrders;
        case 'ordersWillAppear':
          return s.ordersWillAppear;
        case 'loadingCustomerInfo':
          return s.loadingCustomerInfo;
        case 'quantity':
          return s.quantity;
        case 'total':
          return s.total;
        case 'decline':
          return s.decline;
        case 'accept':
          return s.accept;
        case 'markAsPacked':
          return s.markAsPacked;
        case 'markAsDispatched':
          return s.markAsDispatched;
        case 'markAsDelivered':
          return s.markAsDelivered;
        
        // Profile
        case 'updateProfilePhoto':
          return s.updateProfilePhoto;
        case 'chooseFromGalleryProfile':
          return s.chooseFromGalleryProfile;
        case 'removePhoto':
          return s.removePhoto;
        case 'signOut':
          return s.signOut;
        case 'locationNotSet':
          return s.locationNotSet;
        case 'active':
          return s.active;
        case 'viewManageOrders':
          return s.viewManageOrders;
        case 'allCustomers':
          return s.allCustomers;
        case 'viewCustomerProfiles':
          return s.viewCustomerProfiles;
        case 'salesAnalytics':
          return s.salesAnalytics;
        case 'viewPerformanceCharts':
          return s.viewPerformanceCharts;
        case 'myListings':
          return s.myListings;
        case 'manageAllProducts':
          return s.manageAllProducts;
        case 'customerReviews':
          return s.customerReviews;
        case 'seeWhatCustomersSay':
          return s.seeWhatCustomersSay;
        case 'bankUpiSettings':
          return s.bankUpiSettings;
        case 'managePayoutMethods':
          return s.managePayoutMethods;
        case 'kycDocuments':
          return s.kycDocuments;
        case 'helpSupport':
          return s.helpSupport;
        case 'chatWithOurTeam':
          return s.chatWithOurTeam;
        case 'notificationPreferences':
          return s.notificationPreferences;
        case 'alertsHarvestBlasts':
          return s.alertsHarvestBlasts;
        case 'savedFarmers':
          return s.savedFarmers;
        case 'yourFavouriteFarms':
          return s.yourFavouriteFarms;
        case 'deliveryAddresses':
          return s.deliveryAddresses;
        case 'manageSavedAddresses':
          return s.manageSavedAddresses;
        case 'language':
          return s.language;
        case 'tamilHindiEnglish':
          return s.tamilHindiEnglish;
        case 'languageSettingsComingSoon':
          return s.languageSettingsComingSoon;
        
        // Customer Feed
        case 'freshMarket':
          return s.freshMarket + ' 🌾';
        case 'searchVegetablesFruits':
          return s.searchVegetablesFruits;
        case 'noFreshProduceNearby':
          return s.noFreshProduceNearby;
        case 'checkBackSoon':
          return s.checkBackSoon;
        case 'expired':
          return s.expired;
        case 'orderNow':
          return s.orderNow;
        
        default:
          return key;
      }
    } catch (e) {
      // Fallback to English if localization fails
      return _getEnglishFallback(key);
    }
  }
  
  static String getTextWithParams(BuildContext context, String key, {int? seconds, int? hours, String? category}) {
    try {
      final s = S.of(context);
      if (s == null) return _getEnglishFallbackWithParams(key, seconds: seconds, hours: hours, category: category);
      
      switch (key) {
        case 'resendInSeconds':
          return s.resendInSeconds(seconds ?? 0);
        case 'validForHours':
          return s.validForHours(hours ?? 0);
        case 'aiSuggestionText':
          return s.aiSuggestionText(category ?? '', hours ?? 0);
        case 'expiresAt':
          return s.expiresAt(category ?? '');
        case 'noStatusOrders':
          return s.noStatusOrders(category ?? '');
        default:
          return key;
      }
    } catch (e) {
      return _getEnglishFallbackWithParams(key, seconds: seconds, hours: hours, category: category);
    }
  }
  
  static String _getEnglishFallback(String key) {
    switch (key) {
      // Auth & General
      case 'phoneVerified':
        return 'Phone verified! Creating your account...';
      case 'verificationSuccessful':
        return 'Verification successful!';
      case 'invalidOtp':
        return 'Invalid OTP. Please try again.';
      case 'verificationFailed':
        return 'Verification failed';
      case 'otpResentSuccessfully':
        return 'OTP resent successfully!';
      case 'failedToResendOtp':
        return 'Failed to resend OTP';
      case 'createAccount':
        return 'Create Account';
      case 'verifyCreateAccount':
        return 'Verify & Create Account';
      case 'weSentVerificationCode':
        return 'We sent a 6-digit verification code to';
      case 'verifyingYourCode':
        return 'Verifying your code...';
      case 'didntReceiveCode':
        return 'Didn\'t receive the code? ';
      case 'resendOtp':
        return 'Resend OTP';
      case 'changePhoneNumber':
        return 'Change phone number';
      case 'afterVerificationComplete':
        return 'After verification, you\'ll complete your profile setup to start using FieldFresh.';
      
      // Navigation
      case 'dashboard':
        return 'Dashboard';
      case 'post':
        return 'Post';
      case 'orders':
        return 'Orders';
      case 'wallet':
        return 'Wallet';
      case 'community':
        return 'Community';
      case 'profile':
        return 'Profile';
      case 'market':
        return 'Market';
      case 'farmers':
        return 'Farmers';
      case 'groupBuy':
        return 'Group Buy';
      case 'alerts':
        return 'Alerts';
      
      // App Control
      case 'exitApp':
        return 'Exit App';
      case 'exitAppMessage':
        return 'Do you want to exit FieldFresh?';
      case 'cancel':
        return 'Cancel';
      case 'exit':
        return 'Exit';
      
      // Dashboard
      case 'goodMorning':
        return 'Good Morning';
      case 'farmerDashboard':
        return 'Farmer Dashboard';
      case 'marketIsLive':
        return 'Market is live!';
      case 'goLive':
        return 'Go Live';
      case 'activeListings':
        return 'Active Listings';
      case 'totalOrders':
        return 'Total Orders';
      case 'pendingOrders':
        return 'Pending Orders';
      case 'revenue':
        return 'Revenue';
      case 'quickActions':
        return 'Quick Actions';
      case 'postHarvest':
        return 'Post Harvest';
      case 'analytics':
        return 'Analytics';
      case 'liveOrders':
        return 'Live Orders';
      case 'noOrdersYet':
        return 'No orders yet';
      
      // Customer Feed
      case 'freshMarket':
        return 'Fresh Market 🌾';
      case 'searchVegetablesFruits':
        return 'Search vegetables, fruits...';
      case 'noFreshProduceNearby':
        return 'No fresh produce nearby right now';
      case 'checkBackSoon':
        return 'Check back soon!';
      case 'expired':
        return 'Expired';
      case 'orderNow':
        return 'Order Now';
      
      // Orders & Status
      case 'all':
        return 'All';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'packed':
        return 'Packed';
      case 'dispatched':
        return 'Dispatched';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'customerOrders':
        return 'Customer Orders';
      case 'ordersWillAppear':
        return 'Orders will appear here when customers buy your products';
      case 'loadingCustomerInfo':
        return 'Loading customer info...';
      case 'quantity':
        return 'Quantity';
      case 'total':
        return 'Total';
      case 'decline':
        return 'Decline';
      case 'accept':
        return 'Accept';
      case 'markAsPacked':
        return 'Mark as Packed';
      case 'markAsDispatched':
        return 'Mark as Dispatched';
      case 'markAsDelivered':
        return 'Mark as Delivered';
      
      // Profile
      case 'signOut':
        return 'Sign Out';
      case 'helpSupport':
        return 'Help & Support';
      case 'chatWithOurTeam':
        return 'Chat with our team';
      case 'kycDocuments':
        return 'KYC Documents';
      
      default:
        return key;
    }
  }
  
  static String _getEnglishFallbackWithParams(String key, {int? seconds, int? hours, String? category}) {
    switch (key) {
      case 'resendInSeconds':
        return 'Resend in ${seconds ?? 0}s';
      case 'validForHours':
        return 'Valid for ${hours ?? 0} hours';
      case 'aiSuggestionText':
        return 'AI suggestion for \'${category ?? ''}\': ${hours ?? 0} hrs';
      case 'expiresAt':
        return 'Expires: ${category ?? ''}';
      case 'noStatusOrders':
        return 'No ${category ?? ''} orders';
      default:
        return key;
    }
  }
}