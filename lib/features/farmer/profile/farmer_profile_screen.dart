import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';
import 'sales_analytics_screen.dart';
import 'my_listings_screen.dart';
import 'customer_reviews_screen.dart';
import '../wallet/bank_upi_settings_screen.dart';
import '../orders/farmer_orders_screen.dart';
import '../customers/all_customers_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});
  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrderStats();
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

  Future<void> _loadOrderStats() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        final orders = await SupabaseService.getFarmerOrders(userId);
        setState(() {
          _totalOrders = orders.length;
        });
      }
    } catch (e) {
      print('Error loading order stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['name'] ?? 'Farmer';
    final userPhone = _userData?['phone'] ?? '';
    final profileImage = _userData?['profile_image'];
    final rating = (_userData?['rating'] as num?)?.toDouble() ?? 0.0;
    final isVerified = _userData?['is_verified'] ?? false;
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
            height: 260,
            decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
            child: SafeArea(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              profileImage != null
                                  ? CircleAvatar(
                                      radius: 46,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: CachedNetworkImageProvider(profileImage),
                                    )
                                  : const CircleAvatar(
                                      radius: 46,
                                      backgroundColor: Colors.white24,
                                      child: Text('👨‍🌾', style: TextStyle(fontSize: 42))),
                              if (isVerified)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified, color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(userPhone,
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(' ${rating.toStringAsFixed(1)}  ',
                                style: const TextStyle(color: Colors.white)),
                            Text('• $_totalOrders Orders  ',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const Text('• Active',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                          ]),
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
              _MenuItem(Icons.shopping_bag_outlined, 'Customer Orders',
                  'View & manage orders', AppColors.success, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FarmerOrdersScreen()));
              }),
              _MenuItem(Icons.people_outline, 'All Customers',
                  'View customer profiles', AppColors.info, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AllCustomersScreen()));
              }),
              _MenuItem(Icons.analytics_outlined, 'Sales Analytics',
                  'View your performance charts', AppColors.primary, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SalesAnalyticsScreen()));
              }),
              _MenuItem(Icons.inventory_2_outlined, 'My Listings',
                  'Manage all your products', AppColors.secondary, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyListingsScreen()));
              }),
              _MenuItem(Icons.star_border, 'Customer Reviews',
                  'See what customers say', AppColors.accent, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerReviewsScreen()));
              }),
              _MenuItem(Icons.account_balance_outlined, 'Bank / UPI Settings',
                  'Manage payout methods', AppColors.info, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BankUpiSettingsScreen()));
              }),
              _MenuItem(Icons.verified_user_outlined, 'KYC Documents',
                  'Aadhaar & farm docs', AppColors.warning, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('KYC Documents feature coming soon')),
                );
              }),
              _MenuItem(Icons.language, 'Language', 'Tamil / Hindi / English',
                  AppColors.textSecondary, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Language settings coming soon')),
                );
              }),
              _MenuItem(Icons.headset_mic, 'Help & Support',
                  'Chat with our team', AppColors.textSecondary, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon')),
                );
              }),
              Card(
                  margin: const EdgeInsets.only(bottom: 8),
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
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.title, this.subtitle, this.color, this.onTap);
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
