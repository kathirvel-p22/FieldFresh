import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/payment_service.dart';
import '../../../services/supabase_service.dart';
import '../order/manage_bank_accounts_screen.dart';

class CustomerWalletScreen extends StatefulWidget {
  const CustomerWalletScreen({super.key});
  @override
  State<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends State<CustomerWalletScreen> {
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  double _totalSpent = 0;
  double _thisMonthSpent = 0;
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId == null) {
        setState(() => _loading = false);
        return;
      }

      // Load bank accounts
      final accounts = await PaymentService.getBankAccounts(customerId);
      
      // Load payment history
      final transactions = await PaymentService.getPaymentHistory(customerId);

      // Calculate spending stats
      double totalSpent = 0;
      double thisMonth = 0;
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      for (final txn in transactions) {
        final amount = (txn['amount'] as num).toDouble();
        totalSpent += amount;

        final txnDate = DateTime.parse(txn['created_at']);
        if (txnDate.isAfter(firstDayOfMonth)) {
          thisMonth += amount;
        }
      }

      setState(() {
        _bankAccounts = accounts;
        _transactions = transactions;
        _totalSpent = totalSpent;
        _thisMonthSpent = thisMonth;
        _orderCount = transactions.length;
        _loading = false;
      });
    } catch (e) {
      print('Error loading wallet data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWalletData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bank Accounts Section
                    _buildBankAccountsSection(),
                    const SizedBox(height: 20),
                    
                    // Spending Stats
                    _buildSpendingStats(),
                    const SizedBox(height: 20),
                    
                    // Transaction History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_transactions.length} transactions',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_transactions.isEmpty)
                      _buildEmptyState()
                    else
                      ..._transactions.map((txn) => _buildTransactionTile(txn)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBankAccountsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Bank Accounts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageBankAccountsScreen(),
                      ),
                    ).then((_) => _loadWalletData());
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const Divider(height: 20),
            
            if (_bankAccounts.isEmpty)
              Column(
                children: [
                  const Text(
                    'No bank accounts added',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageBankAccountsScreen(),
                        ),
                      ).then((_) => _loadWalletData());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Bank Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              )
            else
              ..._bankAccounts.map((account) => _buildBankAccountCard(account)),
          ],
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(Map<String, dynamic> account) {
    final balance = (account['balance'] as num).toDouble();
    final isPrimary = account['is_primary'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isPrimary 
            ? LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
              )
            : null,
        color: isPrimary ? null : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account['bank_name'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPrimary ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '****${account['account_number'].toString().substring(account['account_number'].toString().length - 4)}',
            style: TextStyle(
              fontSize: 14,
              color: isPrimary ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 12,
                  color: isPrimary ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Spent',
            '₹${_totalSpent.toStringAsFixed(0)}',
            Icons.shopping_cart,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'This Month',
            '₹${_thisMonthSpent.toStringAsFixed(0)}',
            Icons.calendar_month,
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Orders',
            '$_orderCount',
            Icons.receipt_long,
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> txn) {
    final amount = (txn['amount'] as num).toDouble();
    final createdAt = DateTime.parse(txn['created_at']);
    final orders = txn['orders'] as Map<String, dynamic>?;
    final productName = orders?['product_name'] ?? 'Product';
    final quantity = orders?['quantity'] ?? 0;
    final unit = orders?['unit'] ?? 'kg';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          child: const Icon(
            Icons.arrow_upward,
            color: AppColors.error,
            size: 20,
          ),
        ),
        title: Text(
          productName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$quantity $unit',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Text(
          '-₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your purchase history will appear here',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
