import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';

class PlatformTransactionsScreen extends StatefulWidget {
  const PlatformTransactionsScreen({super.key});

  @override
  State<PlatformTransactionsScreen> createState() => _PlatformTransactionsScreenState();
}

class _PlatformTransactionsScreenState extends State<PlatformTransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  double _totalPlatformFees = 0;
  double _totalOrderAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    try {
      final data = await Supabase.instance.client
          .from('platform_transactions')
          .select('*')
          .order('created_at', ascending: false);

      double totalFees = 0;
      double totalOrders = 0;
      for (final tx in data) {
        totalFees += (tx['platform_fee'] as num).toDouble();
        totalOrders += (tx['order_amount'] as num).toDouble();
      }

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(data);
        _totalPlatformFees = totalFees;
        _totalOrderAmount = totalOrders;
        _loading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Platform Revenue'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Orders',
                          '₹${_totalOrderAmount.toStringAsFixed(0)}',
                          Icons.shopping_cart,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Platform Fees',
                          '₹${_totalPlatformFees.toStringAsFixed(0)}',
                          Icons.account_balance_wallet,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Transactions List
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.receipt_long, size: 64, color: AppColors.textHint),
                                const SizedBox(height: 16),
                                const Text('No Platform Transactions Yet', 
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text(
                                  'Platform transactions are created when customers confirm delivery.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                                  ),
                                  child: const Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline, color: AppColors.info, size: 20),
                                          SizedBox(width: 8),
                                          Text('Have existing delivered orders?', 
                                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'If you have orders marked as "delivered" before this system was set up, you need to run a one-time SQL script in Supabase to create their platform transactions.\n\nCheck FIX_REVENUE_TAB.md for instructions.',
                                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _loadTransactions,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTransactions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              return _buildTransactionCard(tx);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final orderAmount = (tx['order_amount'] as num).toDouble();
    final platformFee = (tx['platform_fee'] as num).toDouble();
    final farmerReceives = (tx['farmer_receives'] as num).toDouble();
    final createdAt = DateTime.parse(tx['created_at']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['product_name'] ?? 'Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${(tx['order_id'] as String).substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DELIVERED',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Customer & Farmer
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Customer:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        tx['customer_name'] ?? 'Customer',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Farmer:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        tx['farmer_name'] ?? 'Farmer',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Financial Breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildFinanceRow('Order Amount:', '₹${orderAmount.toStringAsFixed(0)}', false),
                  const SizedBox(height: 4),
                  _buildFinanceRow('Platform Fee (5%):', '₹${platformFee.toStringAsFixed(0)}', false, color: AppColors.success),
                  const SizedBox(height: 4),
                  _buildFinanceRow('Farmer Receives:', '₹${farmerReceives.toStringAsFixed(0)}', false, color: AppColors.primary),
                  const Divider(height: 16),
                  _buildFinanceRow('Platform Earns:', '₹${platformFee.toStringAsFixed(0)}', true, color: AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, String amount, bool isBold, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
