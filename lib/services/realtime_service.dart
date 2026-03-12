import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Real-Time Service for FieldFresh
/// Handles all real-time subscriptions and notifications
class RealtimeService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final Map<String, RealtimeChannel> _channels = {};

  // ═══════════════════════════════════════════════════════════════
  // CUSTOMER REAL-TIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Subscribe to nearby products feed (real-time harvest updates)
  static Stream<List<Map<String, dynamic>>> subscribeToNearbyProducts({
    required double customerLat,
    required double customerLng,
    double radiusKm = 25,
  }) {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .asyncMap((products) async {
          // For each product, fetch farmer data and calculate distance
          final List<Map<String, dynamic>> allProducts = [];
          
          for (final product in products) {
            try {
              // Get farmer data
              final farmerData = await _client
                  .from('users')
                  .select('id, name, profile_image, rating, latitude, longitude')
                  .eq('id', product['farmer_id'])
                  .maybeSingle();

              if (farmerData != null) {
                final farmerLat = farmerData['latitude'] as double?;
                final farmerLng = farmerData['longitude'] as double?;

                // Calculate distance if location exists, otherwise use 0
                double distance = 0.0;
                if (farmerLat != null && farmerLng != null) {
                  distance = SupabaseService.calculateDistance(
                    lat1: customerLat,
                    lng1: customerLng,
                    lat2: farmerLat,
                    lng2: farmerLng,
                  );
                } else {
                  // Show farmers without location as local (0km)
                  distance = 0.0;
                }

                // Include ALL products to show all farmers
                // Add farmer data and distance to product
                product['users'] = farmerData;
                product['farmer_name'] = farmerData['name'];
                product['distance_km'] = distance;
                
                // Calculate freshness score
                final freshnessScore = SupabaseService.calculateFreshnessScore(
                  harvestTime: DateTime.parse(product['created_at']),
                  farmerRating: (farmerData['rating'] as num?)?.toDouble() ?? 0.0,
                  distanceKm: distance,
                );
                
                product['freshness_score'] = freshnessScore;
                product['freshness_label'] = SupabaseService.getFreshnessLabel(freshnessScore);
                
                allProducts.add(product);
              }
            } catch (e) {
              print('Error processing product ${product['id']}: $e');
            }
          }
          
          return allProducts;
        });
  }

  /// Subscribe to customer's orders (real-time order updates)
  static Stream<List<Map<String, dynamic>>> subscribeToCustomerOrders(
    String customerId,
  ) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((orders) =>
            orders.where((o) => o['customer_id'] == customerId).toList());
  }

  /// Subscribe to specific order tracking
  static Stream<Map<String, dynamic>?> subscribeToOrderTracking(
    String orderId,
  ) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((orders) => orders.isNotEmpty ? orders.first : null);
  }

  /// Subscribe to followed farmers' new products
  static Stream<List<Map<String, dynamic>>> subscribeToFollowedFarmersProducts(
    String customerId,
  ) async* {
    // Get followed farmers
    final followedFarmers =
        await SupabaseService.getFollowedFarmers(customerId);
    final farmerIds =
        followedFarmers.map((f) => f['farmer_id'] as String).toList();

    if (farmerIds.isEmpty) {
      yield [];
      return;
    }

    yield* _client
        .from('products')
        .stream(primaryKey: ['id'])
        .inFilter('farmer_id', farmerIds)
        .order('created_at', ascending: false)
        .map((products) =>
            products.where((p) => p['status'] == 'active').toList());
  }

  // ═══════════════════════════════════════════════════════════════
  // FARMER REAL-TIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Subscribe to new farmer registrations (for customer panels)
  static Stream<List<Map<String, dynamic>>> subscribeToNewFarmers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((users) => users
            .where((user) => user['role'] == 'farmer' && user['is_verified'] == true)
            .toList());
  }

  /// Subscribe to farmer profile updates (for customer panels)
  static Stream<List<Map<String, dynamic>>> subscribeToFarmerUpdates() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((users) => users
            .where((user) => user['role'] == 'farmer')
            .toList());
  }

  /// Subscribe to all verified farmers (for nearby farmers list)
  static Stream<List<Map<String, dynamic>>> subscribeToAllVerifiedFarmers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((users) => users
            .where((user) => user['role'] == 'farmer' && user['is_verified'] == true)
            .toList());
  }

  /// Subscribe to farmer's incoming orders (real-time order alerts)
  static Stream<List<Map<String, dynamic>>> subscribeToFarmerOrders(
    String farmerId,
  ) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
  }

  /// Subscribe to farmer's products (quantity updates)
  static Stream<List<Map<String, dynamic>>> subscribeToFarmerProducts(
    String farmerId,
  ) {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
  }

  /// Subscribe to farmer's wallet transactions
  static Stream<List<Map<String, dynamic>>> subscribeToWalletTransactions(
    String farmerId,
  ) {
    return _client
        .from('wallet_transactions')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
  }

  /// Subscribe to farmer's wallet balance
  static Stream<Map<String, dynamic>?> subscribeToWalletBalance(
    String farmerId,
  ) {
    return _client
        .from('farmer_wallets')
        .stream(primaryKey: ['farmer_id'])
        .eq('farmer_id', farmerId)
        .map((wallets) => wallets.isNotEmpty ? wallets.first : null);
  }

  // ═══════════════════════════════════════════════════════════════
  // ADMIN REAL-TIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Subscribe to all platform orders (admin monitoring)
  static Stream<List<Map<String, dynamic>>> subscribeToAllOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100);
  }

  /// Subscribe to all platform products
  static Stream<List<Map<String, dynamic>>> subscribeToAllProducts() {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100);
  }

  /// Subscribe to new user registrations
  static Stream<List<Map<String, dynamic>>> subscribeToNewUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50);
  }

  /// Subscribe to platform activity (all tables combined)
  static Stream<Map<String, dynamic>> subscribeToPlatformActivity() {
    // Return orders stream as primary activity indicator
    return subscribeToAllOrders().map((orders) => {
          'type': 'orders',
          'data': orders,
          'timestamp': DateTime.now().toIso8601String(),
        });
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATION SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════

  /// Subscribe to user notifications
  static Stream<List<Map<String, dynamic>>> subscribeToNotifications(
    String userId,
  ) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('sent_at', ascending: false)
        .limit(50);
  }

  /// Subscribe to unread notification count
  static Stream<int> subscribeToUnreadNotificationCount(String userId) {
    return _client.from('notifications').stream(primaryKey: ['id']).map(
        (notifications) => notifications
            .where((n) => n['user_id'] == userId && n['is_read'] == false)
            .length);
  }

  // ═══════════════════════════════════════════════════════════════
  // GROUP BUY REAL-TIME
  // ═══════════════════════════════════════════════════════════════

  /// Subscribe to active group buys
  static Stream<List<Map<String, dynamic>>> subscribeToActiveGroupBuys() {
    return _client
        .from('group_buys')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('created_at', ascending: false);
  }

  /// Subscribe to specific group buy progress
  static Stream<Map<String, dynamic>?> subscribeToGroupBuyProgress(
    String groupBuyId,
  ) {
    return _client
        .from('group_buys')
        .stream(primaryKey: ['id'])
        .eq('id', groupBuyId)
        .map((groups) => groups.isNotEmpty ? groups.first : null);
  }

  /// Subscribe to group buy members
  static Stream<List<Map<String, dynamic>>> subscribeToGroupBuyMembers(
    String groupBuyId,
  ) {
    return _client
        .from('group_buy_members')
        .stream(primaryKey: ['id'])
        .eq('group_buy_id', groupBuyId)
        .order('joined_at', ascending: false);
  }

  // ═══════════════════════════════════════════════════════════════
  // HARVEST BLAST NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Create harvest blast notification (called when farmer posts product)
  static Future<void> sendHarvestBlast({
    required String productId,
    required String farmerId,
    required double farmerLat,
    required double farmerLng,
    required String productName,
    required double pricePerUnit,
    required String unit,
  }) async {
    try {
      // Find customers within 25km radius
      final customers = await _client
          .from('users')
          .select('id, latitude, longitude, fcm_token')
          .eq('role', 'customer');

      final nearbyCustomers = customers.where((customer) {
        final lat = customer['latitude'] as double?;
        final lng = customer['longitude'] as double?;

        if (lat != null && lng != null) {
          final distance = SupabaseService.calculateDistance(
            lat1: farmerLat,
            lng1: farmerLng,
            lat2: lat,
            lng2: lng,
          );
          return distance <= 25;
        }
        return false;
      }).toList();

      // Create notifications for nearby customers
      final notifications = nearbyCustomers.map((customer) {
        return {
          'user_id': customer['id'],
          'title': 'Fresh $productName near you! 🌾',
          'message': '₹$pricePerUnit/$unit - Just harvested',
          'type': 'harvest_blast',
          'data': {'product_id': productId, 'farmer_id': farmerId},
          'is_read': false,
          'sent_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }

      // TODO: Send FCM push notifications to customer devices
      // This would integrate with Firebase Cloud Messaging
    } catch (e) {
      print('Error sending harvest blast: $e');
    }
  }

  /// Send order notification to farmer
  static Future<void> sendOrderNotificationToFarmer({
    required String farmerId,
    required String orderId,
    required String productName,
    required double quantity,
    required String customerName,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': farmerId,
        'title': 'New Order Received! 🎉',
        'message': '$customerName ordered ${quantity}kg of $productName',
        'type': 'new_order',
        'data': {'order_id': orderId},
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending order notification: $e');
    }
  }

  /// Send order status update to customer
  static Future<void> sendOrderStatusNotification({
    required String customerId,
    required String orderId,
    required String status,
    required String productName,
  }) async {
    try {
      final messages = {
        'confirmed': 'Order confirmed! 🎉',
        'packed': 'Order packed and ready! 📦',
        'dispatched': 'Order dispatched! 🚚',
        'delivered': 'Order delivered! ✅',
        'cancelled': 'Order cancelled ❌',
      };

      final message = messages[status] ?? 'Order status updated';

      await _client.from('notifications').insert({
        'user_id': customerId,
        'title': message,
        'message': 'Your order of $productName is $status',
        'type': 'order_status',
        'data': {'order_id': orderId, 'status': status},
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  /// Send expiry warning (products expiring in 2 hours)
  static Future<void> sendExpiryWarnings() async {
    try {
      final twoHoursFromNow = DateTime.now().add(const Duration(hours: 2));

      final expiringProducts = await _client
          .from('products')
          .select('id, name, farmer_id, valid_until')
          .eq('status', 'active')
          .lt('valid_until', twoHoursFromNow.toIso8601String())
          .gt('valid_until', DateTime.now().toIso8601String());

      for (final product in expiringProducts) {
        await _client.from('notifications').insert({
          'user_id': product['farmer_id'],
          'title': 'Product Expiring Soon! ⏰',
          'message': '${product['name']} will expire in 2 hours',
          'type': 'expiry_warning',
          'data': {'product_id': product['id']},
          'is_read': false,
          'sent_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error sending expiry warnings: $e');
    }
  }

  /// Send price drop alert
  static Future<void> sendPriceDropAlert({
    required String productId,
    required String productName,
    required double oldPrice,
    required double newPrice,
    required String unit,
  }) async {
    try {
      // Find customers who saved/viewed this product
      // For now, send to all customers (can be optimized with saved_products table)
      final customers =
          await _client.from('users').select('id').eq('role', 'customer');

      final notifications = customers.map((customer) {
        final discount = ((oldPrice - newPrice) / oldPrice * 100).round();
        return {
          'user_id': customer['id'],
          'title': 'Price Drop Alert! 💰',
          'message': '$productName now ₹$newPrice/$unit ($discount% off)',
          'type': 'price_drop',
          'data': {'product_id': productId},
          'is_read': false,
          'sent_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }
    } catch (e) {
      print('Error sending price drop alert: $e');
    }
  }

  /// Send new farmer welcome notification to customers
  static Future<void> sendNewFarmerNotification({
    required String farmerId,
    required String farmerName,
    required String farmerLocation,
  }) async {
    try {
      // Get all customers
      final customers = await _client
          .from('users')
          .select('id')
          .eq('role', 'customer');

      final notifications = customers.map((customer) {
        return {
          'user_id': customer['id'],
          'title': 'New Farmer Joined! 👨‍🌾',
          'message': '$farmerName from $farmerLocation is now selling fresh produce',
          'type': 'new_farmer',
          'data': {'farmer_id': farmerId},
          'is_read': false,
          'sent_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      if (notifications.isNotEmpty) {
        await _client.from('notifications').insert(notifications);
      }
    } catch (e) {
      print('Error sending new farmer notification: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CHANNEL MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// Dispose all channels
  static Future<void> disposeAllChannels() async {
    for (final channel in _channels.values) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }

  /// Dispose specific channel
  static Future<void> disposeChannel(String channelName) async {
    final channel = _channels[channelName];
    if (channel != null) {
      await _client.removeChannel(channel);
      _channels.remove(channelName);
    }
  }
}

/// Real-Time Notification Widget
/// Shows in-app notifications with auto-dismiss
class RealtimeNotificationWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const RealtimeNotificationWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications,
    this.color = Colors.blue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
