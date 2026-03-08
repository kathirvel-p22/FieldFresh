import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';
import 'farmers_list_screen.dart';
import 'customers_list_screen.dart';
import 'all_orders_screen.dart';
import 'all_products_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await SupabaseService.getAdminStats();
      setState(() {
        _stats = s;
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.dark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await SupabaseService.signOut();
                if (context.mounted) context.go(AppRoutes.roleSelect);
              }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: [
                              _AdminStat(
                                  'Farmers',
                                  '${_stats['totalFarmers'] ?? 0}',
                                  '👨‍🌾',
                                  AppColors.secondary),
                              _AdminStat(
                                  'Customers',
                                  '${_stats['totalCustomers'] ?? 0}',
                                  '🛒',
                                  AppColors.primary),
                              _AdminStat(
                                  'Orders',
                                  '${_stats['totalOrders'] ?? 0}',
                                  '📦',
                                  AppColors.warning),
                              _AdminStat(
                                  'Revenue',
                                  '₹${((_stats['platformRevenue'] ?? 0.0) / 1000).toStringAsFixed(1)}K',
                                  '💰',
                                  AppColors.success),
                            ]),
                        const SizedBox(height: 20),
                        const Text('Monthly GMV (₹K)',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                                child: SizedBox(
                                    height: 180,
                                    child: BarChart(BarChartData(
                                      barGroups: [
                                        _bar(0, 45),
                                        _bar(1, 67),
                                        _bar(2, 82),
                                        _bar(3, 91),
                                        _bar(4, 78),
                                        _bar(5, 120),
                                        _bar(6, 145),
                                      ],
                                      gridData: const FlGridData(
                                          show: true, drawVerticalLine: false),
                                      borderData: FlBorderData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (v, _) {
                                                  const m = [
                                                    'Jan',
                                                    'Feb',
                                                    'Mar',
                                                    'Apr',
                                                    'May',
                                                    'Jun',
                                                    'Jul'
                                                  ];
                                                  return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Text(m[v.toInt()],
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: AppColors
                                                                  .textSecondary)));
                                                })),
                                      ),
                                    ))))),
                        const SizedBox(height: 20),
                        const Text('Quick Actions',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.15,
                            children: [
                              _AdminAction('View Farmers', Icons.people,
                                  AppColors.secondary, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const FarmersListScreen()));
                              }),
                              _AdminAction('View Customers', Icons.shopping_bag,
                                  AppColors.primary, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const CustomersListScreen()));
                              }),
                              _AdminAction('All Orders', Icons.list_alt,
                                  AppColors.warning, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AllOrdersScreen()));
                              }),
                              _AdminAction('All Products', Icons.inventory_2,
                                  AppColors.info, () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const AllProductsScreen()));
                              }),
                              _AdminAction('Analytics', Icons.analytics,
                                  AppColors.accent, () {}),
                              _AdminAction('Settings', Icons.settings,
                                  AppColors.textSecondary, () {}),
                            ]),
                        const SizedBox(height: 20),
                      ]))),
    );
  }

  BarChartGroupData _bar(int x, double y) => BarChartGroupData(x: x, barRods: [
        BarChartRodData(
            toY: y,
            color: AppColors.primary,
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
      ]);
}

class _AdminStat extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _AdminStat(this.label, this.value, this.emoji, this.color);
  @override
  Widget build(BuildContext context) => Container(
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
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle))
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ]));
}

class _AdminAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _AdminAction(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ])));
}
