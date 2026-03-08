import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants.dart';
import '../../../services/payment_service.dart';
import '../../../services/supabase_service.dart';

class ManageBankAccountsScreen extends StatefulWidget {
  const ManageBankAccountsScreen({super.key});

  @override
  State<ManageBankAccountsScreen> createState() => _ManageBankAccountsScreenState();
}

class _ManageBankAccountsScreenState extends State<ManageBankAccountsScreen> {
  List<Map<String, dynamic>> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        final accounts = await PaymentService.getBankAccounts(customerId);
        setState(() {
          _accounts = accounts;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() => _loading = false);
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddBankAccountDialog(),
    ).then((_) => _loadAccounts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏦', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 12),
                      const Text('No bank accounts added',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showAddAccountDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bank Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _accounts.length,
                  itemBuilder: (context, index) {
                    final account = _accounts[index];
                    return _buildAccountCard(account);
                  },
                ),
      floatingActionButton: _accounts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddAccountDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            )
          : null,
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final isPrimary = account['is_primary'] == true;
    final isVerified = account['is_verified'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            account['bank_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRIMARY',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account['account_holder_name'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isVerified)
                  const Icon(Icons.verified, color: AppColors.success, size: 20),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Number',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '****${account['account_number'].toString().substring(account['account_number'].toString().length - 4)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      '₹${(account['balance'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'IFSC: ',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                Text(
                  account['ifsc_code'],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (!isPrimary) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final customerId = SupabaseService.currentUserId;
                    if (customerId != null) {
                      await PaymentService.setPrimaryAccount(
                          customerId, account['id']);
                      _loadAccounts();
                    }
                  },
                  child: const Text('Set as Primary'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddBankAccountDialog extends StatefulWidget {
  const AddBankAccountDialog({super.key});

  @override
  State<AddBankAccountDialog> createState() => _AddBankAccountDialogState();
}

class _AddBankAccountDialogState extends State<AddBankAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  String _accountType = 'savings';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  Future<void> _addAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        await PaymentService.addBankAccount(
          customerId: customerId,
          accountHolderName: _nameCtrl.text.trim(),
          accountNumber: _accountCtrl.text.trim(),
          ifscCode: _ifscCtrl.text.trim().toUpperCase(),
          bankName: _bankCtrl.text.trim(),
          accountType: _accountType,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Bank account added successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bank Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Account Number *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ifscCtrl,
                decoration: const InputDecoration(
                  labelText: 'IFSC Code *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bank Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'savings', child: Text('Savings')),
                  DropdownMenuItem(value: 'current', child: Text('Current')),
                ],
                onChanged: (value) {
                  setState(() => _accountType = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _addAccount,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Account'),
        ),
      ],
    );
  }
}
