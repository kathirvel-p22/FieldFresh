import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../../core/constants.dart';
import '../../../models/order_model.dart';
import '../../../services/supabase_service.dart';
import '../../../services/progressive_disclosure_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${orderId.substring(0, 8)}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.listenToCustomerOrders(SupabaseService.currentUserId ?? ''),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final raw = snap.data!.where((o) => o['id'] == orderId).toList();
          if (raw.isEmpty) return const Center(child: Text('Order not found'));
          final order = OrderModel.fromJson(raw.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${orderId.substring(0, 8)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            _StatusChip(order.status),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Text('📦', style: TextStyle(fontSize: 30)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.productName ?? 'Product',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  Text(
                                    '${order.quantity} ${order.unit}  •  ₹${order.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.deliveryAddress ?? 'Pickup at farm',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Farmer Information Section
                _buildFarmerInfoSection(order),

                const SizedBox(height: 20),

                // Order Timeline
                const Text(
                  'Order Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTimeline(order),

                const SizedBox(height: 20),

                // Contact Actions
                _buildContactActions(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFarmerInfoSection(OrderModel order) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SupabaseService.getFarmerDetails(order.farmerId),
      builder: (context, farmerSnap) {
        if (!farmerSnap.hasData || farmerSnap.data == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final rawFarmerData = farmerSnap.data!;
        
        return FutureBuilder<Map<String, dynamic>>(
          future: ProgressiveDisclosureService.filterFarmerInfo(
            rawFarmerData, 
            order.status,
          ),
          builder: (context, filteredSnap) {
            if (!filteredSnap.hasData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            
            final filteredFarmerData = filteredSnap.data!;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Farmer Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.secondary,
                          backgroundImage: filteredFarmerData['profile_image'] != null
                              ? NetworkImage(filteredFarmerData['profile_image'])
                              : null,
                          child: filteredFarmerData['profile_image'] == null
                              ? const Icon(Icons.person, color: Colors.white, size: 24)
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
                                    '👨‍🌾 ${filteredFarmerData['name'] ?? 'Farmer'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (filteredFarmerData['is_verified'] == true) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      color: AppColors.success,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              if (filteredFarmerData['rating'] != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: Colors.amber),
                                    Text(
                                      ' ${(filteredFarmerData['rating'] as num).toStringAsFixed(1)} rating',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Contact Information
                    if (filteredFarmerData['phone'] != null) ...[
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        filteredFarmerData['phone'],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Location Information
                    if (filteredFarmerData['city'] != null && filteredFarmerData['address'] == null) ...[
                      _buildInfoRow(
                        Icons.location_city,
                        'City',
                        filteredFarmerData['city'],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    if (filteredFarmerData['address'] != null) ...[
                      _buildInfoRow(
                        Icons.location_on,
                        'Farm Location',
                        filteredFarmerData['address'],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Disclosure Status Message
                    FutureBuilder<String>(
                      future: ProgressiveDisclosureService.getCustomerDisclosureMessage(
                        order.status, 
                        order.farmerId,
                      ),
                      builder: (context, messageSnap) {
                        if (!messageSnap.hasData) return const SizedBox.shrink();
                        
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.info.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  messageSnap.data!,
                                  style: const TextStyle(
                                    fontSize: 12,
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
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final steps = [
      {'title': 'Order Placed', 'sub': 'Your order has been received', 'status': 'pending'},
      {'title': 'Order Confirmed', 'sub': 'Farmer has confirmed your order', 'status': 'confirmed'},
      {'title': 'Preparing Order', 'sub': 'Your order is being prepared', 'status': 'packed'},
      {'title': 'Out for Delivery', 'sub': 'Your order is on the way', 'status': 'dispatched'},
      {'title': 'Delivered', 'sub': 'Order delivered successfully', 'status': 'delivered'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final done = order.statusStep > i;
        final current = order.statusStep == i;
        
        return TimelineTile(
          alignment: TimelineAlign.manual,
          lineXY: 0.1,
          isFirst: i == 0,
          isLast: i == steps.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 20,
            color: done || current ? AppColors.secondary : Colors.grey.shade300,
            iconStyle: IconStyle(
              color: Colors.white,
              iconData: done ? Icons.check : (current ? Icons.radio_button_unchecked : Icons.circle),
            ),
          ),
          beforeLineStyle: LineStyle(
            color: i < order.statusStep ? AppColors.secondary : Colors.grey.shade300,
            thickness: 2,
          ),
          afterLineStyle: LineStyle(
            color: i < order.statusStep ? AppColors.secondary : Colors.grey.shade300,
            thickness: 2,
          ),
          endChild: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 0, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: done || current ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
                Text(
                  s['sub'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: done || current ? AppColors.textSecondary : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactActions(OrderModel order) {
    return FutureBuilder<bool>(
      future: ProgressiveDisclosureService.shouldAllowPhoneCall(
        order.status,
        order.farmerId,
        isCustomer: true,
      ),
      builder: (context, allowCallSnap) {
        return FutureBuilder<String>(
          future: ProgressiveDisclosureService.getContactButtonText(
            order.status,
            order.farmerId,
            isCustomer: true,
          ),
          builder: (context, buttonTextSnap) {
            final canCall = allowCallSnap.data ?? false;
            final buttonText = buttonTextSnap.data ?? 'Contact Farmer';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Help?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: canCall
                            ? () {
                                // Handle phone call
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calling farmer...')),
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: FutureBuilder<String>(
                                      future: ProgressiveDisclosureService.getCustomerDisclosureMessage(
                                        order.status,
                                        order.farmerId,
                                      ),
                                      builder: (context, messageSnap) {
                                        return Text(messageSnap.data ?? 'Contact not available yet');
                                      },
                                    ),
                                    backgroundColor: AppColors.info,
                                  ),
                                );
                              },
                        icon: Icon(canCall ? Icons.phone : Icons.info_outline),
                        label: Text(buttonText),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canCall ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        break;
      case 'confirmed':
        color = AppColors.info;
        text = 'Confirmed';
        break;
      case 'packed':
        color = AppColors.secondary;
        text = 'Packed';
        break;
      case 'dispatched':
        color = AppColors.primary;
        text = 'Dispatched';
        break;
      case 'delivered':
        color = AppColors.success;
        text = 'Delivered';
        break;
      default:
        color = AppColors.textHint;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}