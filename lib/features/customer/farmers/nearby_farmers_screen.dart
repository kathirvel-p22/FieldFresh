import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';
import '../../../services/realtime_service.dart';

class NearbyFarmersScreen extends StatefulWidget {
  const NearbyFarmersScreen({super.key});
  @override
  State<NearbyFarmersScreen> createState() => _NearbyFarmersScreenState();
}

class _NearbyFarmersScreenState extends State<NearbyFarmersScreen> {
  List<Map<String, dynamic>> _farmers = [];
  bool _loading = true;
  StreamSubscription? _farmersSubscription;

  // Demo location (Chennai - same as product defaults)
  final double _customerLat = 13.0827;
  final double _customerLng = 80.2707;

  @override
  void initState() {
    super.initState();
    _loadFarmers();
    _setupRealTimeSubscription();
  }

  void _setupRealTimeSubscription() {
    // Subscribe to real-time farmer updates
    _farmersSubscription = RealtimeService.subscribeToAllVerifiedFarmers().listen((farmers) {
      if (mounted) {
        // Calculate distance for each farmer and filter by radius
        final nearbyFarmers = farmers.where((farmer) {
          final farmerLat = farmer['latitude'] as double?;
          final farmerLng = farmer['longitude'] as double?;
          
          if (farmerLat != null && farmerLng != null) {
            final distance = SupabaseService.calculateDistance(
              lat1: _customerLat,
              lng1: _customerLng,
              lat2: farmerLat,
              lng2: farmerLng,
            );
            farmer['distance_km'] = distance;
            return distance <= 5000; // Use large radius to include all farmers
          } else {
            farmer['distance_km'] = 0.0; // Show farmers without location as local
            return true;
          }
        }).toList();

        setState(() {
          _farmers = nearbyFarmers;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _farmersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFarmers() async {
    setState(() => _loading = true);
    try {
      final farmers = await SupabaseService.getFarmersNearby(
        customerLat: _customerLat,
        customerLng: _customerLng,
        radiusKm: 25,
      );
      setState(() {
        _farmers = farmers;
        _loading = false;
      });
    } catch (e) {
      print('Error loading farmers: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nearby Farmers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _farmers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🌾', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 12),
                      Text('No farmers found nearby',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text('Try expanding your search radius',
                          style: TextStyle(
                              color: AppColors.textHint, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFarmers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _farmers.length,
                    itemBuilder: (context, index) {
                      final farmer = _farmers[index];
                      return FarmerCard(farmer: farmer);
                    },
                  ),
                ),
    );
  }
}

class FarmerCard extends StatefulWidget {
  final Map<String, dynamic> farmer;
  const FarmerCard({super.key, required this.farmer});
  @override
  State<FarmerCard> createState() => _FarmerCardState();
}

class _FarmerCardState extends State<FarmerCard> {
  bool _isFollowing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final customerId = SupabaseService.currentUserId;
    if (customerId == null) return;

    final isFollowing = await SupabaseService.isFollowingFarmer(
        customerId, widget.farmer['id'] as String);
    setState(() => _isFollowing = isFollowing);
  }

  Future<void> _toggleFollow() async {
    final customerId = SupabaseService.currentUserId;
    if (customerId == null) return;

    setState(() => _loading = true);
    try {
      if (_isFollowing) {
        await SupabaseService.unfollowFarmer(
            customerId, widget.farmer['id'] as String);
      } else {
        await SupabaseService.followFarmer(
            customerId, widget.farmer['id'] as String);
      }
      setState(() {
        _isFollowing = !_isFollowing;
        _loading = false;
      });
    } catch (e) {
      print('Error toggling follow: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = widget.farmer;
    final distance = (farmer['distance_km'] as double).toStringAsFixed(1);
    final rating = (farmer['rating'] as num?)?.toDouble() ?? 0.0;
    final isVerified = farmer['is_verified'] as bool? ?? false;
    final village = farmer['village'] ?? '';
    final city = farmer['city'] ?? '';
    final district = farmer['district'] ?? '';
    final state = farmer['state'] ?? '';

    // Build location string
    String locationStr = '';
    if (village.isNotEmpty) locationStr += village;
    if (city.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + city;
    if (district.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + district;
    if (state.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + state;
    if (locationStr.isEmpty) locationStr = '${farmer['district']}, ${farmer['city']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.person,
                    size: 32, color: AppColors.primary),
              ),
              if (isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified,
                        color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Farmer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        farmer['name'] as String? ?? 'Farmer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        locationStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation,
                              size: 10, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            '$distance km away',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Follow Button
          _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: _toggleFollow,
                  icon: Icon(
                    _isFollowing ? Icons.favorite : Icons.favorite_border,
                    color: _isFollowing
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
        ],
      ),
    );
  }
}
