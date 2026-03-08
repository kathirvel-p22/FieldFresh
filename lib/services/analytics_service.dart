import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;
  static final _supabase = Supabase.instance.client;

  // Track screen views
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Track product views
  static Future<void> logProductView(String productId, String productName, double price) async {
    await _analytics.logViewItem(
      currency: 'INR',
      value: price,
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          price: price,
        ),
      ],
    );
  }

  // Track product posts
  static Future<void> logProductPost(String farmerId, String category, double price) async {
    await _analytics.logEvent(
      name: 'product_posted',
      parameters: {
        'farmer_id': farmerId,
        'category': category,
        'price': price,
      },
    );
  }

  // Track orders
  static Future<void> logPurchase(String orderId, double amount, int itemCount) async {
    await _analytics.logPurchase(
      currency: 'INR',
      value: amount,
      transactionId: orderId,
    );
  }

  // Track search
  static Future<void> logSearch(String searchTerm, String category) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
      parameters: {'category': category},
    );
  }

  // Track user engagement
  static Future<void> logUserEngagement(String action, Map<String, dynamic> params) async {
    await _analytics.logEvent(name: action, parameters: params);
  }

  // Save analytics to database for admin dashboard
  static Future<void> saveToDatabase(String eventType, Map<String, dynamic> data) async {
    try {
      await _supabase.from('analytics_events').insert({
        'event_type': eventType,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }

  // Track app opens
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Set user properties
  static Future<void> setUserProperties(String userId, String role) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }
}
