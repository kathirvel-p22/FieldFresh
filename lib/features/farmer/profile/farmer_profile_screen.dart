import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../core/constants.dart';
import '../../../services/supabase_service.dart';
import '../../../services/image_service.dart';
import 'sales_analytics_screen.dart';
import 'my_listings_screen.dart';
import 'customer_reviews_screen.dart';
import '../wallet/bank_upi_settings_screen.dart';
import '../orders/farmer_orders_screen.dart';
import '../customers/all_customers_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});
  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _uploadingImage = false;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOrderStats();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        final user = await SupabaseService.getUser(userId);
        setState(() {
          _userData = user?.toJson();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadOrderStats() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        final orders = await SupabaseService.getFarmerOrders(userId);
        setState(() {
          _totalOrders = orders.length;
        });
      }
    } catch (e) {
      print('Error loading order stats: $e');
    }
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary, size: 28),
                title: const Text('Take Photo', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Capture new profile picture'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfileImage(fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary, size: 28),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Select existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfileImage(fromCamera: false);
                },
              ),
              if (_userData?['profile_image'] != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error, size: 28),
                  title: const Text('Remove Photo', style: TextStyle(fontSize: 16)),
                  subtitle: const Text('Use default avatar'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage({required bool fromCamera}) async {
    setState(() => _uploadingImage = true);
    try {
      print('DEBUG: Starting farmer profile image upload (fromCamera: $fromCamera)');
      
      final imageFile = fromCamera 
          ? await ImageService.pickFromCamera()
          : await ImageService.pickFromGallery();
      
      if (imageFile != null) {
        print('DEBUG: Image file selected: ${imageFile.name}');
        print('DEBUG: Image file path: ${imageFile.path}');
        
        // Show progress message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 16),
                  Expanded(child: Text('Uploading image... This may take a moment.')),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }
        
        // Upload single image using new method
        final imageUrl = await ImageService.uploadImage(imageFile);
        print('DEBUG: Image upload result: $imageUrl');
        
        if (imageUrl != null) {
          print('DEBUG: Updating farmer profile with image URL: $imageUrl');
          
          // Update user profile
          await SupabaseService.updateUserProfile({
            'profile_image': imageUrl,
          });
          
          print('DEBUG: Profile updated, reloading user data...');
          
          // Reload user data
          await _loadUserData();
          
          print('DEBUG: User data reloaded successfully');
          
          // Hide progress message
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          
          _showSnackBar('Profile photo updated successfully! 🎉', isError: false);
        } else {
          print('DEBUG: No image URL returned from upload');
          
          // Hide progress message
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          
          _showSnackBar('Failed to upload image. Please check your internet connection and try again.', isError: true);
        }
      } else {
        print('DEBUG: No image file selected');
      }
    } catch (e) {
      print('ERROR: Profile image upload failed: $e');
      
      // Hide progress message
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      
      String errorMessage = 'Failed to upload profile photo';
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Upload timeout. Please try with a smaller image.';
      } else if (e.toString().contains('size') || e.toString().contains('large')) {
        errorMessage = 'Image too large. Please choose a smaller image.';
      }
      
      _showSnackBar(errorMessage, isError: true);
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _removeProfileImage() async {
    setState(() => _uploadingImage = true);
    try {
      await SupabaseService.updateUserProfile({
        'profile_image': null,
      });
      
      await _loadUserData();
      _showSnackBar('Profile photo removed', isError: false);
    } catch (e) {
      print('Error removing profile image: $e');
      _showSnackBar('Failed to remove profile photo', isError: true);
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userData?['name'] ?? 'Farmer';
    final userPhone = _userData?['phone'] ?? '';
    final profileImage = _userData?['profile_image'];
    final rating = (_userData?['rating'] as num?)?.toDouble() ?? 0.0;
    final isVerified = _userData?['is_verified'] ?? false;
    final village = _userData?['village'] ?? '';
    final city = _userData?['city'] ?? '';
    final district = _userData?['district'] ?? '';
    final state = _userData?['state'] ?? '';
    
    // Build location string
    String locationStr = '';
    if (village.isNotEmpty) locationStr += village;
    if (city.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + city;
    if (district.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + district;
    if (state.isNotEmpty) locationStr += (locationStr.isEmpty ? '' : ', ') + state;
    if (locationStr.isEmpty) locationStr = 'Location not set';

    return Scaffold(
      body: ListView(children: [
        Container(
            height: 260,
            decoration: const BoxDecoration(gradient: AppColors.farmerGradient),
            child: SafeArea(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _uploadingImage
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 10),
                              Text(
                                'Updating profile photo...',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          )
                        : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _showProfileImageOptions,
                                child: profileImage != null
                                    ? CircleAvatar(
                                        radius: 46,
                                        backgroundColor: Colors.white24,
                                        backgroundImage: CachedNetworkImageProvider(profileImage),
                                      )
                                    : const CircleAvatar(
                                        radius: 46,
                                        backgroundColor: Colors.white24,
                                        child: Text('👨‍🌾', style: TextStyle(fontSize: 42))),
                              ),
                              if (isVerified)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified, color: Colors.white, size: 16),
                                  ),
                                ),
                              // Camera icon for photo upload
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: GestureDetector(
                                  onTap: _showProfileImageOptions,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(userName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(userPhone,
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(' ${rating.toStringAsFixed(1)}  ',
                                style: const TextStyle(color: Colors.white)),
                            Text('• $_totalOrders Orders  ',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const Text('• Active',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                          ]),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    locationStr,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]))),
        Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(children: [
              _MenuItem(Icons.shopping_bag_outlined, 'Customer Orders',
                  'View & manage orders', AppColors.success, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FarmerOrdersScreen()));
              }),
              _MenuItem(Icons.people_outline, 'All Customers',
                  'View customer profiles', AppColors.info, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AllCustomersScreen()));
              }),
              _MenuItem(Icons.analytics_outlined, 'Sales Analytics',
                  'View your performance charts', AppColors.primary, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SalesAnalyticsScreen()));
              }),
              _MenuItem(Icons.inventory_2_outlined, 'My Listings',
                  'Manage all your products', AppColors.secondary, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyListingsScreen()));
              }),
              _MenuItem(Icons.star_border, 'Customer Reviews',
                  'See what customers say', AppColors.accent, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerReviewsScreen()));
              }),
              _MenuItem(Icons.account_balance_outlined, 'Bank / UPI Settings',
                  'Manage payout methods', AppColors.info, () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BankUpiSettingsScreen()));
              }),
              _MenuItem(Icons.verified_user_outlined, 'KYC Documents',
                  'Aadhaar & farm docs', AppColors.warning, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('KYC Documents feature coming soon')),
                );
              }),
              _MenuItem(Icons.language, 'Language', 'Tamil / Hindi / English',
                  AppColors.textSecondary, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Language settings coming soon')),
                );
              }),
              _MenuItem(Icons.headset_mic, 'Help & Support',
                  'Chat with our team', AppColors.textSecondary, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon')),
                );
              }),
              Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.logout,
                            color: AppColors.error, size: 20)),
                    title: const Text('Sign Out',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.textHint),
                    onTap: () async {
                      await SupabaseService.signOut();
                      if (context.mounted) context.go(AppRoutes.roleSelect);
                    },
                  )),
            ])),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.title, this.subtitle, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppColors.textHint),
        onTap: onTap,
      ));
}
