import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';
import 'notification_preferences_screen.dart';
import 'saved_farmers_screen.dart';
import 'delivery_addresses_screen.dart';
import '../order/customer_orders_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});
  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        final user = await SupabaseService.getUser(userId);
        setState(() {
          _userData = user?.toJson();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['name'] ?? 'Customer';
    final userPhone = _userData?['phone'] ?? '';
    final profileImage = _userData?['profile_image'];
    final rating = (_userData?['rating'] as num?)?.toDouble() ?? 0.0;
    final village = _userData?['village'] ?? '';
    final city = _userData?['city'] ?? '';
    final district = _userData?['district'] ?? '';
    final state = _userData?['state'] ?? '';
    
    // Build location string
    String locationStr = '';
    if (village.isNotEmpty) locationStr += village;
    if (city.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + city;
    if (district.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + district;
    if (state.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + state;
    if (locationStr.isEmpty) locationStr = 'Location not set';

    return Scaffold(
      body: ListView(children: [
        Container(
            height: 240,
            decoration:
                const BoxDecoration(gradient: AppColors.customerGradient),
            child: SafeArea(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          profileImage != null
                              ? CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: CachedNetworkImageProvider(profileImage),
                                )
                              : const CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.white24,
                                  child: Text('👤', style: TextStyle(fontSize: 40))),
                          const SizedBox(height: 8),
                          Text(userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(userPhone,
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${rating.toStringAsFixed(1)} Rating',
                                  style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    locationStr,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]))),
        Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(children: [
              _Tile(Icons.notifications_outlined, 'Notification Preferences',
                  'Alerts & harvest blasts', AppColors.warning, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationPreferencesScreen()));
              }),
              _Tile(Icons.favorite_border, 'Saved Farmers',
                  'Your favourite farms', AppColors.error, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SavedFarmersScreen()));
              }),
              _Tile(Icons.history, 'Order History', 'All past orders',
                  AppColors.primary, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerOrdersScreen()));
              }),
              _Tile(Icons.location_on_outlined, 'Delivery Addresses',
                  'Manage saved addresses', AppColors.secondary, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DeliveryAddressesScreen()));
              }),
              _Tile(Icons.people_outline, 'Group Buys', 'Active group orders',
                  AppColors.info, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Group Buys - Check Group Buy tab')),
                );
              }),
              _Tile(Icons.language, 'Language', 'Tamil / Hindi / English',
                  AppColors.accent, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Language settings coming soon')),
                );
              }),
              _Tile(Icons.headset_mic_outlined, 'Help & Support',
                  'Chat or call us', AppColors.textSecondary, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon')),
                );
              }),
              const Divider(height: 20),
              Card(
                  child: ListTile(
                leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.logout,
                        color: AppColors.error, size: 20)),
                title: const Text('Sign Out',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textHint),
                onTap: () async {
                  await SupabaseService.signOut();
                  if (context.mounted) context.go(AppRoutes.roleSelect);
                },
              )),
            ])),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _Tile(this.icon, this.title, this.subtitle, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppColors.textHint),
        onTap: onTap,
      ));
}
