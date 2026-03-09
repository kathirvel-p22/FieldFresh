import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';
import '../../../models/order_model.dart';
import '../../../services/supabase_service.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});
  
  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final Map<String, Map<String, dynamic>> _farmerCache = {};
  
  Future<Map<String, dynamic>?> _getFarmerDetails(String farmerId) async {
    if (_farmerCache.containsKey(farmerId)) {
      return _farmerCache[farmerId];
    }
    
    try {
      final farmer = await SupabaseService.getFarmerDetails(farmerId);
      if (farmer != null) {
        _farmerCache[farmerId] = farmer;
      }
      return farmer;
    } catch (e) {
      print('Error loading farmer: $e');
      return null;
    }
  }
  
  Future<void> _confirmDelivery(OrderModel order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text('Have you received this product?\n\nThis will mark the order as delivered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // Mark as delivered
      await SupabaseService.updateOrderStatus(order.id, 'delivered');
      
      // Record platform transaction for admin
      final platformFee = order.totalAmount * 0.05;
      final farmerReceives = order.totalAmount * 0.95;
      
      // Get farmer details
      final farmerData = await SupabaseService.getFarmerDetails(order.farmerId);
      final farmerName = farmerData?['name'] ?? 'Farmer';
      
      // Get customer details
      final customerData = await SupabaseService.getUser(order.customerId);
      final customerName = customerData?.name ?? 'Customer';
      
      // Record platform transaction
      await Supabase.instance.client.from('platform_transactions').insert({
        'order_id': order.id,
        'customer_id': order.customerId,
        'customer_name': customerName,
        'farmer_id': order.farmerId,
        'farmer_name': farmerName,
        'product_name': order.productName,
        'order_amount': order.totalAmount,
        'platform_fee': platformFee,
        'farmer_receives': farmerReceives,
        'transaction_type': 'order_delivery',
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Show review dialog
      if (mounted) {
        _showReviewDialog(order);
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
            content: Text('Failed to confirm delivery:\n\n${e.toString()}'),
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
  
  void _showReviewDialog(OrderModel order) {
    int rating = 5;
    int freshnessRating = 5;
    final commentCtrl = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Your Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How was ${order.productName}?', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Overall Rating:', style: TextStyle(fontSize: 12)),
                Row(
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => rating = i + 1),
                  )),
                ),
                const SizedBox(height: 8),
                const Text('Freshness:', style: TextStyle(fontSize: 12)),
                Row(
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < freshnessRating ? Icons.star : Icons.star_border,
                      color: AppColors.success,
                    ),
                    onPressed: () => setState(() => freshnessRating = i + 1),
                  )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Your Review (Optional)',
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                commentCtrl.dispose();
                Navigator.pop(context);
              },
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await SupabaseService.submitReview(
                    orderId: order.id,
                    farmerId: order.farmerId,
                    rating: rating,
                    freshnessRating: freshnessRating,
                    comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                  );
                  commentCtrl.dispose();
                  if (context.mounted) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Thank You!'),
                          ],
                        ),
                        content: const Text('Your review helps farmers improve their service.'),
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
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Failed to submit review:\n\n${e.toString()}'),
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
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.listenToCustomerOrders(SupabaseService.currentUserId ?? ''),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🛒', style: TextStyle(fontSize: 64)),
            SizedBox(height: 12),
            Text('No orders yet!', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('Browse the market and order fresh produce', style: TextStyle(color: AppColors.textHint)),
          ]));
          }
          final orders = snap.data!.map((d) => OrderModel.fromJson(d)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final o = orders[i];
              const statusColors = {'pending': AppColors.warning, 'confirmed': AppColors.primary, 'packed': AppColors.info, 'dispatched': AppColors.accent, 'delivered': AppColors.success, 'cancelled': AppColors.error};
              final sc = statusColors[o.status] ?? AppColors.textSecondary;
              
              // Calculate fees
              final platformFee = o.totalAmount * 0.05; // 5% platform fee
              final deliveryCharge = o.deliveryCharge;
              final grandTotal = o.totalAmount + platformFee + deliveryCharge;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: Text('📦', style: TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.productName ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('${o.quantity} ${o.unit}  •  ₹${o.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(o.status.toUpperCase(), style: TextStyle(fontSize: 10, color: sc, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Farmer details
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _getFarmerDetails(o.farmerId),
                        builder: (context, farmerSnap) {
                          if (farmerSnap.hasData && farmerSnap.data != null) {
                            final farmer = farmerSnap.data!;
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.secondary,
                                    child: Icon(Icons.person, color: Colors.white, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '👨‍🌾 ${farmer['name'] ?? 'Farmer'}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                        if (farmer['phone'] != null)
                                          Text(
                                            farmer['phone'],
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (farmer['rating'] != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 12, color: Colors.amber),
                                        Text(
                                          ' ${(farmer['rating'] as num).toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Platform Fee: ₹${platformFee.toStringAsFixed(0)}  •  Total: ₹${grandTotal.toStringAsFixed(0)}', 
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      // Action buttons
                      Row(
                        children: [
                          // Confirm Delivery button (only for dispatched orders)
                          if (o.status == 'dispatched')
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmDelivery(o),
                                icon: const Icon(Icons.check_circle, size: 16),
                                label: const Text('Confirm Delivery', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          // View Details button
                          if (o.status == 'dispatched') const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => context.go('/customer/order/${o.id}'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('View Details', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
