import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final id = SupabaseService.currentUserId;
    if (id == null) { setState(() => _loading = false); return; }
    try {
      final n = await SupabaseService.getNotifications(id);
      setState(() { _notifications = n; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        actions: [TextButton(onPressed: () => setState(() => _notifications = _notifications.map((n) => {...n, 'is_read': true}).toList()),
            child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)))]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🔔', style: TextStyle(fontSize: 64)), SizedBox(height: 12),
                  Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Harvest alerts appear here!', style: TextStyle(color: AppColors.textHint)),
                ]))
              : RefreshIndicator(onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final read = n['is_read'] as bool? ?? false;
                      final type = n['type'] as String? ?? 'harvest_blast';
                      final emoji = type == 'harvest_blast' ? '🌾' : type == 'new_order' ? '🎉' : '📦';
                      return ListTile(
                        tileColor: read ? null : AppColors.primary.withOpacity(0.04),
                        leading: Container(width: 46, height: 46,
                            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
                        title: Text(n['title'] ?? '', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['body'] ?? '', style: const TextStyle(fontSize: 12), maxLines: 2),
                          if (n['sent_at'] != null)
                            Text(timeago.format(DateTime.tryParse(n['sent_at'] as String) ?? DateTime.now()),
                                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ]),
                        trailing: !read ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
                        onTap: () async {
                          await SupabaseService.markNotificationRead(n['id'] as String);
                          setState(() => _notifications[i] = {...n, 'is_read': true});
                        },
                      );
                    },
                  )),
    );
  }
}
