import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';

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
      setState(() {
        _customers = data;
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
        title: const Text('All Customers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) context.go(AppRoutes.roleSelect);
            },
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
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              backgroundImage: customer['profile_image'] != null
                                  ? NetworkImage(customer['profile_image'])
                                  : null,
                              child: customer['profile_image'] == null
                                  ? const Text('🛒',
                                      style: TextStyle(fontSize: 20))
                                  : null,
                            ),
                            title: Text(
                              customer['name'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
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
                              icon:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
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
