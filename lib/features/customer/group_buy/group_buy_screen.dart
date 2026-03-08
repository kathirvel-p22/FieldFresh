import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key});
  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  List<Map<String, dynamic>> _groupBuys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupBuys();
  }

  Future<void> _loadGroupBuys() async {
    setState(() => _loading = true);
    try {
      final groupBuys = await SupabaseService.getActiveGroupBuys();
      setState(() {
        _groupBuys = groupBuys;
        _loading = false;
      });
    } catch (e) {
      print('Error loading group buys: $e');
      setState(() => _loading = false);
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group Buy'),
        content: const Text(
            'Group buy creation feature coming soon!\n\nYou\'ll be able to:\n• Select a product\n• Set target quantity\n• Set discount percentage\n• Invite nearby customers'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Group Buy 👥'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
                onPressed: _showCreateGroupDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text('Start Group',
                    style: TextStyle(color: Colors.white)))
          ]),
      body: RefreshIndicator(
        onRefresh: _loadGroupBuys,
        child: ListView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            children: [
              // Banner
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL)),
                  child: const Row(children: [
                    Text('👥', style: TextStyle(fontSize: 44)),
                    SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Buy Together, Save More!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                              'Join a group to unlock up to 20% discount.\nOne delivery point, shared cost.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 2),
                        ])),
                  ])),
              const SizedBox(height: 16),
              const Text('Active Groups Near You',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else if (_groupBuys.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('🛒', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 12),
                        const Text('No active group buys',
                            style: TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showCreateGroupDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Start a Group Buy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._groupBuys.map(
                    (g) => GroupBuyCard(groupBuy: g, onJoined: _loadGroupBuys)),
            ]),
      ),
    );
  }
}

class GroupBuyCard extends StatefulWidget {
  final Map<String, dynamic> groupBuy;
  final VoidCallback onJoined;
  const GroupBuyCard(
      {super.key, required this.groupBuy, required this.onJoined});
  @override
  State<GroupBuyCard> createState() => _GroupBuyCardState();
}

class _GroupBuyCardState extends State<GroupBuyCard> {
  bool _joining = false;

  Future<void> _joinGroup() async {
    final customerId = SupabaseService.currentUserId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to join group buy')),
      );
      return;
    }

    setState(() => _joining = true);
    try {
      // Default quantity of 1 kg/unit
      await SupabaseService.joinGroupBuy(
        widget.groupBuy['id'] as String,
        customerId,
        1.0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined group buy!'),
          backgroundColor: AppColors.success,
        ),
      );

      widget.onJoined();
    } catch (e) {
      print('Error joining group: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining group: $e')),
      );
    } finally {
      setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.groupBuy;
    final product = g['products'] as Map<String, dynamic>?;
    final creator = g['users'] as Map<String, dynamic>?;

    final currentQty = (g['current_quantity'] as num).toDouble();
    final targetQty = (g['target_quantity'] as num).toDouble();
    final discount = (g['discount_percent'] as num).toDouble();
    final progress = (currentQty / targetQty).clamp(0.0, 1.0);
    final full = currentQty >= targetQty;

    final expiresAt = DateTime.parse(g['expires_at'] as String);
    final timeLeft = expiresAt.difference(DateTime.now());
    final hoursLeft = timeLeft.inHours;

    return Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(product?['category_icon'] as String? ?? '🌱',
                  style: const TextStyle(fontSize: 38)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(product?['name'] as String? ?? 'Product',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('-${discount.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold))),
                    ]),
                    Text('by ${creator?['name'] as String? ?? 'Farmer'}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    Text('₹${product?['price_per_unit']}/${product?['unit']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.secondary)),
                  ])),
            ]),
            const SizedBox(height: 12),
            // Progress
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                  '${currentQty.toStringAsFixed(1)} of ${targetQty.toStringAsFixed(1)} ${product?['unit'] ?? 'units'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text(
                  full
                      ? '✅ Ready!'
                      : '${(targetQty - currentQty).toStringAsFixed(1)} more needed',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: full ? AppColors.success : AppColors.warning)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                        full ? AppColors.success : AppColors.primary))),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  hoursLeft > 0 ? '$hoursLeft hours left' : 'Expires soon',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _joining ? null : _joinGroup,
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          full ? AppColors.success : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: _joining
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(full
                          ? '🎉 Finalize Group Order'
                          : 'Join This Group (Save ${discount.toStringAsFixed(0)}%)'),
                )),
          ]),
        ));
  }
}
