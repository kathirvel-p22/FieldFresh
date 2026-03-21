import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../models/order_model.dart';
import '../../../services/supabase_service.dart';
import '../../../services/progressive_disclosure_service.dart';
import '../../../utils/localization_helper.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});
  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String _selectedStatus = 'all';
  final Map<String, Map<String, dynamic>> _customerCache = {};

  final _statusFilters = ['all', 'pending', 'confirmed', 'packed', 'dispatched', 'delivered'];

  String _getLocalizedStatus(String status) {
    return LocalizationHelper.getText(context, status);
  }

  Future<Map<String, dynamic>?> _getCustomerDetails(String customerId) async {
    if (_customerCache.containsKey(customerId)) {
      return _customerCache[customerId];
    }
    
    try {
      final customer = await SupabaseService.getCustomerDetails(customerId);
      if (customer != null) {
        _customerCache[customerId] = customer;
      }
      return customer;
    } catch (e) {
      print('Error loading customer: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final farmerId = SupabaseService.currentUserId;
      if (farmerId != null) {
        final orders = await SupabaseService.getFarmerOrders(farmerId);
        setState(() {
          _orders = orders;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _loading = false);
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedStatus == 'all') return _orders;
    return _orders.where((o) => o.status == _selectedStatus).toList();
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await SupabaseService.updateOrderStatus(orderId, newStatus);
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error updating order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(LocalizationHelper.getText(context, 'customerOrders')),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status filter chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatus == status;
                final count = status == 'all'
                    ? _orders.length
                    : _orders.where((o) => o.status == status).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${_getLocalizedStatus(status)} ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedStatus = status);
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Orders list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 12),
                            Text(
                              _selectedStatus == 'all'
                                  ? LocalizationHelper.getText(context, 'noOrdersYet')
                                  : LocalizationHelper.getTextWithParams(context, 'noStatusOrders', category: _getLocalizedStatus(_selectedStatus)),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              LocalizationHelper.getText(context, 'ordersWillAppear'),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    const statusColors = {
      'pending': AppColors.warning,
      'confirmed': AppColors.primary,
      'packed': AppColors.info,
      'dispatched': AppColors.accent,
      'delivered': AppColors.success,
      'cancelled': AppColors.error,
    };
    final statusColor = statusColors[order.status] ?? AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName ?? 'Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.substring(0, 8)}',
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getLocalizedStatus(order.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            
            // Customer info with progressive disclosure
            FutureBuilder<Map<String, dynamic>?>(
              future: _getCustomerDetails(order.customerId),
              builder: (context, customerSnap) {
                if (customerSnap.hasData && customerSnap.data != null) {
                  final rawCustomerData = customerSnap.data!;
                  
                  return FutureBuilder<Map<String, dynamic>>(
                    future: ProgressiveDisclosureService.filterCustomerInfo(
                      rawCustomerData, 
                      order.status,
                    ),
                    builder: (context, filteredSnap) {
                      if (!filteredSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final filteredCustomerData = filteredSnap.data!;
                      
                      return Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary,
                                backgroundImage: filteredCustomerData['profile_image'] != null
                                    ? NetworkImage(filteredCustomerData['profile_image'])
                                    : null,
                                child: filteredCustomerData['profile_image'] == null
                                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          filteredCustomerData['name'] ?? 'Customer',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (filteredCustomerData['is_verified'] == true) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.verified,
                                            color: AppColors.success,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (filteredCustomerData['phone'] != null)
                                      Text(
                                        filteredCustomerData['phone'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Disclosure message
                          const SizedBox(height: 8),
                          FutureBuilder<String>(
                            future: ProgressiveDisclosureService.getFarmerDisclosureMessage(
                              order.status,
                              order.customerId,
                            ),
                            builder: (context, messageSnap) {
                              if (!messageSnap.hasData) return const SizedBox.shrink();
                              
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 12, color: AppColors.info),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        messageSnap.data!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
                return Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(LocalizationHelper.getText(context, 'loadingCustomerInfo')),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Order details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${LocalizationHelper.getText(context, 'quantity')}: ${order.quantity} ${order.unit}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${LocalizationHelper.getText(context, 'total')}: ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.deliveryAddress != null) ...[
                  const Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    switch (order.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: Text(LocalizationHelper.getText(context, 'decline')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateOrderStatus(order.id, 'confirmed'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: Text(LocalizationHelper.getText(context, 'accept')),
              ),
            ),
          ],
        );
      case 'confirmed':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, 'packed'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
            child: Text(LocalizationHelper.getText(context, 'markAsPacked')),
          ),
        );
      case 'packed':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, 'dispatched'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text(LocalizationHelper.getText(context, 'markAsDispatched')),
          ),
        );
      case 'dispatched':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _updateOrderStatus(order.id, 'delivered'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: Text(LocalizationHelper.getText(context, 'markAsDelivered')),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}