import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class FarmerWalletScreen extends StatefulWidget {
  const FarmerWalletScreen({super.key});
  @override
  State<FarmerWalletScreen> createState() => _FarmerWalletScreenState();
}

class _FarmerWalletScreenState extends State<FarmerWalletScreen> {
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final id = SupabaseService.currentUserId;
    if (id == null) { setState(() => _loading = false); return; }
    try {
      final w = await SupabaseService.getFarmerWallet(id);
      final t = await SupabaseService.getWalletTransactions(id);
      setState(() { _wallet = w; _txns = t; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet'), backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
      body: _loading ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(onRefresh: _load, child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(children: [
            // Balance card
            Container(width: double.infinity, padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(gradient: AppColors.farmerGradient, borderRadius: BorderRadius.circular(AppSizes.radiusXL)),
              child: Column(children: [
                const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('₹ ${(_wallet?['balance'] ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '95% of order amount (5% platform fee)',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💰 Withdrawal request sent to UPI!'))),
                  icon: const Icon(Icons.account_balance, size: 18),
                  label: const Text('Withdraw to UPI / Bank'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                ),
              ])),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _WalletStat('Total Earned', '₹${(_wallet?['total_earned'] ?? 0).toStringAsFixed(0)}', Icons.trending_up, AppColors.success)),
              const SizedBox(width: 12),
              Expanded(child: _WalletStat('This Month', '₹${(_wallet?['this_month'] ?? 0).toStringAsFixed(0)}', Icons.calendar_month, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _WalletStat('Orders', '${_wallet?['order_count'] ?? 0}', Icons.shopping_bag, AppColors.accent)),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Transactions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              TextButton(onPressed: () {}, child: const Text('See All')),
            ]),
            if (_txns.isEmpty)
              const Padding(padding: EdgeInsets.all(32),
                child: Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary)))
            else
              ..._txns.map((t) => _TxnTile(t)),
          ]),
        )),
    );
  }
}

class _WalletStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _WalletStat(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]));
}

class _TxnTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TxnTile(this.txn);
  @override
  Widget build(BuildContext context) {
    final isCredit = (txn['type'] ?? 'credit') == 'credit';
    final color = isCredit ? AppColors.success : AppColors.error;
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1),
          child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18)),
      title: Text(txn['description'] ?? 'Transaction', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(txn['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 11)),
      trailing: Text('${isCredit ? '+' : '-'}₹${txn['amount'] ?? 0}',
          style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    );
  }
}
