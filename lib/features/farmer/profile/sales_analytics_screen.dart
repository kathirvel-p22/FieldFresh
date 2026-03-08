import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});
  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  Map<String, dynamic> _analytics = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      final farmerId = SupabaseService.currentUserId;
      if (farmerId == null) return;

      final orders = await SupabaseService.getFarmerOrders(farmerId);
      final products = await SupabaseService.getFarmerProducts(farmerId);

      // Calculate analytics
      final totalOrders = orders.length;
      final completedOrders =
          orders.where((o) => o.status == 'delivered').length;
      final pendingOrders = orders.where((o) => o.status == 'pending').length;
      final cancelledOrders =
          orders.where((o) => o.status == 'cancelled').length;

      // Calculate farmer's actual earnings (95% after 5% platform fee)
      final totalRevenue = orders
          .where((o) => o.status == 'delivered')
          .fold<double>(0, (sum, o) => sum + (o.totalAmount * 0.95));

      final activeProducts = products.where((p) => p.isActive).length;
      final soldOutProducts = products.where((p) => p.isSoldOut).length;

      // Category-wise sales (farmer's earnings)
      final Map<String, double> categorySales = {};
      for (final order in orders.where((o) => o.status == 'delivered')) {
        final product = products.firstWhere((p) => p.id == order.productId,
            orElse: () => products.first);
        final farmerEarns = order.totalAmount * 0.95; // 95% after platform fee
        categorySales[product.category] =
            (categorySales[product.category] ?? 0) + farmerEarns;
      }

      setState(() {
        _analytics = {
          'totalOrders': totalOrders,
          'completedOrders': completedOrders,
          'pendingOrders': pendingOrders,
          'cancelledOrders': cancelledOrders,
          'totalRevenue': totalRevenue,
          'activeProducts': activeProducts,
          'soldOutProducts': soldOutProducts,
          'categorySales': categorySales,
          'avgOrderValue': totalOrders > 0 ? totalRevenue / completedOrders : 0,
          'completionRate':
              totalOrders > 0 ? (completedOrders / totalOrders * 100) : 0,
        };
        _loading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenue Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.farmerGradient,
                        borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Revenue',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${(_analytics['totalRevenue'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatChip(
                                '${_analytics['completedOrders'] ?? 0} Orders',
                                Icons.check_circle,
                              ),
                              const SizedBox(width: 8),
                              _StatChip(
                                '${(_analytics['completionRate'] ?? 0).toStringAsFixed(1)}% Success',
                                Icons.trending_up,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          'Total Orders',
                          '${_analytics['totalOrders'] ?? 0}',
                          Icons.shopping_bag,
                          AppColors.primary,
                        ),
                        _StatCard(
                          'Pending',
                          '${_analytics['pendingOrders'] ?? 0}',
                          Icons.pending_actions,
                          AppColors.warning,
                        ),
                        _StatCard(
                          'Active Products',
                          '${_analytics['activeProducts'] ?? 0}',
                          Icons.inventory_2,
                          AppColors.success,
                        ),
                        _StatCard(
                          'Avg Order Value',
                          '₹${(_analytics['avgOrderValue'] ?? 0).toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          AppColors.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Sales
                    const Text(
                      'Category-wise Sales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if ((_analytics['categorySales'] as Map<String, double>)
                        .isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'No sales data yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...(_analytics['categorySales'] as Map<String, double>)
                          .entries
                          .map((entry) => _CategorySalesTile(
                                category: entry.key,
                                amount: entry.value,
                                total: _analytics['totalRevenue'] as double,
                              )),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySalesTile extends StatelessWidget {
  final String category;
  final double amount;
  final double total;
  const _CategorySalesTile({
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (amount / total * 100) : 0;
    final categoryIcons = {
      'vegetables': '🥦',
      'fruits': '🍎',
      'dairy': '🥛',
      'grains': '🌾',
      'herbs': '🌿',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                categoryIcons[category] ?? '🌱',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
