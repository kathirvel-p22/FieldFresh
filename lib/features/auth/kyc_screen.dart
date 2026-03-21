import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants.dart';
import '../../../services/image_service.dart';
import 'verification_flow_screen.dart';

class KycScreen extends StatefulWidget {
  final dynamic extra; // Can be String (role) or Map (user data)
  const KycScreen({super.key, required this.extra});
  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _client = Supabase.instance.client;
  XFile? _profileImage;
  double? _lat, _lng;
  bool _loading = false;
  bool _locating = false;
  final _formKey = GlobalKey<FormState>();

  late String _role;
  late String _userId;
  late String _phone;

  final _roleData = {
    'farmer': {
      'emoji': '👨‍🌾',
      'title': 'Set Up Farm Profile',
      'color': AppColors.secondary
    },
    'customer': {
      'emoji': '🛒',
      'title': 'Set Up Your Profile',
      'color': AppColors.primary
    },
  };

  @override
  void initState() {
    super.initState();
    // Parse extra data
    if (widget.extra is Map) {
      final data = widget.extra as Map;
      _role = data['role'] as String;
      _userId = data['userId'] as String;
      _phone = data['phone'] as String;
    } else {
      // Fallback for old format (just role string)
      _role = widget.extra as String;
      _userId = '';
      _phone = '';
    }
    _getLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location services are disabled. Please enable them in settings.')),
          );
        }
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _locating = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Location permissions are denied. Please grant permission in settings.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permissions are permanently denied. Please enable them in app settings.')),
          );
        }
        return;
      }

      // Get current position
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location detected successfully!')),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _locating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final img = await ImageService.pickFromGallery();
    if (img != null) setState(() => _profileImage = img);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Use default coordinates if location is not available
    double finalLat = _lat ?? 13.0827; // Default to Chennai coordinates
    double finalLng = _lng ?? 80.2707;

    if (_lat == null) {
      print('DEBUG: Using default coordinates (Chennai) for user registration');
    }
    setState(() => _loading = true);
    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await ImageService.uploadImage(_profileImage!);
      }

      // Update user with complete profile but DON'T mark as verified yet
      // Users need to go through proper verification flow
      await _client.from('users').update({
        'name': _nameCtrl.text.trim(),
        'profile_image': imageUrl,
        'latitude': finalLat,
        'longitude': finalLng,
        'address': _addressCtrl.text.trim(),
        'village': _villageCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'is_verified': false, // Will be set to true after verification flow
        'is_kyc_done': true, // Profile setup is complete
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile setup complete! Now let\'s verify your account 🔐'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to verification flow for new users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationFlowScreen(
              userId: _userId,
              userRole: _role,
            ),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: KYC save error: $e');
      if (mounted) {
        String errorMessage = 'Error saving profile. Please try again.';

        // Handle specific database errors
        if (e.toString().contains('sent_at')) {
          errorMessage =
              'Database configuration issue. Please contact support.';
        } else if (e.toString().contains('column') &&
            e.toString().contains('does not exist')) {
          errorMessage =
              'Database schema issue. Please run the database fix script.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _roleData[_role] ?? _roleData['customer']!;
    final color = data['color'] as Color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          backgroundColor: color,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
              background: Container(
                  color: color,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['emoji'] as String,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(data['title'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const Text('Almost done! Fill in your details.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                      ]))),
        ),
        SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              Form(
                  key: _formKey,
                  child: Column(children: [
                    // Profile Photo
                    GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(children: [
                          CircleAvatar(
                              radius: 54,
                              backgroundColor: color.withOpacity(0.1),
                              backgroundImage: _profileImage != null
                                  ? FileImage(File(_profileImage!.path))
                                  : null,
                              child: _profileImage == null
                                  ? Text(data['emoji'] as String,
                                      style: const TextStyle(fontSize: 48))
                                  : null),
                          Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 16))),
                        ])),
                    const SizedBox(height: 24),

                    TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                            labelText: _role == 'farmer'
                                ? 'Your Name / Farm Name *'
                                : 'Your Full Name *',
                            prefixIcon: const Icon(Icons.person_outline)),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Name is required' : null),
                    const SizedBox(height: 14),

                    TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                            labelText: _role == 'farmer'
                                ? 'Farm Address *'
                                : 'Home Address *',
                            hintText: 'Street, area...',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Address is required' : null),
                    const SizedBox(height: 14),

                    // Village/Area
                    TextFormField(
                        controller: _villageCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Village / Area *',
                            hintText: 'Enter village or area name',
                            prefixIcon: Icon(Icons.home_outlined)),
                        validator: (v) => v!.trim().isEmpty
                            ? 'Village/Area is required'
                            : null),
                    const SizedBox(height: 14),

                    // City
                    TextFormField(
                        controller: _cityCtrl,
                        decoration: const InputDecoration(
                            labelText: 'City *',
                            hintText: 'Enter city name',
                            prefixIcon: Icon(Icons.location_city)),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'City is required' : null),
                    const SizedBox(height: 14),

                    // District
                    TextFormField(
                        controller: _districtCtrl,
                        decoration: const InputDecoration(
                            labelText: 'District *',
                            hintText: 'Enter district name',
                            prefixIcon: Icon(Icons.map_outlined)),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'District is required' : null),
                    const SizedBox(height: 14),

                    // State
                    TextFormField(
                        controller: _stateCtrl,
                        decoration: const InputDecoration(
                            labelText: 'State *',
                            hintText: 'Enter state name',
                            prefixIcon: Icon(Icons.public)),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'State is required' : null),
                    const SizedBox(height: 14),

                    // Location status
                    Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: _lat != null
                                ? AppColors.success.withValues(alpha: 0.07)
                                : AppColors.info.withValues(alpha: 0.07),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusM),
                            border: Border.all(
                                color: _lat != null
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : AppColors.info.withValues(alpha: 0.3))),
                        child: Row(children: [
                          _locating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Icon(
                                  _lat != null
                                      ? Icons.my_location
                                      : Icons.location_on,
                                  color: _lat != null
                                      ? AppColors.success
                                      : AppColors.info,
                                  size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    _lat != null
                                        ? '📍 Location detected'
                                        : '📍 Location optional',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _lat != null
                                            ? AppColors.success
                                            : AppColors.info,
                                        fontSize: 13)),
                                Text(
                                    _lat != null
                                        ? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                                        : 'Will use default location if not provided',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ])),
                          if (_lat == null && !_locating)
                            TextButton(
                                onPressed: _getLocation,
                                child: const Text('Enable',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                        ])),
                    const SizedBox(height: 28),

                    SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.radiusM))),
                          child: _loading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2)),
                                      SizedBox(width: 12),
                                      Text('Setting up your profile...'),
                                    ])
                              : const Text('Complete Setup & Start',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        )),
                    const SizedBox(height: 60),
                  ])),
            ]))),
      ]),
    );
  }
}
