import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  final String farmerId;
  const FarmerProfileScreen({super.key, required this.farmerId});
  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Map<String, dynamic>? _farmerData;
  bool _loading = true;
  bool _hasAdvancePayment = false;
  bool _isFollowing = false;
  bool _processingPayment = false;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;

      // Check if customer has paid advance
      if (customerId != null) {
        _hasAdvancePayment = await SupabaseService.hasAdvancePayment(
            customerId, widget.farmerId);
        _isFollowing = await SupabaseService.isFollowingFarmer(
            customerId, widget.farmerId);
      }

      // Load appropriate farmer details
      final farmerData = _hasAdvancePayment
          ? await SupabaseService.getFarmerFullDetails(widget.farmerId)
          : await SupabaseService.getFarmerLimitedDetails(widget.farmerId);

      setState(() {
        _farmerData = farmerData;
        _loading = false;
      });
    } catch (e) {
      print('Error loading farmer data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _payAdvance() async {
    final customerId = SupabaseService.currentUserId;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue')),
      );
      return;
    }

    setState(() => _processingPayment = true);
    try {
      // Create advance payment (₹20)
      await SupabaseService.createAdvancePayment(
        customerId: customerId,
        farmerId: widget.farmerId,
        productId: '', // Can be empty for farmer profile unlock
        advanceAmount: 20.0,
        totalAmount: 20.0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Farmer details unlocked.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Reload farmer data with full details
      _loadFarmerData();
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      setState(() => _processingPayment = false);
    }
  }

  Future<void> _toggleFollow() async {
    final customerId = SupabaseService.currentUserId;
    if (customerId == null) return;

    try {
      if (_isFollowing) {
        await SupabaseService.unfollowFarmer(customerId, widget.farmerId);
      } else {
        await SupabaseService.followFarmer(customerId, widget.farmerId);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleFollow,
            icon: Icon(
              _isFollowing ? Icons.favorite : Icons.favorite_border,
              color: _isFollowing ? Colors.red : Colors.white,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _farmerData == null
              ? const Center(child: Text('Farmer not found'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          gradient: AppColors.farmerGradient,
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: const Icon(Icons.person,
                                  size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _farmerData!['name'] as String? ?? 'Farmer',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_farmerData!['is_verified'] == true) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified,
                                      color: Colors.white, size: 20),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  ((_farmerData!['rating'] as num?)
                                              ?.toDouble() ??
                                          0.0)
                                      .toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Info Cards
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Location Info (Always visible)
                            _InfoCard(
                              icon: Icons.location_on,
                              title: 'Location',
                              children: [
                                _InfoRow(
                                    'District',
                                    _farmerData!['district'] as String? ??
                                        'N/A'),
                                _InfoRow('City',
                                    _farmerData!['city'] as String? ?? 'N/A'),
                              ],
                            ),

                            // Locked/Unlocked Content
                            if (!_hasAdvancePayment) ...[
                              const SizedBox(height: 16),
                              _LockedCard(
                                onUnlock: _payAdvance,
                                processing: _processingPayment,
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              _InfoCard(
                                icon: Icons.phone,
                                title: 'Contact Details',
                                children: [
                                  _InfoRow(
                                    'Phone',
                                    _farmerData!['phone'] as String? ?? 'N/A',
                                    onTap: () => _copyToClipboard(
                                        _farmerData!['phone'] as String? ?? '',
                                        'Phone number'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _InfoCard(
                                icon: Icons.home,
                                title: 'Full Address',
                                children: [
                                  _InfoRow(
                                      'Village',
                                      _farmerData!['village'] as String? ??
                                          'N/A'),
                                  _InfoRow('City',
                                      _farmerData!['city'] as String? ?? 'N/A'),
                                  _InfoRow(
                                      'District',
                                      _farmerData!['district'] as String? ??
                                          'N/A'),
                                  _InfoRow(
                                      'State',
                                      _farmerData!['state'] as String? ??
                                          'N/A'),
                                  if (_farmerData!['address'] != null)
                                    _InfoRow('Full Address',
                                        _farmerData!['address'] as String),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _InfoCard(
                                icon: Icons.location_searching,
                                title: 'GPS Coordinates',
                                children: [
                                  _InfoRow(
                                    'Latitude',
                                    (_farmerData!['latitude'] as double?)
                                            ?.toStringAsFixed(6) ??
                                        'N/A',
                                    onTap: () => _copyToClipboard(
                                        (_farmerData!['latitude'] as double?)
                                                ?.toString() ??
                                            '',
                                        'Latitude'),
                                  ),
                                  _InfoRow(
                                    'Longitude',
                                    (_farmerData!['longitude'] as double?)
                                            ?.toStringAsFixed(6) ??
                                        'N/A',
                                    onTap: () => _copyToClipboard(
                                        (_farmerData!['longitude'] as double?)
                                                ?.toString() ??
                                            '',
                                        'Longitude'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _InfoCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _InfoRow(this.label, this.value, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.copy,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedCard extends StatelessWidget {
  final VoidCallback onUnlock;
  final bool processing;
  const _LockedCard({required this.onUnlock, required this.processing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock, size: 48, color: AppColors.warning),
          const SizedBox(height: 12),
          const Text(
            'Farmer Details Locked',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pay ₹20 advance to unlock:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('Phone number', style: TextStyle(fontSize: 13)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('Full address', style: TextStyle(fontSize: 13)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('GPS coordinates', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: processing ? null : onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Pay ₹20 & Unlock Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This amount will be adjusted in your first order',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
