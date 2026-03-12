import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';
import '../core/constants.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static String? _demoUserId; // Store user ID for demo mode
  static const String _userIdKey = 'demo_user_id';

  static Future<void> initialize() async {
    await Supabase.initialize(
        url: AppStrings.supabaseUrl, anonKey: AppStrings.supabaseAnonKey);
    
    // Load saved demo user ID from Hive
    try {
      final box = await Hive.openBox('auth');
      _demoUserId = box.get(_userIdKey);
      if (_demoUserId != null) {
        print('Loaded demo user ID from storage: $_demoUserId');
      }
    } catch (e) {
      print('Error loading demo user ID: $e');
    }
  }

  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId {
    final userId = _demoUserId ?? _client.auth.currentUser?.id;
    print('Getting current user ID: $userId (demo: $_demoUserId, auth: ${_client.auth.currentUser?.id})');
    return userId;
  }

  static Future<void> setDemoUserId(String userId) async {
    _demoUserId = userId;
    print('Setting demo user ID: $userId');
    
    // Persist to Hive
    try {
      final box = await Hive.openBox('auth');
      await box.put(_userIdKey, userId);
      print('Saved demo user ID to storage');
    } catch (e) {
      print('Error saving demo user ID: $e');
    }
  }

  static Future<void> clearDemoUserId() async {
    _demoUserId = null;
    
    // Clear from Hive
    try {
      final box = await Hive.openBox('auth');
      await box.delete(_userIdKey);
      print('Cleared demo user ID from storage');
    } catch (e) {
      print('Error clearing demo user ID: $e');
    }
  }

  static Future<void> signInWithOtp(String phone) async =>
      await _client.auth.signInWithOtp(phone: phone);
  static Future<AuthResponse> verifyOTP(String phone, String token) async =>
      await _client.auth
          .verifyOTP(phone: phone, token: token, type: OtpType.sms);
  
  static Future<void> signOut() async {
    await clearDemoUserId();
    await _client.auth.signOut();
  }

  static Future<UserModel?> getUser(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      return data != null ? UserModel.fromJson(data) : null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final data = await _client
          .from('users')
          .select(
              'id, phone, name, role, is_verified, is_kyc_done, profile_image, latitude, longitude, address, rating')
          .eq('phone', phone)
          .maybeSingle();
      return data;
    } catch (e) {
      print('Error fetching user by phone: $e');
      return null;
    }
  }

  static Future<String> createBasicUser(String phone, String role) async {
    try {
      final userId = const Uuid().v4(); // Generate a UUID
      await _client.from('users').insert({
        'id': userId,
        'phone': phone,
        'role': role,
        'is_verified': false,
        'is_kyc_done': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      return userId;
    } catch (e) {
      print('Error creating basic user: $e');
      rethrow;
    }
  }

  static Future<UserModel> upsertUser(UserModel user) async {
    final data =
        await _client.from('users').upsert(user.toJson()).select('*').single();
    return UserModel.fromJson(data);
  }

  static Future<void> updateFcmToken(String userId, String token) async =>
      await _client.from('users').update({'fcm_token': token}).eq('id', userId);

  static Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');
    
    print('DEBUG: Updating user profile for user: $userId');
    print('DEBUG: Updates: $updates');
    
    await _client.from('users').update(updates).eq('id', userId);
    
    print('DEBUG: User profile updated successfully');
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId);
  }

  static Future<List<ProductModel>> getNearbyProducts(
      {required double lat,
      required double lng,
      double radiusKm = 25,
      String? category}) async {
    var query = _client
        .from('products')
        .select('*, users(name, profile_image, rating)')
        .eq('status', 'active')
        .gt('valid_until', DateTime.now().toIso8601String())
        .gt('quantity_left', 0)
        .order('created_at', ascending: false);
    if (category != null && category != 'all') {
      query = _client
          .from('products')
          .select('*, users(name, profile_image, rating)')
          .eq('status', 'active')
          .eq('category', category)
          .gt('valid_until', DateTime.now().toIso8601String())
          .gt('quantity_left', 0)
          .order('created_at', ascending: false);
    }
    final data = await query;
    return data.map((d) => ProductModel.fromJson(d)).toList();
  }

  static Future<List<ProductModel>> getFarmerProducts(String farmerId) async {
    print('DEBUG: Fetching products for farmer: $farmerId');
    
    // Add a timestamp to prevent caching issues
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    print('DEBUG: Query timestamp: $timestamp');
    
    try {
      final data = await _client
          .from('products')
          .select('*')
          .eq('farmer_id', farmerId)
          .neq('status', 'deleted') // Exclude deleted products
          .order('created_at', ascending: false);
      
      print('DEBUG: Raw database response: ${data.length} records (excluding deleted)');
      
      final products = data.map((d) => ProductModel.fromJson(d)).toList();
      print('DEBUG: Converted to ${products.length} ProductModel objects');
      
      // Print product IDs and names for debugging
      for (final product in products) {
        print('DEBUG: DB Product: ${product.name} (ID: ${product.id}, Status: ${product.status})');
      }
      
      return products;
    } catch (e) {
      print('ERROR: Failed to fetch farmer products: $e');
      rethrow;
    }
  }

  static Future<ProductModel> postProduct(ProductModel product) async {
    try {
      print('Attempting to post product with data: ${product.toJson()}');
      
      // First, let's try with the expected new schema fields
      final newSchemaData = {
        'farmer_id': product.farmerId,
        'name': product.name,
        'category': product.category,
        'price_per_unit': product.pricePerUnit,
        'unit': product.unit,
        'quantity_total': product.quantityTotal,
        'quantity_left': product.quantityLeft,
        'status': 'active',
        'harvest_time': product.harvestTime.toIso8601String(),
        'valid_until': product.validUntil.toIso8601String(),
        'freshness_score': product.freshnessScore,
        'image_urls': product.imageUrls,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Add optional fields if they exist
      if (product.description != null) newSchemaData['description'] = product.description!;
      if (product.latitude != null) newSchemaData['latitude'] = product.latitude!;
      if (product.longitude != null) newSchemaData['longitude'] = product.longitude!;
      
      print('Trying new schema data: $newSchemaData');
      
      final data = await _client
          .from('products')
          .insert(newSchemaData)
          .select('*')
          .single();
      
      print('Product posted successfully with new schema: $data');
      return ProductModel.fromJson(data);
    } catch (e) {
      print('New schema failed, trying legacy compatibility: $e');
      
      // If new schema fails, try legacy field names that might exist
      try {
        print('Trying legacy schema compatibility...');
        final legacyData = {
          'farmer_id': product.farmerId,
          'name': product.name,
          'category': product.category,
          'price': product.pricePerUnit,  // Try 'price' instead of 'price_per_unit'
          'unit': product.unit,
          'quantity': product.quantityTotal,  // Try 'quantity' instead of 'quantity_total'
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        };
        
        final data2 = await _client
            .from('products')
            .insert(legacyData)
            .select('*')
            .single();
            
        print('Legacy schema worked: $data2');
        return ProductModel.fromJson(data2);
      } catch (e2) {
        print('Legacy schema also failed: $e2');
        
        // Try ultra-minimal to see what fields actually exist
        try {
          print('Trying ultra-minimal to discover schema...');
          final ultraMinimal = {
            'farmer_id': product.farmerId,
            'name': product.name,
          };
          
          final data3 = await _client
              .from('products')
              .insert(ultraMinimal)
              .select('*')
              .single();
              
          print('Ultra-minimal worked, current schema accepts: $data3');
          return ProductModel.fromJson(data3);
        } catch (e3) {
          print('All attempts failed. Database schema needs to be updated: $e3');
          rethrow;
        }
      }
    }
  }

  static Future<void> updateProductQuantity(
      String productId, double newQty) async {
    final status = newQty <= 0 ? 'sold_out' : 'active';
    await _client.from('products').update(
        {'quantity_left': newQty, 'status': status}).eq('id', productId);
  }

  static Future<OrderModel> placeOrder(OrderModel order) async {
    final data = await _client
        .from('orders')
        .insert(order.toJson())
        .select('*')
        .single();
    return OrderModel.fromJson(data);
  }

  static Future<List<OrderModel>> getFarmerOrders(String farmerId) async {
    final data = await _client
        .from('orders')
        .select('*')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return data.map((d) => OrderModel.fromJson(d)).toList();
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'confirmed') {
      updates['confirmed_at'] = DateTime.now().toIso8601String();
    }
    if (status == 'delivered') {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('orders').update(updates).eq('id', orderId);
  }

  static Future<void> updatePaymentStatus(
          String orderId, String paymentId) async =>
      await _client.from('orders').update({
        'payment_status': 'paid',
        'payment_id': paymentId,
        'status': 'confirmed'
      }).eq('id', orderId);

  static Stream<List<Map<String, dynamic>>> listenToFarmerOrders(
          String farmerId) =>
      _client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

  static Stream<List<Map<String, dynamic>>> listenToCustomerOrders(
          String customerId) {
    print('DEBUG: listenToCustomerOrders called with customerId: $customerId');
    
    try {
      return _client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
    } catch (e) {
      print('DEBUG: Stream failed, error: $e');
      rethrow;
    }
  }

  // Fallback method for customer orders (non-streaming)
  static Future<List<OrderModel>> getCustomerOrders(String customerId) async {
    print('DEBUG: getCustomerOrders called with customerId: $customerId');
    
    try {
      final data = await _client
          .from('orders')
          .select('*')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      
      print('DEBUG: getCustomerOrders returned ${data.length} orders');
      return data.map((d) => OrderModel.fromJson(d)).toList();
    } catch (e) {
      print('DEBUG: getCustomerOrders failed: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> listenToProducts() => _client
      .from('products')
      .stream(primaryKey: ['id'])
      .eq('status', 'active')
      .order('created_at', ascending: false);

  static Future<Map<String, dynamic>?> getFarmerWallet(String farmerId) async {
    try {
      // Get all delivered orders for this farmer
      final orders = await _client
          .from('orders')
          .select('*')
          .eq('farmer_id', farmerId)
          .eq('status', 'delivered');

      // Calculate earnings (farmer receives 95% after 5% platform fee)
      double totalEarned = 0;
      double thisMonth = 0;
      int orderCount = orders.length;

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (final order in orders) {
        final orderAmount = (order['total_amount'] as num).toDouble();
        final farmerEarns = orderAmount * 0.95; // 95% after platform fee
        totalEarned += farmerEarns;

        // Check if order was delivered this month
        final deliveredAt = order['delivered_at'] != null
            ? DateTime.parse(order['delivered_at'])
            : DateTime.parse(order['created_at']);
        if (deliveredAt.isAfter(firstDayOfMonth)) {
          thisMonth += farmerEarns;
        }
      }

      return {
        'farmer_id': farmerId,
        'balance': totalEarned, // Available balance
        'total_earned': totalEarned,
        'this_month': thisMonth,
        'order_count': orderCount,
      };
    } catch (e) {
      print('Error getting farmer wallet: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getWalletTransactions(
          String farmerId) async {
    try {
      // Get all delivered orders as transactions
      final orders = await _client
          .from('orders')
          .select('*, products(name)')
          .eq('farmer_id', farmerId)
          .eq('status', 'delivered')
          .order('delivered_at', ascending: false);

      // Convert orders to transaction format
      return orders.map<Map<String, dynamic>>((order) {
        final orderAmount = (order['total_amount'] as num).toDouble();
        final farmerEarns = orderAmount * 0.95; // 95% after 5% platform fee
        final platformFee = orderAmount * 0.05;

        return {
          'id': order['id'],
          'farmer_id': farmerId,
          'order_id': order['id'],
          'type': 'credit',
          'amount': farmerEarns,
          'description':
              'Order delivered: ${order['product_name'] ?? 'Product'} (₹$orderAmount - ₹${platformFee.toStringAsFixed(0)} platform fee)',
          'created_at': order['delivered_at'] ?? order['created_at'],
        };
      }).toList();
    } catch (e) {
      print('Error getting wallet transactions: $e');
      return [];
    }
  }

  static Future<void> submitReview(
      {required String orderId,
      required String farmerId,
      required int rating,
      required int freshnessRating,
      String? comment}) async {
    
    final customerId = currentUserId;
    if (customerId == null) {
      throw Exception('Customer not logged in');
    }
    
    await _client.from('reviews').insert({
      'order_id': orderId,
      'customer_id': customerId, // Add missing customer_id
      'farmer_id': farmerId,
      'rating': rating,
      'freshness_rating': freshnessRating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String()
    });
    final reviews = await _client
        .from('reviews')
        .select('rating')
        .eq('farmer_id', farmerId);
    final avg = reviews.map((r) => r['rating'] as int).reduce((a, b) => a + b) /
        reviews.length;
    await _client.from('users').update({'rating': avg}).eq('id', farmerId);
  }

  static Future<List<Map<String, dynamic>>> getNotifications(
          String userId) async =>
      await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('sent_at', ascending: false)
          .limit(50);

  static Future<void> markNotificationRead(String notificationId) async =>
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);

  static Future<Map<String, dynamic>> getAdminStats() async {
    final farmers =
        await _client.from('users').select('id').eq('role', 'farmer');
    final customers =
        await _client.from('users').select('id').eq('role', 'customer');
    final orders = await _client.from('orders').select('total_amount, status');
    final products =
        await _client.from('products').select('id').eq('status', 'active');
    final totalRevenue = orders
        .where((o) => o['status'] == 'delivered')
        .fold<double>(0, (s, o) => s + (o['total_amount'] as num).toDouble());
    return {
      'totalFarmers': farmers.length,
      'totalCustomers': customers.length,
      'totalOrders': orders.length,
      'activeProducts': products.length,
      'totalRevenue': totalRevenue,
      'platformRevenue': totalRevenue * 0.05
    };
  }

  // Admin methods
  static Future<List<Map<String, dynamic>>> getAllFarmers() async {
    final data = await _client
        .from('users')
        .select('*')
        .eq('role', 'farmer')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      print('Fetching all customers...'); // Debug
      
      // Get all users first to see what we have
      final allUsers = await _client
          .from('users')
          .select('*')
          .order('created_at', ascending: false);
      
      print('Total users in database: ${allUsers.length}'); // Debug
      
      // Filter for customers
      final customers = allUsers.where((user) {
        final role = user['role']?.toString().toLowerCase();
        final isCustomer = role == 'customer';
        print('User: ${user['name']} - Role: $role - IsCustomer: $isCustomer'); // Debug
        return isCustomer;
      }).toList();
      
      print('Filtered customers: ${customers.length}'); // Debug
      
      return List<Map<String, dynamic>>.from(customers);
    } catch (e) {
      print('Error fetching customers: $e');
      rethrow;
    }
  }

  static Future<void> updateCustomerStatus(String customerId, bool isBlocked) async {
    await _client
        .from('users')
        .update({'is_blocked': isBlocked})
        .eq('id', customerId);
  }

  static Future<void> deleteCustomer(String customerId) async {
    try {
      print('DEBUG: Starting customer deletion process for ID: $customerId');
      
      // First verify the customer exists
      final existingCustomer = await _client
          .from('users')
          .select('id, name, role')
          .eq('id', customerId)
          .maybeSingle();
      
      if (existingCustomer == null) {
        throw Exception('Customer not found');
      }
      
      print('DEBUG: Found customer: ${existingCustomer['name']} (${existingCustomer['role']})');
      
      // Delete customer's orders first (cascade delete)
      print('DEBUG: Deleting customer orders...');
      final orderDeleteResult = await _client
          .from('orders')
          .delete()
          .eq('customer_id', customerId);
      print('DEBUG: Orders deletion result: $orderDeleteResult');
      
      // Delete customer's reviews
      print('DEBUG: Deleting customer reviews...');
      final reviewDeleteResult = await _client
          .from('reviews')
          .delete()
          .eq('customer_id', customerId);
      print('DEBUG: Reviews deletion result: $reviewDeleteResult');
      
      // Delete customer's wallet transactions (if table exists)
      try {
        print('DEBUG: Deleting wallet transactions...');
        await _client
            .from('wallet_transactions')
            .delete()
            .eq('user_id', customerId);
      } catch (e) {
        print('DEBUG: Wallet transactions table might not exist: $e');
      }
      
      // Delete customer's notifications (if table exists)
      try {
        print('DEBUG: Deleting notifications...');
        await _client
            .from('notifications')
            .delete()
            .eq('user_id', customerId);
      } catch (e) {
        print('DEBUG: Notifications deletion failed: $e');
      }
      
      // Finally delete the customer
      print('DEBUG: Deleting customer record...');
      final customerDeleteResult = await _client
          .from('users')
          .delete()
          .eq('id', customerId);
      print('DEBUG: Customer deletion result: $customerDeleteResult');
      
      // Verify deletion
      final verifyResult = await _client
          .from('users')
          .select('id')
          .eq('id', customerId)
          .maybeSingle();
      
      if (verifyResult != null) {
        throw Exception('Customer deletion failed - record still exists');
      }
      
      print('DEBUG: Customer deletion completed successfully');
      
    } catch (e) {
      print('ERROR: Customer deletion failed: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getFarmerDetails(String farmerId) async {
    final data = await _client
        .from('users')
        .select('*')
        .eq('id', farmerId)
        .maybeSingle();
    return data;
  }

  static Future<Map<String, dynamic>?> getCustomerDetails(
      String customerId) async {
    final data = await _client
        .from('users')
        .select('*')
        .eq('id', customerId)
        .maybeSingle();
    return data;
  }

  static Future<List<Map<String, dynamic>>> getFarmerProductsAdmin(
      String farmerId) async {
    final data = await _client
        .from('products')
        .select('*')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getFarmerOrdersAdmin(
      String farmerId) async {
    final data = await _client
        .from('orders')
        .select('*')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getCustomerOrdersAdmin(
      String customerId) async {
    final data = await _client
        .from('orders')
        .select('*')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    final data = await _client
        .from('orders')
        .select('*, products(name, users(name, phone, address)), users!orders_customer_id_fkey(name, phone)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      print('Fetching all products to check database structure...');
      final data = await _client
          .from('products')
          .select('*')
          .limit(1);
      
      if (data.isNotEmpty) {
        print('Sample product from database: ${data.first}');
        print('Available fields: ${data.first.keys.toList()}');
      } else {
        print('No products found in database');
      }
      
      final allData = await _client
          .from('products')
          .select('*, users(name)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(allData);
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    final data = await _client
        .from('orders')
        .select('*, products(name, users(name, phone, address)), users!orders_customer_id_fkey(name, phone)')
        .eq('id', orderId)
        .maybeSingle();
    return data;
  }

  // AI Freshness Score System
  static int calculateFreshnessScore({
    required DateTime harvestTime,
    required double farmerRating,
    required double distanceKm,
  }) {
    // Time since harvest (60 points max)
    final hoursSinceHarvest = DateTime.now().difference(harvestTime).inHours;
    int timeScore = 60;
    if (hoursSinceHarvest <= 2) {
      timeScore = 60;
    } else if (hoursSinceHarvest <= 6) {
      timeScore = 55;
    } else if (hoursSinceHarvest <= 12) {
      timeScore = 50;
    } else if (hoursSinceHarvest <= 24) {
      timeScore = 40;
    } else if (hoursSinceHarvest <= 48) {
      timeScore = 30;
    } else {
      timeScore = 20;
    }

    // Farmer rating (25 points max)
    final ratingScore = (farmerRating * 5).round();

    // Distance (15 points max)
    int distanceScore = 15;
    if (distanceKm <= 5) {
      distanceScore = 15;
    } else if (distanceKm <= 10) {
      distanceScore = 12;
    } else if (distanceKm <= 15) {
      distanceScore = 10;
    } else if (distanceKm <= 20) {
      distanceScore = 7;
    } else if (distanceKm <= 25) {
      distanceScore = 5;
    } else {
      distanceScore = 3;
    }

    return timeScore + ratingScore + distanceScore;
  }

  static String getFreshnessLabel(int score) {
    if (score >= 90) return 'Ultra Fresh';
    if (score >= 75) return 'Very Fresh';
    if (score >= 60) return 'Fresh';
    if (score >= 45) return 'Good';
    if (score >= 30) return 'Aging';
    return 'Too Old';
  }

  static Color getFreshnessColor(int score) {
    if (score >= 90) return const Color(0xFF27AE60);
    if (score >= 75) return const Color(0xFF2ECC71);
    if (score >= 60) return const Color(0xFF52BE80);
    if (score >= 45) return const Color(0xFFF39C12);
    if (score >= 30) return const Color(0xFFE67E22);
    return const Color(0xFFE74C3C);
  }

  // Follow/Unfollow Farmer
  static Future<void> followFarmer(String customerId, String farmerId) async {
    await _client.from('farmer_followers').insert({
      'customer_id': customerId,
      'farmer_id': farmerId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> unfollowFarmer(String customerId, String farmerId) async {
    await _client
        .from('farmer_followers')
        .delete()
        .eq('customer_id', customerId)
        .eq('farmer_id', farmerId);
  }

  static Future<bool> isFollowingFarmer(
      String customerId, String farmerId) async {
    final data = await _client
        .from('farmer_followers')
        .select('id')
        .eq('customer_id', customerId)
        .eq('farmer_id', farmerId)
        .maybeSingle();
    return data != null;
  }

  static Future<List<Map<String, dynamic>>> getFollowedFarmers(
      String customerId) async {
    final data = await _client
        .from('farmer_followers')
        .select('*, users!farmer_followers_farmer_id_fkey(*)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Group Buy Features
  static Future<String> createGroupBuy({
    required String productId,
    required String creatorId,
    required double targetQuantity,
    required double discountPercent,
    required DateTime expiresAt,
  }) async {
    final data = await _client
        .from('group_buys')
        .insert({
          'id': const Uuid().v4(),
          'product_id': productId,
          'creator_id': creatorId,
          'target_quantity': targetQuantity,
          'current_quantity': 0,
          'discount_percent': discountPercent,
          'status': 'active',
          'expires_at': expiresAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return data['id'] as String;
  }

  static Future<void> joinGroupBuy(
      String groupBuyId, String customerId, double quantity) async {
    await _client.from('group_buy_members').insert({
      'group_buy_id': groupBuyId,
      'customer_id': customerId,
      'quantity': quantity,
      'joined_at': DateTime.now().toIso8601String(),
    });

    // Update current quantity
    final groupBuy = await _client
        .from('group_buys')
        .select('current_quantity')
        .eq('id', groupBuyId)
        .single();

    final newQuantity = (groupBuy['current_quantity'] as num) + quantity;
    await _client
        .from('group_buys')
        .update({'current_quantity': newQuantity}).eq('id', groupBuyId);
  }

  static Future<List<Map<String, dynamic>>> getActiveGroupBuys() async {
    final data = await _client
        .from('group_buys')
        .select('*, products(*), users!group_buys_creator_id_fkey(name)')
        .eq('status', 'active')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>?> getGroupBuyDetails(
      String groupBuyId) async {
    final data = await _client
        .from('group_buys')
        .select('*, products(*), users!group_buys_creator_id_fkey(name)')
        .eq('id', groupBuyId)
        .maybeSingle();
    return data;
  }

  static Future<List<Map<String, dynamic>>> getGroupBuyMembers(
      String groupBuyId) async {
    final data = await _client
        .from('group_buy_members')
        .select(
            '*, users!group_buy_members_customer_id_fkey(name, profile_image)')
        .eq('group_buy_id', groupBuyId)
        .order('joined_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // ═══════════════════════════════════════════════════════════════
  // LOCATION & DISTANCE FEATURES
  // ═══════════════════════════════════════════════════════════════
  // LOCATION & DISTANCE FEATURES
  // ═══════════════════════════════════════════════════════════════

  // Distance calculation using Haversine formula
  static double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Get nearby products with distance and freshness
  static Future<List<Map<String, dynamic>>> getNearbyProductsWithScore({
    required double customerLat,
    required double customerLng,
    double radiusKm = 25,
    String? category,
  }) async {
    dynamic query = _client
        .from('products')
        .select(
            '*, users(id, name, profile_image, rating, latitude, longitude, district, city, village)')
        .eq('status', 'active')
        .gt('valid_until', DateTime.now().toIso8601String())
        .gt('quantity_left', 0);

    if (category != null && category != 'all') {
      query = query.eq('category', category);
    }

    query = query.order('created_at', ascending: false);
    final data = await query;

    // Calculate distance and freshness for each product
    final productsWithScore = data
        .map((product) {
          // Ensure farmer data exists
          if (product['users'] == null) {
            print('Warning: Product ${product['id']} has no farmer data');
            return null;
          }

          final farmerData = product['users'] as Map<String, dynamic>;
          final farmerLat = farmerData['latitude'] as double?;
          final farmerLng = farmerData['longitude'] as double?;

          // Add farmer_name to product for compatibility
          product['farmer_name'] = farmerData['name'] ?? 'Unknown Farmer';

          // Calculate distance if location data exists, otherwise use default
          double distance = 0.0;
          if (farmerLat != null && farmerLng != null) {
            distance = calculateDistance(
              lat1: customerLat,
              lng1: customerLng,
              lat2: farmerLat,
              lng2: farmerLng,
            );
          } else {
            // If farmer has no location, show them as 0km away (local)
            print('Info: Farmer ${farmerData['name']} has no location data, showing as local');
            distance = 0.0;
          }

          // Include ALL products regardless of distance to show all farmers
          final freshnessScore = calculateFreshnessScore(
            harvestTime: DateTime.parse(product['created_at']),
            farmerRating: (farmerData['rating'] as num?)?.toDouble() ?? 0.0,
            distanceKm: distance,
          );

          // Show all products, even with low freshness scores
          product['distance_km'] = distance;
          product['freshness_score'] = freshnessScore;
          product['freshness_label'] = getFreshnessLabel(freshnessScore);
          return product;
        })
        .where((p) => p != null)
        .toList();

    // Sort by feed algorithm score
    productsWithScore.sort((a, b) {
      final scoreA = _calculateFeedScore(a!, customerLat, customerLng);
      final scoreB = _calculateFeedScore(b!, customerLat, customerLng);
      return scoreB.compareTo(scoreA);
    });

    return productsWithScore.cast<Map<String, dynamic>>();
  }

  // Get single product with farmer details
  static Future<Map<String, dynamic>?> getProductWithFarmerDetails(String productId) async {
    try {
      final data = await _client
          .from('products')
          .select(
              '*, users(id, name, profile_image, rating, latitude, longitude, district, city, village, phone, address)')
          .eq('id', productId)
          .maybeSingle();

      if (data != null && data['users'] != null) {
        // Add farmer_name for compatibility
        data['farmer_name'] = data['users']['name'];
      }

      return data;
    } catch (e) {
      print('Error fetching product with farmer details: $e');
      return null;
    }
  }

  // Verify farmer (triggers automatic customer notifications)
  static Future<void> verifyFarmer(String farmerId) async {
    try {
      await _client
          .from('users')
          .update({
            'is_verified': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);
      
      print('Farmer verified successfully - customers will be notified automatically');
    } catch (e) {
      print('Error verifying farmer: $e');
      rethrow;
    }
  }

  // Update farmer profile (triggers notifications to followers)
  static Future<void> updateFarmerProfile(String farmerId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await _client
          .from('users')
          .update(updates)
          .eq('id', farmerId);
      
      print('Farmer profile updated - followers will be notified automatically');
    } catch (e) {
      print('Error updating farmer profile: $e');
      rethrow;
    }
  }

  // Get all products without location restrictions (for debugging)
  static Future<List<Map<String, dynamic>>> getAllProductsWithFarmers() async {
    try {
      final data = await _client
          .from('products')
          .select(
              '*, users(id, name, profile_image, rating, latitude, longitude, district, city, village)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      // Add farmer_name to all products
      for (final product in data) {
        if (product['users'] != null) {
          product['farmer_name'] = product['users']['name'];
          product['distance_km'] = 0.0; // Default distance
          product['freshness_score'] = product['freshness_score'] ?? 85;
          product['freshness_label'] = getFreshnessLabel(product['freshness_score'] ?? 85);
        }
      }

      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching all products: $e');
      return [];
    }
  }

  // Feed algorithm: Distance(40%) + Freshness(30%) + Following(20%) + Category(10%)
  static double _calculateFeedScore(
      Map<String, dynamic> product, double customerLat, double customerLng) {
    final distance = product['distance_km'] as double;
    final freshnessScore = product['freshness_score'] as int;

    // Distance score (40%) - closer is better
    final distanceScore = ((25 - distance) / 25 * 40).clamp(0, 40);

    // Freshness score (30%)
    final freshnessWeight = freshnessScore / 100 * 30;

    // Following score (20%) - would need to check if customer follows farmer
    const followingScore = 0.0; // TODO: Check following status

    // Category preference (10%) - would need customer's order history
    const categoryScore = 0.0; // TODO: Check category preference

    return distanceScore + freshnessWeight + followingScore + categoryScore;
  }

  // ═══════════════════════════════════════════════════════════════
  // PARTIAL PAYMENT FOR FARMER DETAILS
  // ═══════════════════════════════════════════════════════════════

  // Create advance payment to unlock farmer details
  static Future<String> createAdvancePayment({
    required String customerId,
    required String farmerId,
    required String productId,
    required double advanceAmount,
    required double totalAmount,
  }) async {
    final paymentId = const Uuid().v4();
    await _client.from('advance_payments').insert({
      'id': paymentId,
      'customer_id': customerId,
      'farmer_id': farmerId,
      'product_id': productId,
      'advance_amount': advanceAmount,
      'total_amount': totalAmount,
      'payment_status': 'paid',
      'created_at': DateTime.now().toIso8601String(),
    });
    return paymentId;
  }

  static Future<bool> hasAdvancePayment(
      String customerId, String farmerId) async {
    final data = await _client
        .from('advance_payments')
        .select('id')
        .eq('customer_id', customerId)
        .eq('farmer_id', farmerId)
        .eq('payment_status', 'paid')
        .maybeSingle();
    return data != null;
  }

  // Get farmer full details (after advance payment)
  static Future<Map<String, dynamic>?> getFarmerFullDetails(
      String farmerId) async {
    final data = await _client
        .from('users')
        .select(
            'id, name, phone, profile_image, rating, latitude, longitude, address, district, city, village, state, is_verified, created_at')
        .eq('id', farmerId)
        .eq('role', 'farmer')
        .maybeSingle();
    return data;
  }

  // Get farmer limited details (before payment)
  static Future<Map<String, dynamic>?> getFarmerLimitedDetails(
      String farmerId) async {
    final data = await _client
        .from('users')
        .select('id, name, profile_image, rating, district, city, is_verified')
        .eq('id', farmerId)
        .eq('role', 'farmer')
        .maybeSingle();
    return data;
  }

  // ═══════════════════════════════════════════════════════════════
  // NEARBY FARMERS DISCOVERY
  // ═══════════════════════════════════════════════════════════════

  // Get farmers within radius
  static Future<List<Map<String, dynamic>>> getFarmersNearby({
    required double customerLat,
    required double customerLng,
    double radiusKm = 25,
  }) async {
    final farmers = await _client
        .from('users')
        .select(
            'id, name, profile_image, rating, latitude, longitude, district, city, village, state, is_verified')
        .eq('role', 'farmer')
        .eq('is_verified', true);

    final nearbyFarmers = farmers.where((farmer) {
      final lat = farmer['latitude'] as double?;
      final lng = farmer['longitude'] as double?;

      if (lat != null && lng != null) {
        final distance = calculateDistance(
          lat1: customerLat,
          lng1: customerLng,
          lat2: lat,
          lng2: lng,
        );

        if (distance <= radiusKm) {
          farmer['distance_km'] = distance;
          return true;
        }
      }
      return false;
    }).toList();

    // Sort by distance
    nearbyFarmers.sort((a, b) {
      final distA = a['distance_km'] as double;
      final distB = b['distance_km'] as double;
      return distA.compareTo(distB);
    });

    return nearbyFarmers;
  }

  // Product deletion method
  static Future<void> deleteProduct(String productId) async {
    try {
      print('DEBUG: SupabaseService.deleteProduct called with ID: $productId');
      
      // First, check if the product exists
      final existingProduct = await _client
          .from('products')
          .select('id, name, farmer_id')
          .eq('id', productId)
          .maybeSingle();
      
      if (existingProduct == null) {
        print('DEBUG: Product not found in database: $productId');
        throw Exception('Product not found');
      }
      
      print('DEBUG: Found product to delete: ${existingProduct['name']} (${existingProduct['id']})');
      
      // Check if there are any orders for this product that might prevent deletion
      final relatedOrders = await _client
          .from('orders')
          .select('id')
          .eq('product_id', productId);
      
      print('DEBUG: Found ${relatedOrders.length} related orders');
      
      // If there are related orders, we might need to handle them differently
      if (relatedOrders.isNotEmpty) {
        print('DEBUG: Product has related orders, attempting soft delete...');
        // Instead of deleting, mark as inactive
        await _client
            .from('products')
            .update({'status': 'deleted'})
            .eq('id', productId);
        print('DEBUG: Product marked as deleted (soft delete)');
      } else {
        print('DEBUG: No related orders, attempting hard delete...');
        // Delete the product from database
        final result = await _client
            .from('products')
            .delete()
            .eq('id', productId);
        
        print('DEBUG: Delete operation completed. Result: $result');
      }
      
      // Verify deletion/update by checking product status
      final verifyResult = await _client
          .from('products')
          .select('id, status')
          .eq('id', productId)
          .maybeSingle();
      
      if (verifyResult == null) {
        print('DEBUG: Product successfully deleted from database (hard delete)');
      } else if (verifyResult['status'] == 'deleted') {
        print('DEBUG: Product successfully marked as deleted (soft delete)');
      } else {
        print('WARNING: Product still exists with status: ${verifyResult['status']}');
        throw Exception('Product deletion failed - still exists in database');
      }
      
    } catch (e) {
      print('ERROR: Failed to delete product: $e');
      rethrow;
    }
  }
}
