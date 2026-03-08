import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  // Listen to user notifications in real-time
  static Stream<List<Map<String, dynamic>>> listenToNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  // Get all notifications
  static Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final data = await _client
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  // Get unread count
  static Future<int> getUnreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('read', false);
    return data.length;
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  // Mark all as read
  static Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  // Send manual notification (for testing or admin)
  static Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data ?? {},
    });
  }

  // Get notification icon based on type
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'new_product':
        return '🌾';
      case 'advance_paid':
        return '💰';
      case 'order_confirmed':
        return '✅';
      case 'order_packed':
        return '📦';
      case 'order_delivered':
        return '✅';
      case 'payment_received':
        return '💵';
      default:
        return '🔔';
    }
  }
}
