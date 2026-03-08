import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../../core/constants.dart';
import '../../../models/order_model.dart';
import '../../../services/supabase_service.dart';

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${orderId.substring(0, 8)}'),
          backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.listenToCustomerOrders(SupabaseService.currentUserId ?? ''),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final raw = snap.data!.where((o) => o['id'] == orderId).toList();
          if (raw.isEmpty) return const Center(child: Text('Order not found'));
          final order = OrderModel.fromJson(raw.first);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Order Card
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Order #${orderId.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  _StatusChip(order.status),
                ]),
                const Divider(height: 20),
                Row(children: [
                  Text(order.productName?.isNotEmpty == true ? '📦' : '📦', style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.productName ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('${order.quantity} ${order.unit}  •  ₹${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(child: Text(order.deliveryAddress ?? 'Pickup at farm',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                ]),
              ]))),
              const SizedBox(height: 20),
              const Text('Tracking Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              _buildTimeline(order),

              const SizedBox(height: 20),
              if (order.status == 'delivered') ...[
                const Divider(),
                const SizedBox(height: 12),
                const Text('How was your order?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
                  GestureDetector(onTap: () {}, child: const Icon(Icons.star_border, size: 40, color: AppColors.accent)))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity,
                  child: ElevatedButton(onPressed: () {},
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    child: const Text('Submit Review'))),
              ],
              if (order.deliveryType == 'delivery' && order.status != 'delivered' && order.status != 'cancelled')
                _CallFarmerBtn(),
              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final steps = [
      {'title': 'Order Placed', 'sub': 'Payment confirmed', 'icon': Icons.check_circle_outline, 'done': true},
      {'title': 'Farmer Confirmed', 'sub': 'Farmer accepted your order', 'icon': Icons.handshake_outlined, 'done': order.statusStep >= 1},
      {'title': 'Packing', 'sub': 'Your produce is being packed', 'icon': Icons.inventory_2_outlined, 'done': order.statusStep >= 2},
      {'title': 'Out for Delivery', 'sub': 'On the way to you', 'icon': Icons.delivery_dining_outlined, 'done': order.statusStep >= 3},
      {'title': 'Delivered! 🎉', 'sub': 'Enjoy your fresh produce', 'icon': Icons.home_outlined, 'done': order.statusStep >= 4},
    ];

    return Column(children: steps.asMap().entries.map((e) {
      final i = e.key; final s = e.value; final done = s['done'] as bool;
      final active = i == order.statusStep;
      return TimelineTile(
        alignment: TimelineAlign.manual, lineXY: 0.12,
        isFirst: i == 0, isLast: i == steps.length - 1,
        indicatorStyle: IndicatorStyle(width: 40, height: 40,
          indicator: AnimatedContainer(duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
                color: done ? AppColors.secondary : active ? AppColors.primary.withOpacity(0.15) : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: done ? AppColors.secondary : active ? AppColors.primary : Colors.grey.shade300, width: 2)),
            child: Icon(s['icon'] as IconData, size: 18, color: done ? Colors.white : active ? AppColors.primary : Colors.grey))),
        beforeLineStyle: LineStyle(color: done ? AppColors.secondary : Colors.grey.shade300, thickness: 2),
        afterLineStyle: LineStyle(color: i < order.statusStep ? AppColors.secondary : Colors.grey.shade300, thickness: 2),
        endChild: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 0, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s['title'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: done ? AppColors.textPrimary : AppColors.textHint)),
          Text(s['sub'] as String, style: TextStyle(fontSize: 12, color: done ? AppColors.textSecondary : AppColors.textHint)),
        ])),
      );
    }).toList());
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);
  @override
  Widget build(BuildContext context) {
    const colors = {'pending': AppColors.warning, 'confirmed': AppColors.primary, 'packed': AppColors.info, 'dispatched': AppColors.accent, 'delivered': AppColors.success, 'cancelled': AppColors.error};
    final color = colors[status] ?? AppColors.textSecondary;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)));
  }
}

class _CallFarmerBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    child: SizedBox(width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📞 Calling farmer...'))),
        icon: const Icon(Icons.call),
        label: const Text('Call Farmer'),
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 12)),
      )));
}
