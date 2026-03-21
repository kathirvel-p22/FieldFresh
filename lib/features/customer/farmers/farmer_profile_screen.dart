import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/trust_score_widget.dart';
import '../../../widgets/verification_badges_widget.dart';
import '../../../services/enterprise_service_manager.dart';
import '../../../services/privacy_service.dart';

class FarmerProfileScreen extends StatefulWidget {
  final String farmerId;
  final PaymentStatus paymentStatus;

  const FarmerProfileScreen({
    super.key,
    required this.farmerId,
    this.paymentStatus = PaymentStatus.none,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _enterpriseManager = EnterpriseServiceManager();
  FilteredUserProfile? _farmerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmerProfile();
  }

  Future<void> _loadFarmerProfile() async {
    try {
      final profile = await _enterpriseManager.getFilteredUserProfile(
        widget.farmerId,
        widget.paymentStatus,
        requesterId: _enterpriseManager.currentUserId,
      );

      if (mounted) {
        setState(() {
          _farmerProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Farmer Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFarmerProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _farmerProfile == null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load farmer profile',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFarmerProfile,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _farmerProfile!;
    final visibleData = profile.visibleData;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Image and Basic Info
                Row(
                  children: [
                    // Profile Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: ClipOval(
                        child: visibleData['profile_image'] != null
                            ? CachedNetworkImage(
                                imageUrl: visibleData['profile_image'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 40),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, size: 40),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.person, size: 40),
                              ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Name and Location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visibleData['name'] ?? 'Unknown Farmer',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (visibleData['district'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  visibleData['district'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          // Verification Badges
                          VerificationBadgesWidget(
                            userId: widget.farmerId,
                            maxBadges: 4,
                            badgeSize: 20,
                          ),
                        ],
                      ),
                    ),

                    // Trust Score
                    TrustScoreWidget(
                      userId: widget.farmerId,
                      size: 70,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rating
                if (visibleData['rating'] != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(5, (index) {
                        final rating =
                            (visibleData['rating'] as num).toDouble();
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${visibleData['rating']} / 5.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contact Information
          _buildContactSection(),

          const SizedBox(height: 16),

          // Farm Details
          _buildFarmDetailsSection(),

          const SizedBox(height: 16),

          // Privacy Upgrade Message
          if (profile.upgradeMessage != null)
            _buildUpgradeMessage(profile.upgradeMessage!),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    final visibleData = _farmerProfile!.visibleData;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.contact_phone,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Phone Number
          if (visibleData['phone'] != null)
            _buildContactItem(
              Icons.phone,
              'Phone',
              visibleData['phone'],
              onTap: () => _callFarmer(visibleData['phone']),
            )
          else
            _buildLockedContactItem(
              Icons.phone,
              'Phone Number',
              'Make an advance payment to unlock',
            ),

          // Email
          if (visibleData['email'] != null)
            _buildContactItem(
              Icons.email,
              'Email',
              visibleData['email'],
              onTap: () => _emailFarmer(visibleData['email']),
            )
          else if (_farmerProfile!.appliedLevel != DisclosureLevel.full)
            _buildLockedContactItem(
              Icons.email,
              'Email Address',
              'Confirm your order to unlock',
            ),

          // Location
          if (visibleData['latitude'] != null &&
              visibleData['longitude'] != null)
            _buildContactItem(
              Icons.location_on,
              'Exact Location',
              'Tap to view on map',
              onTap: () => _showLocationOnMap(
                visibleData['latitude'],
                visibleData['longitude'],
              ),
            )
          else if (visibleData['approximate_location'] != null)
            _buildContactItem(
              Icons.location_on,
              'Approximate Location',
              'Within 5km radius',
              onTap: () => _showApproximateLocation(),
            )
          else
            _buildLockedContactItem(
              Icons.location_on,
              'Location',
              'Make a payment to unlock location',
            ),
        ],
      ),
    );
  }

  Widget _buildFarmDetailsSection() {
    final visibleData = _farmerProfile!.visibleData;

    if (visibleData['farm_name'] == null &&
        visibleData['address'] == null &&
        visibleData['city'] == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.agriculture,
                color: Colors.green,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Farm Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleData['farm_name'] != null)
            _buildDetailItem('Farm Name', visibleData['farm_name']),
          if (visibleData['address'] != null)
            _buildDetailItem('Address', visibleData['address']),
          if (visibleData['city'] != null)
            _buildDetailItem('City', visibleData['city']),
          if (visibleData['farm_size'] != null)
            _buildDetailItem('Farm Size', visibleData['farm_size']),
          if (visibleData['crop_types'] != null)
            _buildDetailItem('Crops', visibleData['crop_types'].join(', ')),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedContactItem(
    IconData icon,
    String label,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeMessage(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareFarmerProfile() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _callFarmer(String phoneNumber) {
    // Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phoneNumber...')),
    );
  }

  void _emailFarmer(String email) {
    // Implement email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email to $email...')),
    );
  }

  void _showLocationOnMap(double latitude, double longitude) {
    // Implement map functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening map at $latitude, $longitude')),
    );
  }

  void _showApproximateLocation() {
    // Show approximate location info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approximate Location'),
        content: const Text(
          'This farmer\'s location is shown within a 5km radius for privacy. '
          'Confirm your order to get the exact location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
