import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';

class SavedFarmersScreen extends StatefulWidget {
  const SavedFarmersScreen({super.key});
  @override
  State<SavedFarmersScreen> createState() => _SavedFarmersScreenState();
}

class _SavedFarmersScreenState extends State<SavedFarmersScreen> {
  List<Map<String, dynamic>> _farmers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedFarmers();
  }

  Future<void> _loadSavedFarmers() async {
    setState(() => _loading = true);
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId == null) return;

      final data = await SupabaseService.getFollowedFarmers(customerId);
      setState(() {
        _farmers = data;
        _loading = false;
      });
    } catch (e) {
      print('Error loading saved farmers: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _unfollowFarmer(String farmerId) async {
    try {
      final customerId = SupabaseService.currentUserId;
      if (customerId == null) return;

      await SupabaseService.unfollowFarmer(customerId, farmerId);
      _loadSavedFarmers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farmer removed from favorites')),
        );
      }
    } catch (e) {
      print('Error unfollowing farmer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Farmers'),
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
                      Text('❤️', style: TextStyle(fontSize: 64)),
                      SizedBox(height: 12),
                      Text('No saved farmers yet',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Follow farmers to see them here',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedFarmers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _farmers.length,
                    itemBuilder: (context, index) {
                      final farmer = _farmers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Text(
                              farmer['name']?[0]?.toUpperCase() ?? '👨‍🌾',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            farmer['name'] ?? 'Farmer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                  Text(
                                      ' ${farmer['rating']?.toStringAsFixed(1) ?? '5.0'}',
                                      style: const TextStyle(fontSize: 12)),
                                  const Text(' • ',
                                      style: TextStyle(fontSize: 12)),
                                  Text('${farmer['total_orders'] ?? 0} orders',
                                      style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              if (farmer['district'] != null)
                                Text(
                                  '📍 ${farmer['district']}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: AppColors.error),
                                onPressed: () => _unfollowFarmer(farmer['id']),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.textHint),
                            ],
                          ),
                          onTap: () {
                            // Navigate to farmer profile
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
