import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants.dart';
import '../../../models/order_model.dart';
import '../../../services/payment_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/supabase_service.dart';
import 'payment_success_screen.dart';
import 'manage_bank_accounts_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Map<String, dynamic>> _bankAccounts = [];
  String? _selectedAccountId;
  bool _loading = true;
  bool _processing = false;
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
    _checkPINSetup();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        final accounts = await PaymentService.getBankAccounts(customerId);
        setState(() {
          _bankAccounts = accounts;
          // Auto-select primary account
          _selectedAccountId = accounts.firstWhere(
            (acc) => acc['is_primary'] == true,
            orElse: () => accounts.isNotEmpty ? accounts.first : {},
          )['id'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _checkPINSetup() async {
    final customerId = SupabaseService.currentUserId;
    if (customerId != null) {
      final hasPIN = await PaymentService.hasPINSet(customerId);
      if (!hasPIN && mounted) {
        _showSetPINDialog();
      }
    }
  }

  void _showSetPINDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SetPINDialog(),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank account')),
      );
      return;
    }

    // Make address optional with default value
    final deliveryAddress = _addressCtrl.text.trim().isEmpty 
        ? 'Valasaravakkam, Chennai, Tamil Nadu' 
        : _addressCtrl.text.trim();

    // Show PIN verification dialog
    final pinVerified = await showDialog<bool>(
      context: context,
      builder: (context) => const VerifyPINDialog(),
    );

    if (pinVerified != true) return;

    setState(() => _processing = true);

    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId == null) {
        throw Exception('User not logged in');
      }

      final total = CartService.calculateCartTotal(widget.cartItems);

      // Create orders for each item (grouped by farmer)
      final farmerOrders = <String, List<Map<String, dynamic>>>{};
      for (final item in widget.cartItems) {
        final product = item['products'] as Map<String, dynamic>;
        final farmerId = product['farmer_id'] as String?;
        
        if (farmerId == null || farmerId.isEmpty) {
          throw Exception('Product ${product['name']} has no farmer_id');
        }
        
        farmerOrders.putIfAbsent(farmerId, () => []).add(item);
      }

      print('Processing orders for ${farmerOrders.length} farmers');

      // Get customer details
      final customerData = await SupabaseService.getUser(customerId);
      final customerName = customerData?.name ?? 'Customer';
      final customerPhone = customerData?.phone ?? '';

      // Process each farmer's order
      for (final entry in farmerOrders.entries) {
        final farmerId = entry.key;
        final items = entry.value;

        print('Processing ${items.length} items for farmer $farmerId');

        for (final item in items) {
          final product = item['products'] as Map<String, dynamic>;
          final quantity = (item['quantity'] as num).toDouble();
          final pricePerUnit = (item['price_per_unit'] as num).toDouble();
          final itemTotal = quantity * pricePerUnit;

          print('Creating order for product: ${product['name']}, quantity: $quantity, total: $itemTotal');

          // Create order
          final order = OrderModel(
            id: '',
            customerId: customerId,
            customerName: customerName,
            customerPhone: customerPhone,
            farmerId: farmerId,
            productId: product['id'],
            productName: product['name'],
            quantity: quantity,
            unit: item['unit'],
            pricePerUnit: pricePerUnit,
            totalAmount: itemTotal,
            deliveryType: 'delivery',
            deliveryAddress: deliveryAddress,
            status: 'pending',
            paymentStatus: 'pending',
            createdAt: DateTime.now(),
          );

          print('Placing order...');
          final orderData = await SupabaseService.placeOrder(order);
          print('Order placed successfully: ${orderData.id}');

          // Process payment
          print('Processing payment...');
          final paymentResult = await PaymentService.processPayment(
            orderId: orderData.id,
            customerId: customerId,
            farmerId: farmerId,
            bankAccountId: _selectedAccountId!,
            amount: itemTotal,
          );

          print('Payment result: ${paymentResult['success']}');

          if (!paymentResult['success']) {
            throw Exception(paymentResult['message']);
          }
        }
      }

      // Clear cart
      await CartService.clearCart(customerId);

      setState(() => _processing = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              amount: total,
              itemCount: widget.cartItems.length,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _processing = false);
      print('Payment error: $e'); // Debug print
      if (mounted) {
        // Show error in a dialog instead of snackbar for better visibility
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                SizedBox(width: 8),
                Text('Payment Failed'),
              ],
            ),
            content: Text(
              e.toString(),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = CartService.calculateCartTotal(widget.cartItems);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  _buildSection(
                    'Order Summary',
                    Icons.shopping_bag,
                    _buildOrderSummary(),
                  ),
                  const SizedBox(height: 16),
                  // Delivery Address
                  _buildSection(
                    'Delivery Address',
                    Icons.location_on,
                    _buildAddressInput(),
                  ),
                  const SizedBox(height: 16),
                  // Payment Method
                  _buildSection(
                    'Payment Method',
                    Icons.payment,
                    _buildPaymentMethod(),
                  ),
                  const SizedBox(height: 16),
                  // Price Breakdown
                  _buildPriceBreakdown(total),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomBar(total),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      children: widget.cartItems.map((item) {
        final product = item['products'] as Map<String, dynamic>;
        final quantity = (item['quantity'] as num).toDouble();
        final pricePerUnit = (item['price_per_unit'] as num).toDouble();
        final itemTotal = quantity * pricePerUnit;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${product['name']} (${quantity.toStringAsFixed(0)} ${item['unit']})',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                '₹${itemTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddressInput() {
    return TextField(
      controller: _addressCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Enter your delivery address...',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    if (_bankAccounts.isEmpty) {
      return Column(
        children: [
          const Text('No bank account added'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageBankAccountsScreen(),
                ),
              ).then((_) => _loadBankAccounts());
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Bank Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ..._bankAccounts.map((account) {
          final isSelected = account['id'] == _selectedAccountId;
          return RadioListTile<String>(
            value: account['id'],
            groupValue: _selectedAccountId,
            onChanged: (value) {
              setState(() => _selectedAccountId = value);
            },
            title: Text(
              account['bank_name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '****${account['account_number'].toString().substring(account['account_number'].toString().length - 4)}\nBalance: ₹${(account['balance'] as num).toStringAsFixed(2)}',
            ),
            secondary: Icon(
              Icons.account_balance,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageBankAccountsScreen(),
              ),
            ).then((_) => _loadBankAccounts());
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Another Account'),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _priceRow('Subtotal', total),
            _priceRow('Delivery Fee', 0),
            _priceRow('Tax', 0),
            const Divider(height: 20),
            _priceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _processing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _processing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Pay ₹${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Set PIN Dialog
class SetPINDialog extends StatefulWidget {
  const SetPINDialog({super.key});

  @override
  State<SetPINDialog> createState() => _SetPINDialogState();
}

class _SetPINDialogState extends State<SetPINDialog> {
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _setPIN() async {
    if (_pinCtrl.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 digits')),
      );
      return;
    }

    if (_pinCtrl.text != _confirmPinCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        await PaymentService.setPaymentPIN(customerId, _pinCtrl.text);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Payment PIN set successfully')),
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
      title: const Text('Set Payment PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create a 4-digit PIN to secure your payments',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Enter PIN',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmPinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _setPIN,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Set PIN'),
        ),
      ],
    );
  }
}

// Verify PIN Dialog
class VerifyPINDialog extends StatefulWidget {
  const VerifyPINDialog({super.key});

  @override
  State<VerifyPINDialog> createState() => _VerifyPINDialogState();
}

class _VerifyPINDialogState extends State<VerifyPINDialog> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPIN() async {
    if (_pinCtrl.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be 4 digits')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId != null) {
        final isValid =
            await PaymentService.verifyPaymentPIN(customerId, _pinCtrl.text);
        if (isValid) {
          if (mounted) Navigator.pop(context, true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Incorrect PIN')),
            );
          }
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
      title: const Text('Enter Payment PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your 4-digit PIN to confirm payment',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Payment PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _verifyPIN(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _verifyPIN,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
