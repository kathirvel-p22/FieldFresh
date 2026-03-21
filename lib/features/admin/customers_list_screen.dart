import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});
  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllCustomers();
      print('Loaded ${data.length} customers'); // Debug log
      for (var customer in data) {
        print('Customer: ${customer['name']} - Role: ${customer['role']}'); // Debug log
      }
      setState(() {
        _customers = data;
        _loading = false;
      });
    } catch (e) {
      print('Error loading customers: $e'); // Debug log
      setState(() => _loading = false);
    }
  }

  Future<void> _blockCustomer(String customerId, String customerName, bool isBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBlocked ? 'Unblock Customer' : 'Block Customer'),
        content: Text(
          isBlocked 
            ? 'Are you sure you want to unblock $customerName?\n\nThey will be able to place orders again.'
            : 'Are you sure you want to block $customerName?\n\nThey will not be able to place new orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? AppColors.success : AppColors.warning,
            ),
            child: Text(isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.updateCustomerStatus(customerId, !isBlocked);
      _loadCustomers();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Success'),
              ],
            ),
            content: Text('Customer ${isBlocked ? 'unblocked' : 'blocked'} successfully'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Failed to update: ${e.toString()}'),
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

  Future<void> _deleteCustomer(String customerId, String customerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete $customerName?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Note:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• If this customer has orders, they will be deactivated but preserved in database\n'
                    '• If no orders exist, the customer will be permanently deleted\n'
                    '• Order history will be maintained for business records',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Deleting customer...'),
          ],
        ),
      ),
    );

    try {
      print('DEBUG: Attempting to delete customer: $customerId');
      await SupabaseService.deleteCustomer(customerId);
      print('DEBUG: Customer deletion successful');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      _loadCustomers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $customerName deleted successfully'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('ERROR: Customer deletion failed: $e');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to delete $customerName: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚪 Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your admin account?\n\n'
          'You\'ll need to login again to access the admin dashboard.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show logout progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Signing out...'),
                    ],
                  ),
                ),
              );
              
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout(context: context);
                
                // Close loading dialog
                if (mounted) Navigator.pop(context);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Signed out successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) Navigator.pop(context);
                
                // Show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Logout failed: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Customers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCustomers,
              child: _customers.isEmpty
                  ? const Center(child: Text('No customers found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _customers.length,
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return _CustomerCard(
                          customer: customer,
                          onBlock: () => _blockCustomer(
                            customer['id'],
                            customer['name'] ?? 'Customer',
                            customer['is_blocked'] ?? false,
                          ),
                          onDelete: () => _deleteCustomer(
                            customer['id'],
                            customer['name'] ?? 'Customer',
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final customer =
          await SupabaseService.getCustomerDetails(widget.customerId);
      final orders =
          await SupabaseService.getCustomerOrdersAdmin(widget.customerId);

      setState(() {
        _customer = customer;
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?['name'] ?? 'Customer Details'),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _customer?['profile_image'] != null
                                ? NetworkImage(_customer!['profile_image'])
                                : null,
                            child: _customer?['profile_image'] == null
                                ? const Text('🛒',
                                    style: TextStyle(fontSize: 40))
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _customer?['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(_customer?['phone'] ?? ''),
                          const SizedBox(height: 8),
                          Text(_customer?['address'] ?? 'No address'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.shopping_bag,
                                  color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                '${_orders.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Orders',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.currency_rupee,
                                  color: AppColors.success),
                              const SizedBox(height: 8),
                              Text(
                                '₹${_orders.fold<double>(0, (sum, o) => sum + (o['total_amount'] ?? 0)).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Total Spent',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Order History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._orders.map((o) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                              'Order #${o['id'].toString().substring(0, 8)}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${o['status']} • ${o['payment_status']}'),
                              Text(
                                o['created_at'] ?? '',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '₹${o['total_amount']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onBlock;
  final VoidCallback onDelete;
  
  const _CustomerCard({
    required this.customer,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = customer['is_blocked'] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: customer['profile_image'] != null
                  ? NetworkImage(customer['profile_image'])
                  : null,
              child: customer['profile_image'] == null
                  ? const Text('🛒', style: TextStyle(fontSize: 20))
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    customer['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BLOCKED',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer['phone'] ?? ''),
                const SizedBox(height: 4),
                Text(
                  customer['address'] ?? 'No address',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailScreen(
                      customerId: customer['id'],
                    ),
                  ),
                );
              },
            ),
          ),
          // Admin Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onBlock,
                    icon: Icon(
                      isBlocked ? Icons.check_circle : Icons.block,
                      size: 16,
                    ),
                    label: Text(
                      isBlocked ? 'Unblock' : 'Block',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isBlocked ? AppColors.success : AppColors.warning,
                      side: BorderSide(
                        color: isBlocked ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}