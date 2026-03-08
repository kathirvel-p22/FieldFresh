import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class BankUpiSettingsScreen extends StatefulWidget {
  const BankUpiSettingsScreen({super.key});
  @override
  State<BankUpiSettingsScreen> createState() => _BankUpiSettingsScreenState();
}

class _BankUpiSettingsScreenState extends State<BankUpiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiIdCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  String _paymentMethod = 'upi'; // upi or bank
  bool _loading = false;
  bool _hasSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _upiIdCtrl.dispose();
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _bankNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final farmerId = SupabaseService.currentUserId;
      if (farmerId == null) return;

      // Load payment settings from database
      final client = Supabase.instance.client;
      final settings = await client
          .from('payment_settings')
          .select('*')
          .eq('farmer_id', farmerId)
          .maybeSingle();

      if (settings != null) {
        setState(() {
          _hasSettings = true;
          _paymentMethod = settings['payment_method'] ?? 'upi';
          _upiIdCtrl.text = settings['upi_id'] ?? '';
          _accountNameCtrl.text = settings['account_name'] ?? '';
          _accountNumberCtrl.text = settings['account_number'] ?? '';
          _ifscCtrl.text = settings['ifsc_code'] ?? '';
          _bankNameCtrl.text = settings['bank_name'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final farmerId = SupabaseService.currentUserId;
      if (farmerId == null) return;

      final settings = {
        'farmer_id': farmerId,
        'payment_method': _paymentMethod,
        'upi_id': _paymentMethod == 'upi' ? _upiIdCtrl.text.trim() : null,
        'account_name':
            _paymentMethod == 'bank' ? _accountNameCtrl.text.trim() : null,
        'account_number':
            _paymentMethod == 'bank' ? _accountNumberCtrl.text.trim() : null,
        'ifsc_code': _paymentMethod == 'bank' ? _ifscCtrl.text.trim() : null,
        'bank_name':
            _paymentMethod == 'bank' ? _bankNameCtrl.text.trim() : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client.from('payment_settings').upsert(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bank / UPI Settings'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveSettings,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _loading && !_hasSettings
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add your payment details to receive payouts from completed orders',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Selection
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentMethodCard(
                            icon: Icons.account_balance_wallet,
                            title: 'UPI',
                            subtitle: 'Instant transfer',
                            selected: _paymentMethod == 'upi',
                            onTap: () => setState(() => _paymentMethod = 'upi'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentMethodCard(
                            icon: Icons.account_balance,
                            title: 'Bank Account',
                            subtitle: '1-2 business days',
                            selected: _paymentMethod == 'bank',
                            onTap: () =>
                                setState(() => _paymentMethod = 'bank'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // UPI Form
                    if (_paymentMethod == 'upi') ...[
                      const Text(
                        'UPI Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _upiIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'UPI ID *',
                          hintText: 'yourname@paytm',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'UPI ID is required';
                          }
                          if (!v.contains('@')) {
                            return 'Invalid UPI ID format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'UPI payments are instant and have 0% transaction fee',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Bank Form
                    if (_paymentMethod == 'bank') ...[
                      const Text(
                        'Bank Account Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accountNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Account Holder Name *',
                          hintText: 'As per bank records',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Account name is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _accountNumberCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Account Number *',
                          hintText: 'Enter account number',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Account number is required';
                          }
                          if (v.length < 9 || v.length > 18) {
                            return 'Invalid account number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ifscCtrl,
                        decoration: const InputDecoration(
                          labelText: 'IFSC Code *',
                          hintText: 'e.g. SBIN0001234',
                          prefixIcon: Icon(Icons.code),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'IFSC code is required';
                          }
                          if (v.length != 11) {
                            return 'IFSC code must be 11 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bankNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bank Name *',
                          hintText: 'e.g. State Bank of India',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Bank name is required'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Payment Settings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: selected ? AppColors.secondary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.secondary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: selected ? AppColors.secondary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
