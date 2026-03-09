import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../services/supabase_service.dart';

class FarmersListScreen extends StatefulWidget {
  const FarmersListScreen({super.key});
  @override
  State<FarmersListScreen> createState() => _FarmersListScreenState();
}

class _FarmersListScreenState extends State<FarmersListScreen> {
  List<Map<String, dynamic>> _farmers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
  }

  Future<void> _loadFarmers() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllFarmers();
      setState(() {
        _farmers = data;
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

  Future<void> _toggleVerification(String farmerId, bool currentStatus) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_verified': !currentStatus})
          .eq('id', farmerId);
      _loadFarmers();
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
            content: Text('Farmer ${!currentStatus ? 'verified' : 'unverified'} successfully'),
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

  Future<void> _deleteFarmer(String farmerId, String farmerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Farmer'),
        content: Text('Are you sure you want to delete $farmerName?\n\nThis will also delete all their products and orders.'),
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

    try {
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', farmerId);
      _loadFarmers();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Deleted'),
              ],
            ),
            content: const Text('Farmer deleted successfully'),
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
            content: Text('Failed to delete: ${e.toString()}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Farmers'),
        backgroundColor: AppColors.secondary,
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
              onRefresh: _loadFarmers,
              child: _farmers.isEmpty
                  ? const Center(child: Text('No farmers found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _farmers.length,
                      itemBuilder: (context, index) {
                        final farmer = _farmers[index];
                        return _FarmerCard(
                          farmer: farmer,
                          onVerify: () => _toggleVerification(
                            farmer['id'],
                            farmer['is_verified'] ?? false,
                          ),
                          onDelete: () => _deleteFarmer(
                            farmer['id'],
                            farmer['name'] ?? 'Farmer',
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final VoidCallback onVerify;
  final VoidCallback onDelete;
  
  const _FarmerCard({
    required this.farmer,
    required this.onVerify,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              backgroundImage: farmer['profile_image'] != null
                  ? NetworkImage(farmer['profile_image'])
                  : null,
              child: farmer['profile_image'] == null
                  ? const Text('👨‍🌾', style: TextStyle(fontSize: 20))
                  : null,
            ),
            title: Text(
              farmer['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmer['phone'] ?? ''),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('${farmer['rating'] ?? 0.0}'),
                    const SizedBox(width: 12),
                    Icon(
                      farmer['is_verified'] == true
                          ? Icons.verified
                          : Icons.pending,
                      size: 14,
                      color: farmer['is_verified'] == true
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      farmer['is_verified'] == true ? 'Verified' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: farmer['is_verified'] == true
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmerDetailScreen(farmerId: farmer['id']),
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
                    onPressed: onVerify,
                    icon: Icon(
                      farmer['is_verified'] == true ? Icons.block : Icons.verified,
                      size: 16,
                    ),
                    label: Text(
                      farmer['is_verified'] == true ? 'Unverify' : 'Verify',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: farmer['is_verified'] == true
                          ? AppColors.warning
                          : AppColors.success,
                      side: BorderSide(
                        color: farmer['is_verified'] == true
                            ? AppColors.warning
                            : AppColors.success,
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

class FarmerDetailScreen extends StatefulWidget {
  final String farmerId;
  const FarmerDetailScreen({super.key, required this.farmerId});
  @override
  State<FarmerDetailScreen> createState() => _FarmerDetailScreenState();
}

class _FarmerDetailScreenState extends State<FarmerDetailScreen> {
  Map<String, dynamic>? _farmer;
  List<Map<String, dynamic>> _products = [];
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
      final farmer = await SupabaseService.getFarmerDetails(widget.farmerId);
      final products =
          await SupabaseService.getFarmerProductsAdmin(widget.farmerId);
      final orders =
          await SupabaseService.getFarmerOrdersAdmin(widget.farmerId);

      setState(() {
        _farmer = farmer;
        _products = products;
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
        title: Text(_farmer?['name'] ?? 'Farmer Details'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farmer Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _farmer?['profile_image'] != null
                                ? NetworkImage(_farmer!['profile_image'])
                                : null,
                            child: _farmer?['profile_image'] == null
                                ? const Text('👨‍🌾',
                                    style: TextStyle(fontSize: 40))
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _farmer?['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(_farmer?['phone'] ?? ''),
                          const SizedBox(height: 8),
                          Text(_farmer?['address'] ?? 'No address'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          'Products',
                          '${_products.length}',
                          Icons.inventory_2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          'Orders',
                          '${_orders.length}',
                          Icons.shopping_bag,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._products.map((p) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(p['name'] ?? ''),
                          subtitle:
                              Text('₹${p['price_per_unit']} • ${p['status']}'),
                          trailing: Text('${p['quantity_left']} ${p['unit']}'),
                        ),
                      )),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._orders.map((o) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                              'Order #${o['id'].toString().substring(0, 8)}'),
                          subtitle:
                              Text('${o['status']} • ${o['payment_status']}'),
                          trailing: Text('₹${o['total_amount']}'),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.secondary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
