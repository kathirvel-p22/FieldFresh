import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_service.dart';

class AllOrdersScreen extends StatefulWidget {
  const AllOrdersScreen({super.key});
  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filterStatus = 'all';
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _setupRealTimeSubscriptions();
  }

  void _setupRealTimeSubscriptions() {
    // Subscribe to real-time order updates for admin
    _ordersSubscription = RealtimeService.subscribeToAllOrders().listen((orders) {
      if (mounted) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllOrders();
      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_filterStatus == 'all') return _orders;
    return _orders.where((o) => o['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FilterChip('All', 'all'),
                  _FilterChip('Pending', 'pending'),
                  _FilterChip('Confirmed', 'confirmed'),
                  _FilterChip('Packed', 'packed'),
                  _FilterChip('Dispatched', 'dispatched'),
                  _FilterChip('Delivered', 'delivered'),
                  _FilterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: _filteredOrders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return _OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  orderId: order['id'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
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

  Widget _FilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterStatus = value);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final statusColors = {
      'pending': AppColors.warning,
      'confirmed': AppColors.primary,
      'packed': AppColors.info,
      'dispatched': AppColors.accent,
      'delivered': AppColors.success,
      'cancelled': AppColors.error,
    };
    final color = statusColors[status] ?? AppColors.textSecondary;

    // Extract customer, farmer, and product info
    final customerName = order['users']?['name'] ?? 'Unknown Customer';
    final productName = order['products']?['name'] ?? 'Product';
    final farmerName = order['products']?['users']?['name'] ?? 'Unknown Farmer';
    final quantity = order['quantity'] ?? 0;
    final unit = order['unit'] ?? 'kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['id'].toString().substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Customer (who ordered)
              Row(
                children: [
                  const Icon(Icons.person,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text(
                    'Customer: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Farmer (who sold)
              Row(
                children: [
                  const Icon(Icons.agriculture,
                      size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  const Text(
                    'Farmer: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      farmerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Product details
              Row(
                children: [
                  const Icon(Icons.inventory_2,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  const Text(
                    'Product: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$productName ($quantity $unit)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        order['payment_status'] == 'paid'
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 16,
                        color: order['payment_status'] == 'paid'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order['payment_status'] ?? 'pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: order['payment_status'] == 'paid'
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${order['total_amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getOrderDetails(widget.orderId);
      setState(() {
        _order = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await SupabaseService.updateOrderStatus(widget.orderId, newStatus);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId.substring(0, 8)}'),
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
                  // Order Status Timeline
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _StatusTimeline(
                            currentStatus: _order?['status'] ?? 'pending',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Customer Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Customer Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _DetailRow('Name', _order?['users']?['name'] ?? 'Unknown'),
                          _DetailRow('Phone', _order?['users']?['phone'] ?? 'N/A'),
                          _DetailRow('Address', _order?['delivery_address'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Farmer Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.agriculture, color: AppColors.secondary),
                              SizedBox(width: 8),
                              Text(
                                'Farmer Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _DetailRow('Name', _order?['products']?['users']?['name'] ?? 'Unknown'),
                          _DetailRow('Phone', _order?['products']?['users']?['phone'] ?? 'N/A'),
                          _DetailRow('Location', _order?['products']?['users']?['address'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Order Details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.inventory_2, color: AppColors.accent),
                              SizedBox(width: 8),
                              Text(
                                'Order Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _DetailRow('Product', _order?['product_name'] ?? ''),
                          _DetailRow('Quantity',
                              '${_order?['quantity']} ${_order?['unit']}'),
                          _DetailRow('Price',
                              '₹${_order?['price_per_unit']}/${_order?['unit']}'),
                          _DetailRow(
                              'Total Amount', '₹${_order?['total_amount']}'),
                          _DetailRow('Payment',
                              _order?['payment_status'] ?? 'pending'),
                          _DetailRow('Delivery Type',
                              _order?['delivery_type'] ?? 'delivery'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Update Status
                  const Text(
                    'Update Order Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusButton('Confirmed', 'confirmed'),
                      _StatusButton('Packed', 'packed'),
                      _StatusButton('Dispatched', 'dispatched'),
                      _StatusButton('Delivered', 'delivered'),
                      _StatusButton('Cancelled', 'cancelled'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _StatusButton(String label, String status) {
    return ElevatedButton(
      onPressed: () => _updateStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'pending',
      'confirmed',
      'packed',
      'dispatched',
      'delivered'
    ];
    final currentIndex = statuses.indexOf(currentStatus);

    return Column(
      children: List.generate(statuses.length, (index) {
        final status = statuses[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == statuses.length - 1;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? AppColors.success : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color:
                      isCompleted ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
