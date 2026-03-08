import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';
import 'post_product/post_product_screen.dart';
import 'orders/farmer_orders_screen.dart';
import 'wallet/farmer_wallet_screen.dart';
import 'profile/farmer_profile_screen.dart';
import '../community/groups_list_screen.dart';

class FarmerHome extends StatefulWidget {
  const FarmerHome({super.key});
  @override
  State<FarmerHome> createState() => _FarmerHomeState();
}

class _FarmerHomeState extends State<FarmerHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _FarmerDashboard(),
      const PostProductScreen(),
      const FarmerOrdersScreen(),
      const FarmerWalletScreen(),
      const GroupsListScreen(), // Community Groups
      const FarmerProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Post'),
          NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Community'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _FarmerDashboard extends StatefulWidget {
  const _FarmerDashboard();
  @override
  State<_FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<_FarmerDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final products = await SupabaseService.getFarmerProducts(userId);
      final orders = await SupabaseService.getFarmerOrders(userId);
      // Calculate farmer's actual earnings (95% after 5% platform fee)
      final revenue = orders
          .where((o) => o.status == 'delivered')
          .fold<double>(0, (s, o) => s + (o.totalAmount * 0.95));
      setState(() {
        _stats = {
          'activeProducts': products.where((p) => p.isActive).length,
          'totalOrders': orders.length,
          'pendingOrders': orders.where((o) => o.status == 'pending').length,
          'revenue': revenue,
        };
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.farmerGradient),
                child: SafeArea(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Good Morning 👋',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Farmer Dashboard',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Market is live!',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.farmerLiveStream),
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.videocam,
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Go Live',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ])),
                          ),
                        ]),
                      ]),
                )),
              ),
              title: const Text('Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            backgroundColor: AppColors.secondary,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                        'Active Listings',
                        '${_stats['activeProducts'] ?? 0}',
                        Icons.inventory_2,
                        AppColors.primary),
                    _StatCard('Total Orders', '${_stats['totalOrders'] ?? 0}',
                        Icons.shopping_bag, AppColors.secondary),
                    _StatCard('Pending', '${_stats['pendingOrders'] ?? 0}',
                        Icons.pending_actions, AppColors.warning),
                    _StatCard(
                        'Revenue',
                        '₹${(_stats['revenue'] ?? 0.0).toStringAsFixed(0)}',
                        Icons.currency_rupee,
                        AppColors.success),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Quick Actions',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _ActionBtn(
                          'Post Harvest', '🌾', AppColors.secondary, () {})),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _ActionBtn('Go Live', '📹', AppColors.error,
                          () => context.go(AppRoutes.farmerLiveStream))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _ActionBtn(
                          'Analytics', '📊', AppColors.primary, () {})),
                ]),
                const SizedBox(height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Live Orders',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle)),
                    ]),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: SupabaseService.listenToFarmerOrders(
                      SupabaseService.currentUserId ?? ''),
                  builder: (ctx, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    if (snap.data!.isEmpty) return _EmptyOrders();
                    return Column(
                      children: snap.data!
                          .take(5)
                          .map((o) => _LiveOrderTile(o))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ])),
          ),
        ]),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL)),
      child: const Column(children: [
        Text('📦', style: TextStyle(fontSize: 48)),
        SizedBox(height: 8),
        Text('No orders yet. Post your harvest!',
            style: TextStyle(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label, emoji;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.emoji, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            border: Border.all(color: color.withOpacity(0.25))),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _LiveOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _LiveOrderTile(this.order);
  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final colors = {
      'pending': AppColors.warning,
      'confirmed': AppColors.primary,
      'packed': AppColors.info,
      'dispatched': AppColors.accent,
      'delivered': AppColors.success,
      'cancelled': AppColors.error
    };
    final c = colors[status] ?? AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: c.withOpacity(0.25))),
      child: Row(children: [
        Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
                color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(order['product_name'] ?? 'Product',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
              '₹${order['total_amount']} • ${order['delivery_type'] ?? 'delivery'}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status.toUpperCase(),
                style: TextStyle(
                    fontSize: 10, color: c, fontWeight: FontWeight.bold))),
      ]),
    );
  }
}
