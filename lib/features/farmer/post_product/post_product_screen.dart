import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants.dart';
import '../../../models/product_model.dart';
import '../../../services/supabase_service.dart';
import '../../../services/image_service.dart';
import '../../../services/freshness_service.dart';

class PostProductScreen extends StatefulWidget {
  const PostProductScreen({super.key});
  @override
  State<PostProductScreen> createState() => _PostProductScreenState();
}

class _PostProductScreenState extends State<PostProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'vegetables';
  String _unit = 'kg';
  int _validHours = 12;
  List<File> _images = [];
  bool _loading = false;
  double? _lat, _lng;

  final _units = ['kg', 'g', 'litre', 'ml', 'piece', 'dozen', 'bunch'];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {}
  }

  void _onCategoryChanged(String cat) => setState(() {
        _category = cat;
        _validHours = FreshnessService.suggestValidityHours(cat);
      });

  Future<void> _pickImages() async {
    final imgs = await ImageService.pickMultiple();
    if (imgs.isNotEmpty) setState(() => _images = imgs);
  }

  Future<void> _pickFromCamera() async {
    final img = await ImageService.pickFromCamera();
    if (img != null) setState(() => _images.add(img));
  }

  Future<void> _pickFromGallery() async {
    final img = await ImageService.pickFromGallery();
    if (img != null) setState(() => _images.add(img));
  }

  void _showImagePickerOptions() {
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
                'Add Product Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.secondary, size: 28),
                title: const Text('Take Photo', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Capture fresh product image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary, size: 28),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Select existing photos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      _showSnack('Please add at least one product photo', isError: true);
      return;
    }

    // Check if user is logged in
    final farmerId = SupabaseService.currentUserId;
    if (farmerId == null) {
      _showSnack('Error: User not logged in. Please login again.',
          isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final imageUrls = await ImageService.uploadMultiple(_images);
      final now = DateTime.now();
      final score = FreshnessService.calculateScore(
          harvestTime: now,
          category: _category,
          farmerRating: 4.5,
          distanceKm: 0);
      final product = ProductModel(
        id: '', farmerId: farmerId, name: _nameCtrl.text.trim(),
        category: _category,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        pricePerUnit: double.parse(_priceCtrl.text), unit: _unit,
        quantityTotal: double.parse(_qtyCtrl.text),
        quantityLeft: double.parse(_qtyCtrl.text),
        imageUrls: imageUrls.isNotEmpty
            ? imageUrls
            : [
                'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400'
              ],
        harvestTime: now, validUntil: now.add(Duration(hours: _validHours)),
        freshnessScore: score, latitude: _lat, longitude: _lng,
        // farmAddress removed - not in database yet
        createdAt: now,
      );
      await SupabaseService.postProduct(product);
      
      // Harvest blast notification will be sent automatically by database trigger
      // when product is inserted (see PROGRESSIVE_SYSTEM_SCHEMA.sql)
      
      _nameCtrl.clear();
      _priceCtrl.clear();
      _qtyCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _images = [];
        _category = 'vegetables';
        _validHours = 12;
      });
      _showSnack('🌾 Harvest posted! Nearby customers notified!');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Post Today's Harvest"),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
              onPressed: _loading ? null : _submit,
              child: const Text('POST',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15))),
        ],
      ),
      body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─ Image Picker ─
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      border: Border.all(
                          color: AppColors.secondary.withOpacity(0.4),
                          width: 2)),
                  child: _images.isEmpty
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_a_photo,
                                  size: 40, color: AppColors.secondary),
                              SizedBox(height: 8),
                              Text('Add product photos',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                              Text('📸 Camera or 🖼️ Gallery',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textHint)),
                            ])
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount: _images.length + 1,
                          itemBuilder: (_, i) {
                            if (i == _images.length) {
                              return GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.secondary,
                                              width: 1.5),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(
                                          Icons.add_photo_alternate,
                                          color: AppColors.secondary)));
                            }
                            return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                        image: FileImage(_images[i]),
                                        fit: BoxFit.cover)));
                          }),
                ),
              ),
              const SizedBox(height: 16),

              // ─ Category ─
              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ProductCategories.all.length,
                    itemBuilder: (_, i) {
                      final cat = ProductCategories.all[i];
                      final sel = _category == cat['id'];
                      return GestureDetector(
                        onTap: () => _onCategoryChanged(cat['id'] as String),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.secondary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: sel
                                        ? AppColors.secondary
                                        : Colors.grey.shade300)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(cat['icon'] as String,
                                  style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 4),
                              Text(cat['name'] as String,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal)),
                            ])),
                      );
                    },
                  )),
              const SizedBox(height: 14),

              // ─ Name ─
              TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g. Fresh Tomatoes',
                      prefixIcon: Icon(Icons.eco_outlined)),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Product name required' : null),
              const SizedBox(height: 12),

              // ─ Price + Unit ─
              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                            labelText: 'Price (₹) *',
                            prefixIcon: Icon(Icons.currency_rupee)),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Required' : null)),
                const SizedBox(width: 12),
                SizedBox(
                    width: 110,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: _units
                          .map(
                              (u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    )),
              ]),
              const SizedBox(height: 12),

              // ─ Quantity ─
              TextFormField(
                  controller: _qtyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: InputDecoration(
                      labelText: 'Available Quantity *',
                      hintText: 'e.g. 50',
                      prefixIcon: const Icon(Icons.scale_outlined),
                      suffixText: _unit),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 14),

              // ─ Validity Slider ─
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.3))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.timer_outlined,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 6),
                          Text('Valid for $_validHours hours',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning)),
                          const Spacer(),
                          Text(
                              'Expires: ${DateTime.now().add(Duration(hours: _validHours)).hour}:${DateTime.now().add(Duration(hours: _validHours)).minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ]),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.warning,
                              thumbColor: AppColors.warning,
                              inactiveTrackColor:
                                  AppColors.warning.withOpacity(0.2)),
                          child: Slider(
                              value: _validHours.toDouble(),
                              min: 1,
                              max: 168,
                              divisions: 167,
                              onChanged: (v) =>
                                  setState(() => _validHours = v.round())),
                        ),
                        Text(
                            'AI suggestion for "$_category": ${FreshnessService.suggestValidityHours(_category)} hrs',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                      ])),
              const SizedBox(height: 12),

              // ─ Description ─
              TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Tell customers about your produce...',
                      prefixIcon: Icon(Icons.notes),
                      alignLabelWithHint: true)),
              const SizedBox(height: 12),

              // ─ Location ─
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _lat != null
                          ? AppColors.success.withOpacity(0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(
                          color: _lat != null
                              ? AppColors.success.withOpacity(0.3)
                              : Colors.grey.shade200)),
                  child: Row(children: [
                    Icon(_lat != null ? Icons.location_on : Icons.location_off,
                        color: _lat != null
                            ? AppColors.success
                            : AppColors.textHint,
                        size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            _lat != null
                                ? '📍 Farm location detected (${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)})'
                                : 'Detecting farm location...',
                            style: TextStyle(
                                fontSize: 12,
                                color: _lat != null
                                    ? AppColors.success
                                    : AppColors.textHint))),
                    if (_lat == null)
                      TextButton(
                          onPressed: _getLocation,
                          child: const Text('Retry',
                              style: TextStyle(fontSize: 12))),
                  ])),
              const SizedBox(height: 20),

              // ─ Submit Button ─
              SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusM))),
                    child: _loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Posting & Notifying Customers...',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                              ])
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Text('🌾', style: TextStyle(fontSize: 22)),
                                SizedBox(width: 10),
                                Text('Post Harvest & Notify Customers',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold)),
                              ]),
                  )),
              const SizedBox(height: 40),
            ]),
          )),
    );
  }
}
